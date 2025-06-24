import Foundation


enum APIError: Error, LocalizedError {
    case invalidResponse
    case apiError(message: String)
    case uploadFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid or unexpected response."
        case .apiError(let message): return message // This will show the server's message, e.g., "invalid token"
        case .uploadFailed(let message): return "Upload failed: \(message)"
        }
    }
}

class APIService {
    static let shared = APIService()
    private init() {}

    private let createURL = URL(string: "https://mvsep.com/api/separation/create")!
    private let getURL = URL(string: "https://mvsep.com/api/separation/get")!

    func submitTask(
        filePath: URL,
        apiKey: String,
        modelID: Int,
        formatID: Int,
        additionalOptions: [String: String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var request = URLRequest(url: createURL)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        
        body.append(self.createDataField(name: "api_token", value: apiKey, boundary: boundary))
        body.append(self.createDataField(name: "sep_type", value: "\(modelID)", boundary: boundary))
        body.append(self.createDataField(name: "output_format", value: "\(formatID)", boundary: boundary))
        
        for (key, value) in additionalOptions {
            if !value.isEmpty {
                body.append(self.createDataField(name: key, value: value, boundary: boundary))
            }
        }
        
        do {
            let fileData = try Data(contentsOf: filePath)
            body.append(self.createFileField(name: "audiofile", fileData: fileData, fileName: filePath.lastPathComponent, boundary: boundary))
        } catch {
            completion(.failure(APIError.uploadFailed(message: error.localizedDescription)))
            return
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            if let successResponse = try? JSONDecoder().decode(SubmitResponse.self, from: data), successResponse.success {
                if let hash = successResponse.data?.hash {
                    completion(.success(hash))
                    return
                }
            }
            
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMessage = errorResponse.errors.joined(separator: ", ")
                completion(.failure(APIError.apiError(message: errorMessage)))
                return
            }
            
            completion(.failure(APIError.invalidResponse))

        }.resume()
    }
    
    func checkStatus(hash: String, completion: @escaping (Result<StatusResponse, Error>) -> Void) {
        var components = URLComponents(url: getURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "hash", value: hash)]
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            do {
                // This will now correctly decode all valid status responses
                let result = try JSONDecoder().decode(StatusResponse.self, from: data)
                completion(.success(result))
            } catch {
                // --- Better Debugging ---
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("--- FAILED TO DECODE STATUS RESPONSE ---")
                print("Server response was: \(responseString)")
                print("Decoding error: \(error.localizedDescription)")
                print("--------------------------------------")
                completion(.failure(APIError.invalidResponse)) // Send a clean error to the UI
            }
        }.resume()
    }

    func downloadFile(fromURL: String, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let sourceURL = URL(string: fromURL) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        let task = URLSession.shared.downloadTask(with: sourceURL) { localURL, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let localURL = localURL else { completion(.failure(APIError.invalidResponse)); return }
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func createDataField(name: String, value: String, boundary: String) -> Data {
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        field += "\(value)\r\n"
        return field.data(using: .utf8)!
    }

    private func createFileField(name: String, fileData: Data, fileName: String, boundary: String) -> Data {
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        field += "Content-Type: application/octet-stream\r\n\r\n"
        
        var data = Data()
        data.append(field.data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        return data
    }
}

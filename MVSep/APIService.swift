import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case apiError(message: String)
    case uploadFailed(message: String)
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid or unexpected response."
        case .apiError(let message): return message
        case .uploadFailed(let message): return "Upload failed: \(message)"
        }
    }
}

class APIService: NSObject, URLSessionDownloadDelegate {
    static let shared = APIService()
    private var session: URLSession!
    private var downloadCompletions: [URLSessionTask: (Result<URL, Error>) -> Void] = [:]
    private var downloadProgressHandlers: [URLSessionTask: (Double) -> Void] = [:]

    private let createURL = URL(string: "https://mvsep.com/api/separation/create")!
    private let getURL = URL(string: "https://mvsep.com/api/separation/get")!

    override private init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func submitTask(filePath: URL, apiKey: String, modelID: Int, formatID: Int, additionalOptions: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: createURL)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append(self.createDataField(name: "api_token", value: apiKey, boundary: boundary))
        body.append(self.createDataField(name: "sep_type", value: "\(modelID)", boundary: boundary))
        body.append(self.createDataField(name: "output_format", value: "\(formatID)", boundary: boundary))
        for (key, value) in additionalOptions {
            if !value.isEmpty { body.append(self.createDataField(name: key, value: value, boundary: boundary)) }
        }
        do {
            let fileData = try Data(contentsOf: filePath)
            body.append(self.createFileField(name: "audiofile", fileData: fileData, fileName: filePath.lastPathComponent, boundary: boundary))
        } catch { completion(.failure(APIError.uploadFailed(message: error.localizedDescription))); return }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!); request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.invalidResponse)); return }
            if let successResponse = try? JSONDecoder().decode(SubmitResponse.self, from: data), successResponse.success {
                if let hash = successResponse.data?.hash { completion(.success(hash)); return }
            }
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMessage = errorResponse.errors.joined(separator: ", "); completion(.failure(APIError.apiError(message: errorMessage))); return
            }
            completion(.failure(APIError.invalidResponse))
        }.resume()
    }

    func checkStatus(hash: String, completion: @escaping (Result<StatusResponse, Error>) -> Void) {
        var components = URLComponents(url: getURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "hash", value: hash)]; guard let url = components.url else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.invalidResponse)); return }
            do { let result = try JSONDecoder().decode(StatusResponse.self, from: data); completion(.success(result)) }
            catch { completion(.failure(APIError.invalidResponse)) }
        }.resume()
    }

    func fetchHistory(apiKey: String, start: Int = 0, limit: Int = 20, completion: @escaping (Result<[HistoryJob], Error>) -> Void) {
        guard var components = URLComponents(string: "https://mvsep.com/api/app/separation_history") else { completion(.failure(APIError.invalidResponse)); return }
        components.queryItems = [URLQueryItem(name: "api_token", value: apiKey), URLQueryItem(name: "start", value: "\(start)"), URLQueryItem(name: "limit", value: "\(limit)")]
        guard let url = components.url else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.invalidResponse)); return }
            do {
                let result = try JSONDecoder().decode(HistoryResponse.self, from: data)
                if result.success { completion(.success(result.data)) } else { completion(.failure(APIError.apiError(message: "Failed to fetch history."))) }
            } catch { completion(.failure(APIError.invalidResponse)) }
        }.resume()
    }

    func downloadFile(fromURL: String, to destinationURL: URL, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let sourceURL = URL(string: fromURL) else { completion(.failure(APIError.invalidResponse)); return }
        let downloadTask = session.downloadTask(with: sourceURL)
        downloadCompletions[downloadTask] = { result in
            if case .success(let tempURL) = result {
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) { try FileManager.default.removeItem(at: destinationURL) }
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL); completion(.success(destinationURL))
                } catch { completion(.failure(error)) }
            } else if case .failure(let error) = result { completion(.failure(error)) }
        }
        downloadProgressHandlers[downloadTask] = progressHandler
        downloadTask.resume()
    }

    private func createDataField(name: String, value: String, boundary: String) -> Data {
        var field = "--\(boundary)\r\n"; field += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"; field += "\(value)\r\n"
        return field.data(using: .utf8)!
    }

    private func createFileField(name: String, fileData: Data, fileName: String, boundary: String) -> Data {
        var field = "--\(boundary)\r\n"; field += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"; field += "Content-Type: application/octet-stream\r\n\r\n"
        var data = Data(); data.append(field.data(using: .utf8)!); data.append(fileData); data.append("\r\n".data(using: .utf8)!)
        return data
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloadCompletions[downloadTask]?(.success(location))
        downloadCompletions[downloadTask] = nil; downloadProgressHandlers[downloadTask] = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error { downloadCompletions[task]?(.failure(error)) }
        downloadCompletions[task] = nil; downloadProgressHandlers[task] = nil
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        downloadProgressHandlers[downloadTask]?(progress)
    }
}

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

final class APIService: NSObject, URLSessionDownloadDelegate {
    static let shared = APIService()
    private let baseURL = URL(string: "https://mvsep.com/api/")!
    private var session: URLSession!
    private let decoder = JSONDecoder()

    // Download callbacks are registered from the caller's thread and fired on the delegate queue.
    private let lock = NSLock()
    private var downloadCompletions: [Int: (Result<URL, Error>) -> Void] = [:]
    private var downloadProgressHandlers: [Int: (Double) -> Void] = [:]

    override private init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    // MARK: - Separation

    func submitTask(filePath: URL, apiKey: String, modelID: Int, formatID: Int, additionalOptions: [String: String], progressHandler: @escaping (Double) -> Void) async throws -> String {
        var fields = ["api_token": apiKey, "sep_type": "\(modelID)", "output_format": "\(formatID)"]
        for (key, value) in additionalOptions where !value.isEmpty { fields[key] = value }

        let boundary = "Boundary-\(UUID().uuidString)"
        let bodyURL: URL
        do { bodyURL = try writeMultipartBody(fields: fields, fileURL: filePath, boundary: boundary) }
        catch { throw APIError.uploadFailed(message: error.localizedDescription) }
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        var request = URLRequest(url: baseURL.appendingPathComponent("separation/create"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.upload(for: request, fromFile: bodyURL, delegate: UploadProgressDelegate(handler: progressHandler))

        guard let response = try? decoder.decode(SubmitResponse.self, from: data) else { throw APIError.invalidResponse }
        if response.success, let hash = response.data?.hash { return hash }
        throw APIError.apiError(message: errorMessage(errors: response.errors, message: response.data?.message))
    }

    func checkStatus(hash: String) async throws -> StatusResponse {
        let data = try await get("separation/get", query: ["hash": hash])
        do { return try decoder.decode(StatusResponse.self, from: data) } catch { throw APIError.invalidResponse }
    }

    /// Credits are refunded only if the job has not started processing yet.
    func cancelTask(hash: String, apiKey: String) async throws {
        let response: SimpleResponse = try await post("separation/cancel", fields: ["api_token": apiKey, "hash": hash])
        if !response.success { throw APIError.apiError(message: errorMessage(errors: response.errors, message: response.message)) }
    }

    // MARK: - Site & Account

    func fetchAlgorithms() async throws -> Data {
        try await get("app/algorithms", query: [:])
    }

    func fetchUser(apiKey: String) async throws -> UserInfo {
        let data = try await get("app/user", query: ["api_token": apiKey])
        guard let response = try? decoder.decode(UserResponse.self, from: data) else { throw APIError.invalidResponse }
        guard response.success, let user = response.data else { throw APIError.apiError(message: "Invalid API key.") }
        return user
    }

    func setPremiumEnabled(_ enabled: Bool, apiKey: String) async throws {
        let response: SimpleResponse = try await post(enabled ? "app/enable_premium" : "app/disable_premium", fields: ["api_token": apiKey])
        if !response.success { throw APIError.apiError(message: errorMessage(errors: response.errors, message: response.message)) }
    }

    func fetchHistory(apiKey: String, start: Int = 0, limit: Int = 20) async throws -> [HistoryJob] {
        let data = try await get("app/separation_history", query: ["api_token": apiKey, "start": "\(start)", "limit": "\(limit)"])
        guard let result = try? decoder.decode(HistoryResponse.self, from: data) else { throw APIError.invalidResponse }
        if result.success { return result.data }
        throw APIError.apiError(message: "Failed to fetch history.")
    }

    // MARK: - Downloads

    func downloadFile(fromURL: String, to destinationURL: URL, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard let sourceURL = URL(string: fromURL) else { throw APIError.invalidResponse }
        let downloadTask = session.downloadTask(with: sourceURL)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.withLock {
                    downloadCompletions[downloadTask.taskIdentifier] = { result in
                        // The temporary file is deleted as soon as the delegate returns, so move it here.
                        continuation.resume(with: result.flatMap { tempURL in
                            Result {
                                if FileManager.default.fileExists(atPath: destinationURL.path) { try FileManager.default.removeItem(at: destinationURL) }
                                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                                return destinationURL
                            }
                        })
                    }
                    downloadProgressHandlers[downloadTask.taskIdentifier] = progressHandler
                }
                downloadTask.resume()
            }
        } onCancel: {
            downloadTask.cancel()
        }
    }

    // MARK: - Helpers

    private func get(_ path: String, query: [String: String]) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = components.url else { throw APIError.invalidResponse }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private func post<T: Decodable>(_ path: String, fields: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        for (name, value) in fields { body.append(createDataField(name: name, value: value, boundary: boundary)) }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let (data, _) = try await URLSession.shared.data(for: request)
        do { return try decoder.decode(T.self, from: data) } catch { throw APIError.invalidResponse }
    }

    private func errorMessage(errors: [String]?, message: String?) -> String {
        if let errors, !errors.isEmpty { return errors.joined(separator: "\n") }
        return message ?? "The server rejected the request."
    }

    /// Streams the audio file into a temporary multipart body so large files never sit in memory.
    private func writeMultipartBody(fields: [String: String], fileURL: URL, boundary: String) throws -> URL {
        let bodyURL = FileManager.default.temporaryDirectory.appendingPathComponent("upload-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: bodyURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: bodyURL)
        defer { try? output.close() }

        for (name, value) in fields { try output.write(contentsOf: createDataField(name: name, value: value, boundary: boundary)) }
        let fileName = fileURL.lastPathComponent.replacingOccurrences(of: "\"", with: "'")
        try output.write(contentsOf: "--\(boundary)\r\nContent-Disposition: form-data; name=\"audiofile\"; filename=\"\(fileName)\"\r\nContent-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)

        let input = try FileHandle(forReadingFrom: fileURL)
        defer { try? input.close() }
        while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty { try output.write(contentsOf: chunk) }

        try output.write(contentsOf: "\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return bodyURL
    }

    private func createDataField(name: String, value: String, boundary: String) -> Data {
        var field = "--\(boundary)\r\n"; field += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"; field += "\(value)\r\n"
        return field.data(using: .utf8)!
    }

    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let completion = lock.withLock {
            downloadProgressHandlers[downloadTask.taskIdentifier] = nil
            return downloadCompletions.removeValue(forKey: downloadTask.taskIdentifier)
        }
        if let response = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            completion?(.failure(APIError.apiError(message: "Download failed (HTTP \(response.statusCode)).")))
        } else {
            completion?(.success(location))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let completion = lock.withLock {
            downloadProgressHandlers[task.taskIdentifier] = nil
            return downloadCompletions.removeValue(forKey: task.taskIdentifier)
        }
        if let completion { completion(.failure(error ?? APIError.invalidResponse)) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let handler = lock.withLock { downloadProgressHandlers[downloadTask.taskIdentifier] }
        handler?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }
}

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let handler: (Double) -> Void
    init(handler: @escaping (Double) -> Void) { self.handler = handler }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        handler(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
}

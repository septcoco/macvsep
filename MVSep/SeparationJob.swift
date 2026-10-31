import Foundation
import Observation

/// One separation, from upload to results.
@MainActor @Observable
final class SeparationJob {
    enum Phase: Equatable {
        case idle
        case uploading(Double)
        case waiting(position: Int?, eta: Int?)
        case processing
        case distributing(finished: Int, total: Int)
        case merging
        case finished([SeparatedFile])
        case failed(String)
        case cancelled
    }

    private(set) var phase: Phase = .idle
    private(set) var inputName = ""
    private var hash: String?
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        switch phase {
        case .uploading, .waiting, .processing, .distributing, .merging: return true
        default: return false
        }
    }

    func start(file: URL, model: SeparationModel, formatID: Int, options: [String: String], apiKey: String) {
        task?.cancel()
        inputName = file.lastPathComponent
        hash = nil
        phase = .uploading(0)
        let visibleOptions = options.filter { key, _ in model.additionalOptions.first { $0.parameterName == key }?.isVisible(with: options) ?? false }

        task = Task {
            do {
                let hash = try await APIService.shared.submitTask(filePath: file, apiKey: apiKey, modelID: model.id, formatID: formatID, additionalOptions: visibleOptions) { progress in
                    Task { @MainActor in if case .uploading = self.phase { self.phase = .uploading(progress) } }
                }
                try Task.checkCancellation()
                self.hash = hash
                phase = .waiting(position: nil, eta: nil)
                try await poll(hash: hash)
            } catch is CancellationError {
            } catch let error as URLError where error.code == .cancelled {
            } catch {
                if !Task.isCancelled { phase = .failed(error.localizedDescription) }
            }
        }
    }

    func cancel(apiKey: String) {
        task?.cancel()
        task = nil
        phase = .cancelled
        if let hash {
            self.hash = nil
            Task { try? await APIService.shared.cancelTask(hash: hash, apiKey: apiKey) }
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        hash = nil
        phase = .idle
    }

    private func poll(hash: String) async throws {
        var failures = 0
        while true {
            try await Task.sleep(for: .seconds(5))
            let response: StatusResponse
            do {
                response = try await APIService.shared.checkStatus(hash: hash)
                failures = 0
            } catch {
                // A dropped connection shouldn't lose a job that is still running on the server.
                failures += 1
                if failures >= 6 { throw error }
                continue
            }
            try Task.checkCancellation()
            let data = response.data
            switch response.status {
            case "waiting":
                phase = .waiting(position: data?.current_order, eta: data?.eta_seconds)
            case "processing":
                phase = .processing
            case "distributing":
                if let finished = data?.finished_chunks, let total = data?.all_chunks, total > 0 { phase = .distributing(finished: finished, total: total) }
                else { phase = .processing }
            case "merging":
                phase = .merging
            case "done":
                let files = (data?.files ?? []).map { SeparatedFile(fileName: $0.download, downloadURL: $0.url) }
                phase = .finished(files)
                self.hash = nil
                NotificationManager.shared.sendNotification(title: "Separation Complete", body: "\(inputName) is ready for download.")
                return
            case "failed":
                self.hash = nil
                throw APIError.apiError(message: data?.message ?? "The separation process failed on the server.")
            case "not_found":
                self.hash = nil
                throw APIError.apiError(message: "The job could not be found on the server.")
            default:
                phase = .processing
            }
        }
    }
}

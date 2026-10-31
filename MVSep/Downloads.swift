import Foundation
import Observation

/// Tracks every file download so a row, a "Download All" button and the history all see the same state.
@MainActor @Observable
final class Downloads {
    static let shared = Downloads()

    enum State: Equatable { case downloading(Double), finished(URL), failed(String) }

    private(set) var states: [String: State] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]

    private init() {}

    func state(for file: SeparatedFile) -> State? { states[file.downloadURL] }

    func isBusy(_ files: [SeparatedFile]) -> Bool {
        files.contains { if case .downloading = states[$0.downloadURL] { return true } else { return false } }
    }

    /// Downloads files one after another into the output folder. Returns how many were saved.
    @discardableResult
    func download(_ files: [SeparatedFile], inputName: String) async -> Int {
        let folder: URL
        do {
            guard let destination = try OutputFolder.shared.destination(forInputNamed: inputName) else { return 0 }
            folder = destination
        } catch {
            for file in files { states[file.downloadURL] = .failed(error.localizedDescription) }
            return 0
        }

        var saved = 0
        for file in files {
            if case .finished = states[file.downloadURL] { saved += 1; continue }
            if case .downloading = states[file.downloadURL] { continue }
            states[file.downloadURL] = .downloading(0)
            let task = Task {
                do {
                    let url = try await APIService.shared.downloadFile(fromURL: file.downloadURL, to: folder.appendingPathComponent(file.fileName)) { progress in
                        Task { @MainActor in
                            if case .downloading = self.states[file.downloadURL] { self.states[file.downloadURL] = .downloading(progress) }
                        }
                    }
                    states[file.downloadURL] = .finished(url)
                } catch {
                    states[file.downloadURL] = .failed(error.localizedDescription)
                }
            }
            tasks[file.downloadURL] = task
            await task.value
            tasks[file.downloadURL] = nil
            if case .finished = states[file.downloadURL] { saved += 1 }
        }

        if files.count > 1 {
            let failed = files.count - saved
            NotificationManager.shared.sendNotification(
                title: failed == 0 ? "Download Complete" : "Download Finished With Errors",
                body: failed == 0 ? "\(saved) files were saved." : "\(saved) of \(files.count) files were saved."
            )
        } else if let file = files.first {
            switch states[file.downloadURL] {
            case .finished: NotificationManager.shared.sendNotification(title: "Download Complete", body: "\(file.fileName) has been saved.")
            case .failed(let message): NotificationManager.shared.sendNotification(title: "Download Failed", body: "Could not save \(file.fileName). Error: \(message)")
            default: break
            }
        }
        return saved
    }

    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
    }
}

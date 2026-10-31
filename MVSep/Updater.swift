import Combine
import Observation
import Sparkle

/// Wraps Sparkle so SwiftUI views can show "Check for Updates…" and the update preferences.
@MainActor @Observable
final class Updater {
    static let shared = Updater()

    private let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    private var cancellable: AnyCancellable?

    private(set) var canCheckForUpdates = false
    var automaticallyChecksForUpdates: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates }
    }
    var automaticallyDownloadsUpdates: Bool {
        didSet { controller.updater.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates }
    }

    private init() {
        automaticallyChecksForUpdates = controller.updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = controller.updater.automaticallyDownloadsUpdates
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates).sink { [weak self] value in
            self?.canCheckForUpdates = value
        }
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

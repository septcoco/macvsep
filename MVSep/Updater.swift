import AppKit
import Combine
import Observation
import Sparkle

/// Wraps Sparkle so SwiftUI views can show "Check for Updates…" and the update preferences.
@MainActor @Observable
final class Updater {
    static let shared = Updater()

    private let delegate = UpdaterDelegate()
    private let controller: SPUStandardUpdaterController
    private var cancellable: AnyCancellable?

    private(set) var canCheckForUpdates = false
    var automaticallyChecksForUpdates: Bool {
        didSet { controller.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates }
    }
    var automaticallyDownloadsUpdates: Bool {
        didSet { controller.updater.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates }
    }

    private init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: delegate, userDriverDelegate: nil)
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

/// macOS won't quit an app while a sheet is open (it just beeps), so "Install and Relaunch"
/// did nothing when Settings or History was showing. Close them before Sparkle relaunches.
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem, untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        let windows = NSApp.windows.filter { $0.attachedSheet != nil }
        guard !windows.isEmpty else { return false }
        for window in windows {
            if let sheet = window.attachedSheet { window.endSheet(sheet) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: installHandler)
        return true
    }
}

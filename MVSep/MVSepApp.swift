import SwiftUI

@main
struct MVSepApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @ColorAppStorage(wrappedValue: .accentColor, "accentColorHex") private var accentColor
    @State private var updater = Updater.shared

    var body: some Scene {
        WindowGroup("MacVSep") {
            ContentView()
                .preferredColorScheme(appearanceMode.colorScheme)
                .tint(accentColor)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
            }
        }
    }
}

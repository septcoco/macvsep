import SwiftUI

@main
struct MVSepApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup("MacVSep") {
            ContentView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}

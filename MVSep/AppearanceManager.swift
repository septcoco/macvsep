import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct GradientPreset: Identifiable, Hashable {
    let name: String
    var id: String { name }
    let colors: [Color]
}

class AppearanceManager {
    static let presets: [GradientPreset] = [
        GradientPreset(name: "Default", colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
        GradientPreset(name: "Sunset", colors: [Color.orange.opacity(0.4), Color.red.opacity(0.4)]),
        GradientPreset(name: "Forest", colors: [Color.green.opacity(0.4), Color.teal.opacity(0.4)]),
        GradientPreset(name: "Monochrome", colors: [Color.gray.opacity(0.3), Color.black.opacity(0.4)])
    ]
}

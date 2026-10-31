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
        GradientPreset(name: "Monochrome", colors: [Color.gray.opacity(0.3), Color.black.opacity(0.4)]),
        GradientPreset(name: "Ocean", colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.4), Color.indigo.opacity(0.4)]),
        GradientPreset(name: "Aurora", colors: [Color.green.opacity(0.35), Color.teal.opacity(0.3), Color.purple.opacity(0.4)]),
        GradientPreset(name: "Lavender", colors: [Color(red: 0.71, green: 0.62, blue: 0.95).opacity(0.4), Color.pink.opacity(0.3)]),
        GradientPreset(name: "Peach", colors: [Color(red: 1.0, green: 0.72, blue: 0.55).opacity(0.45), Color.pink.opacity(0.35)]),
        GradientPreset(name: "Ember", colors: [Color.red.opacity(0.45), Color.orange.opacity(0.3), Color.black.opacity(0.4)]),
        GradientPreset(name: "Mint", colors: [Color.mint.opacity(0.4), Color.cyan.opacity(0.25)]),
        GradientPreset(name: "Sand", colors: [Color(red: 0.93, green: 0.84, blue: 0.66).opacity(0.45), Color.brown.opacity(0.35)]),
        GradientPreset(name: "Midnight", colors: [Color.indigo.opacity(0.45), Color.black.opacity(0.55)]),
        GradientPreset(name: "Neon", colors: [Color.pink.opacity(0.45), Color.purple.opacity(0.35), Color.cyan.opacity(0.35)])
    ]
}

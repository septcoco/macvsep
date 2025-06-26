import SwiftUI

@propertyWrapper
struct ColorAppStorage: DynamicProperty {
    @AppStorage var storedValue: String
    
    var wrappedValue: Color {
        get { Color(hex: storedValue) ?? .accentColor }
        nonmutating set { storedValue = newValue.toHex() ?? "" }
    }
    
    var projectedValue: Binding<Color> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    init(wrappedValue: Color, _ key: String) {
        self._storedValue = AppStorage(wrappedValue: wrappedValue.toHex() ?? "", key)
    }
}

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("selectedPresetName") private var selectedPresetName: String = "Default"
    
    @ColorAppStorage(wrappedValue: .accentColor, "accentColorHex") private var accentColor
    
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("API Settings")) {
                VStack(alignment: .leading) {
                    Text("Your API Key").font(.headline)
                    SecureField("Paste your Mvsep API key here", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        if let url = URL(string: "https://mvsep.com/user-api") {
                            openURL(url)
                        }
                    }) {
                        Text("Get API Key from Mvsep Website")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    
                    Text("This will open the user API page. Click 'Create private key' there, then copy and paste the key above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider().padding(.vertical)
            
            Section {
                Picker("Appearance", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                
                ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)
                
                Picker("Background Gradient", selection: $selectedPresetName) {
                    ForEach(AppearanceManager.presets) { preset in
                        Text(preset.name).tag(preset.name)
                    }
                }
            } header: {
                Text("Appearance")
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 450, height: 450)
    }
}

extension Color {
    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = Float(components[0]); let g = Float(components[1]); let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

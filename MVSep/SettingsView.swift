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
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("selectedPresetName") private var selectedPresetName: String = "Default"
    @AppStorage("createJobSubfolders") private var createJobSubfolders: Bool = false
    
    @ColorAppStorage(wrappedValue: .accentColor, "accentColorHex") private var accentColor
    @State private var account = Account.shared
    @State private var updater = Updater.shared
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                accountSection
                outputSection
                updatesSection
                appearanceSection
            }
            .formStyle(.grouped)
            
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 480, height: 620)
        .task(id: account.apiKey) { await account.refresh() }
    }

    private var accountSection: some View {
        Section {
            SecureField("API Key", text: $account.apiKey, prompt: Text("Paste your Mvsep API key"))
            
            if let user = account.user {
                LabeledContent("Credits") {
                    Text("\(user.credits)").monospacedDigit()
                }
                Toggle(isOn: Binding(
                    get: { user.premiumEnabled },
                    set: { enabled in Task { await account.setPremiumEnabled(enabled) } }
                )) {
                    Text("Use Premium")
                    Text(account.isPremiumActive
                         ? "Jobs use credits and unlock premium formats, premium models and parallel jobs."
                         : "Jobs are free and run one at a time, without premium formats or models.")
                }
                .disabled(account.isUpdatingPremium || (user.credits == 0 && !user.premiumEnabled))
            } else if let error = account.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundColor(.red)
            } else if !account.apiKey.isEmpty {
                HStack { ProgressView().controlSize(.small); Text("Checking your account...").foregroundColor(.secondary) }
            }
        } header: {
            Text("Account")
        } footer: {
            HStack {
                Text("Your key is stored in your Mac's Keychain.")
                Spacer()
                Button("Get Your API Key...") {
                    if let url = URL(string: "https://mvsep.com/user-api") { openURL(url) }
                }
                .buttonStyle(.link)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var outputSection: some View {
        Section("Output") {
            Toggle(isOn: $createJobSubfolders) {
                Text("Save each separation in its own folder")
                Text("Files go into a subfolder named after the original file.")
            }
        }
    }

    private var updatesSection: some View {
        Section {
            Toggle("Check for updates automatically", isOn: $updater.automaticallyChecksForUpdates)
            Toggle("Download and install updates automatically", isOn: $updater.automaticallyDownloadsUpdates)
                .disabled(!updater.automaticallyChecksForUpdates)
            LabeledContent("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")") {
                Button("Check Now") { updater.checkForUpdates() }.disabled(!updater.canCheckForUpdates)
            }
        } header: {
            Text("Updates")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)
            Picker("Background", selection: $selectedPresetName) {
                ForEach(AppearanceManager.presets) { preset in
                    Text(preset.name).tag(preset.name)
                }
            }
        }
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

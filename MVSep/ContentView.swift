import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("favoriteModelIDsString") private var favoriteModelIDsString: String = ""
    @AppStorage("selectedPresetName") private var selectedPresetName: String = "Default"
    @AppStorage("selectedModelID") private var selectedModelID: Int = 20
    @AppStorage("modelSettings") private var modelSettingsData: Data = Data()
    @ColorAppStorage(wrappedValue: .accentColor, "accentColorHex") private var accentColor

    @State private var catalog = ModelCatalog.shared
    @State private var account = Account.shared
    @State private var outputFolder = OutputFolder.shared
    @State private var downloads = Downloads.shared
    @State private var job = SeparationJob()

    @State private var showingSettings = false
    @State private var isShowingModelPicker = false
    @State private var isShowingHistory = false
    @State private var selectedFormatID: Int = 0
    @State private var selectedAdditionalOptions: [String: String] = [:]
    @State private var favoriteIDs: Set<Int> = []
    @State private var droppedFilePath: URL?
    @State private var droppedFileDuration: TimeInterval?
    @State private var isTargeted = false

    private var selectedModel: SeparationModel? { catalog.model(withID: selectedModelID) ?? catalog.models.first }
    private var selectedFormat: OutputFormat { OutputFormat.all.first { $0.id == selectedFormatID } ?? OutputFormat.all[0] }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView {
                VStack(spacing: 16) {
                    fileCard; outputCard; modelCard
                    statusView
                }
                .padding(24)
            }
            actionBar
        }
        .frame(minWidth: 480, minHeight: 680).background(backgroundGradient)
        .overlay { modelPickerOverlay }
        .animation(.easeOut(duration: 0.15), value: isShowingModelPicker)
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $isShowingHistory) { HistoryView() }
        .onAppear {
            favoriteIDs = Set(favoriteModelIDsString.split(separator: ",").compactMap { Int($0) })
            loadSettings(for: selectedModel)
        }
        .task { await catalog.refresh() }
        .task(id: account.apiKey) { await account.refresh() }
        .onChange(of: selectedModelID) { loadSettings(for: selectedModel) }
        .onChange(of: catalog.models) { loadSettings(for: selectedModel) }
        .onChange(of: selectedAdditionalOptions) { saveSettings() }
        .onChange(of: selectedFormatID) { saveSettings() }
        .onChange(of: favoriteIDs) { favoriteModelIDsString = favoriteIDs.map { String($0) }.joined(separator: ",") }
        .tint(accentColor)
    }

    private var backgroundGradient: some View {
        let preset = AppearanceManager.presets.first { $0.name == selectedPresetName } ?? AppearanceManager.presets.first!
        return LinearGradient(gradient: Gradient(colors: preset.colors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            Text("MacVSep").font(.largeTitle).bold(); Spacer()
            if let user = account.user {
                premiumToggle(for: user)
            } else if account.apiKey.isEmpty {
                Button("Add API Key") { showingSettings = true }.buttonStyle(.borderedProminent).controlSize(.small)
            }
            Button(action: { isShowingHistory = true }) { Image(systemName: "clock.arrow.circlepath").font(.title2) }.buttonStyle(.plain).help("History")
            Button(action: { showingSettings.toggle() }) { Image(systemName: "gearshape.fill").font(.title2) }.buttonStyle(.plain).help("Settings")
        }
        .padding(.horizontal, 24).padding(.vertical, 14).background(.ultraThinMaterial)
    }

    /// Credits, doubling as a quick Premium on/off switch.
    private func premiumToggle(for user: UserInfo) -> some View {
        let isOn = account.isPremiumActive
        let canTurnOn = user.credits > 0
        return Button(action: { Task { await account.setPremiumEnabled(!user.premiumEnabled) } }) {
            HStack(spacing: 6) {
                if account.isUpdatingPremium {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: isOn ? "crown.fill" : "crown")
                }
                Text("\(user.credits)").monospacedDigit()
                Text(isOn ? "Active" : "Off").font(.caption.weight(.bold)).textCase(.uppercase)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background((isOn ? accentColor : Color.secondary).opacity(0.25), in: Capsule())
            }
            .font(.callout.weight(.medium))
            .foregroundColor(isOn ? accentColor : .secondary)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(isOn ? AnyShapeStyle(accentColor.opacity(0.15)) : AnyShapeStyle(.thinMaterial), in: Capsule())
            .overlay(Capsule().strokeBorder(accentColor.opacity(isOn ? 0.6 : 0), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(account.isUpdatingPremium || (!canTurnOn && !user.premiumEnabled))
        .help(isOn ? "Premium is on: \(user.credits) credits left. Click to turn it off."
              : canTurnOn ? "Premium is off: jobs are free. Click to turn it on and use your credits."
              : "Premium is off and you have no credits left.")
    }

    @ViewBuilder private var modelPickerOverlay: some View {
        if isShowingModelPicker {
            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.35)
                        .contentShape(Rectangle())
                        .onTapGesture { isShowingModelPicker = false }
                    // Escape closes the picker even when the search field isn't focused.
                    Button("") { isShowingModelPicker = false }.keyboardShortcut(.cancelAction).opacity(0).frame(width: 0, height: 0)
                    ModelPickerView(models: catalog.models, favoriteIDs: $favoriteIDs, selectedModelID: $selectedModelID,
                                    isPresented: $isShowingModelPicker, isPremiumActive: account.isPremiumActive)
                        .frame(width: max(min(proxy.size.width - 32, 520), proxy.size.width * 0.85),
                               height: max(min(proxy.size.height - 32, 420), proxy.size.height * 0.85))
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.12)))
                        .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
                }
            }
            .transition(.opacity)
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var fileCard: some View {
        Group {
            if let file = droppedFilePath {
                card("Audio File") {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform").font(.title2).foregroundColor(accentColor)
                            .frame(width: 44, height: 44).background(accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.lastPathComponent).font(.headline).lineLimit(1).truncationMode(.middle)
                            Text(fileDetails).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Change...") { showOpenFilePanel() }
                        Button(action: clearFile) { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }.buttonStyle(.plain).help("Remove")
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentColor, lineWidth: isTargeted ? 2 : 0))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.badge.plus").font(.system(size: 44)).foregroundColor(isTargeted ? accentColor : .secondary)
                    Text("Drop an audio file here").font(.headline)
                    Text("or click to browse").font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 170)
                .background(.black.opacity(isTargeted ? 0.15 : 0.25), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isTargeted ? Color.accentColor : .white.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [10])))
                .contentShape(Rectangle())
                .onTapGesture { showOpenFilePanel() }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !job.isRunning, let url = urls.first(where: isAudioFile) else { return false }
            selectFile(url)
            return true
        } isTargeted: { isTargeted = $0 }
        .disabled(job.isRunning)
    }

    private var fileDetails: String {
        var parts: [String] = []
        if let duration = droppedFileDuration { parts.append(formatDuration(duration)) }
        if let file = droppedFilePath, let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            parts.append(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        }
        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }

    private var outputCard: some View {
        card("Save To") {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill").foregroundColor(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(outputFolder.url?.lastPathComponent ?? "No folder chosen").lineLimit(1)
                    if let path = outputFolder.url?.deletingLastPathComponent().path {
                        Text((path as NSString).abbreviatingWithTildeInPath).font(.caption).foregroundColor(.secondary).lineLimit(1).truncationMode(.head)
                    }
                }
                Spacer()
                if outputFolder.url != nil {
                    Button(action: { outputFolder.reveal() }) { Image(systemName: "arrow.up.forward.square") }.buttonStyle(.borderless).help("Open in Finder")
                }
                Button("Choose...") { outputFolder.choose() }
            }
        }
    }

    private var modelCard: some View {
        card("Separation") {
            Button(action: { isShowingModelPicker = true }) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(selectedModel?.name ?? "Loading models...").fontWeight(.medium).lineLimit(1)
                            if selectedModel?.tier == .premium { PremiumBadge(locked: !account.isPremiumActive) }
                        }
                        if let group = selectedModel?.group { Text(group).font(.caption).foregroundColor(.secondary) }
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain).disabled(catalog.models.isEmpty).help(selectedModel?.summary ?? "")

            if let model = selectedModel {
                ForEach(model.additionalOptions.filter { $0.isVisible(with: selectedAdditionalOptions) }, id: \.self) { option in
                    let binding = Binding<String>(get: { self.selectedAdditionalOptions[option.parameterName] ?? "" }, set: { self.selectedAdditionalOptions[option.parameterName] = $0 })
                    switch option.kind {
                    case .choice:
                        Picker(option.uiName, selection: binding) { ForEach(option.values, id: \.self) { value in Text(value.displayName).tag(value.parameterValue) } }.pickerStyle(MenuPickerStyle())
                    case .text:
                        TextField(option.uiName, text: binding)
                    case .multilineText:
                        TextField(option.uiName, text: binding, axis: .vertical).lineLimit(2...6)
                    }
                }
            }
            Picker("Output Format", selection: $selectedFormatID) {
                ForEach(OutputFormat.all) { format in
                    Text(format.premiumOnly && !account.isPremiumActive ? "\(format.name) (Premium)" : format.name).tag(format.id)
                }
            }.pickerStyle(MenuPickerStyle())
        }
        .disabled(job.isRunning)
    }

    /// One line under the Separate button explaining what will happen, or why it can't.
    private var actionNotice: (text: String, isWarning: Bool)? {
        if let reason = blockedReason { return (reason, droppedFilePath != nil) }
        guard let model = selectedModel, let user = account.user else { return nil }
        guard account.isPremiumActive else { return ("Premium is off: this separation is free.", false) }
        guard let duration = droppedFileDuration else { return ("Premium is on: this separation will use credits.", false) }
        let credits = model.estimatedCredits(duration: duration, options: selectedAdditionalOptions)
        return ("About \(credits) credit\(credits == 1 ? "" : "s") of \(user.credits).", false)
    }

    private var blockedReason: String? {
        if droppedFilePath == nil { return "Choose an audio file to get started." }
        if outputFolder.url == nil { return "Choose where to save the results." }
        if account.apiKey.isEmpty { return "Add your API key in Settings." }
        if selectedModel == nil { return "No model selected." }
        if selectedModel?.tier == .premium && !account.isPremiumActive { return "This model requires Premium." }
        if selectedFormat.premiumOnly && !account.isPremiumActive { return "This format requires Premium." }
        return nil
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            if job.isRunning {
                Button(role: .destructive, action: { job.cancel(apiKey: account.apiKey) }) {
                    Label("Cancel", systemImage: "xmark.circle.fill").font(.title3.bold()).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).controlSize(.large).tint(.red)
            } else {
                Button(action: startSeparationProcess) {
                    Label("Separate", systemImage: "sparkles").font(.title3.bold()).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).controlSize(.large).disabled(blockedReason != nil)
                .keyboardShortcut(.return, modifiers: .command)
            }
            if !job.isRunning, let notice = actionNotice {
                Label(notice.text, systemImage: notice.isWarning ? "exclamationmark.triangle.fill" : "info.circle")
                    .font(.caption).foregroundColor(notice.isWarning ? .orange : .secondary)
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder private var statusView: some View {
        switch job.phase {
        case .idle:
            EmptyView()
        case .uploading(let progress):
            statusCard(icon: "arrow.up.circle", title: "Uploading \(job.inputName)", detail: "\(Int(progress * 100))%", progress: progress)
        case .waiting(let position, let eta):
            statusCard(icon: "hourglass", title: position.map { "In queue, position \($0)" } ?? "Waiting for the server",
                       detail: eta.flatMap { $0 > 0 ? "About \(formatDuration(TimeInterval($0))) left" : nil }, progress: nil)
        case .processing:
            statusCard(icon: "gearshape.2", title: "Processing", detail: "This can take a few minutes.", progress: nil)
        case .distributing(let finished, let total):
            statusCard(icon: "gearshape.2", title: "Processing", detail: "\(finished) of \(total) parts done", progress: Double(finished) / Double(total))
        case .merging:
            statusCard(icon: "square.stack.3d.down.right", title: "Merging parts", detail: nil, progress: nil)
        case .finished(let files):
            resultsView(files)
        case .failed(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Separation failed").font(.headline)
                    Text(message).font(.callout).foregroundColor(.secondary).textSelection(.enabled)
                }
                Spacer()
            }
            .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        case .cancelled:
            Label("Separation cancelled.", systemImage: "xmark.circle").foregroundColor(.secondary)
        }
    }

    private func statusCard(icon: String, title: String, detail: String?, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.title3).foregroundColor(accentColor).symbolEffect(.pulse, isActive: progress == nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).lineLimit(1).truncationMode(.middle)
                    if let detail { Text(detail).font(.caption).foregroundColor(.secondary) }
                }
                Spacer()
                if progress == nil { ProgressView().controlSize(.small) }
            }
            if let progress { ProgressView(value: progress) }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func resultsView(_ files: [SeparatedFile]) -> some View {
        card("Results") {
            ForEach(files) { file in
                DownloadRowView(file: file, inputName: job.inputName)
            }
            HStack {
                Spacer()
                Button(action: { Task { await downloads.download(files, inputName: job.inputName) } }) {
                    Label("Download All", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.borderedProminent)
                .disabled(outputFolder.url == nil || downloads.isBusy(files))
            }
        }
    }

    // MARK: - Files

    private func isAudioFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .audio) || type.conforms(to: .movie)
    }

    private func clearFile() {
        droppedFilePath = nil; droppedFileDuration = nil; job.reset()
    }

    private func selectFile(_ url: URL) {
        droppedFilePath = url; droppedFileDuration = nil; job.reset()
        Task {
            let duration = try? await AVURLAsset(url: url).load(.duration)
            if droppedFilePath == url, let seconds = duration?.seconds, seconds.isFinite { droppedFileDuration = seconds }
        }
    }

    private func showOpenFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false; panel.allowedContentTypes = [.audio, .movie]
        if panel.runModal() == .OK, let url = panel.url { selectFile(url) }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }

    // MARK: - Per-model settings

    private var savedSettings: [String: ModelSettings] {
        (try? JSONDecoder().decode([String: ModelSettings].self, from: modelSettingsData)) ?? [:]
    }

    private func loadSettings(for model: SeparationModel?) {
        guard let model else { return }
        var options = model.defaultOptions
        var formatID = selectedFormatID
        if let saved = savedSettings[String(model.id)] {
            for option in model.additionalOptions {
                guard let value = saved.options[option.parameterName] else { continue }
                // Ignore values the server no longer offers.
                if option.kind != .choice || option.values.contains(where: { $0.parameterValue == value }) { options[option.parameterName] = value }
            }
            formatID = saved.formatID
        }
        selectedAdditionalOptions = options
        selectedFormatID = OutputFormat.all.contains { $0.id == formatID } ? formatID : 0
    }

    private func saveSettings() {
        guard let model = selectedModel else { return }
        var all = savedSettings
        all[String(model.id)] = ModelSettings(options: selectedAdditionalOptions, formatID: selectedFormatID)
        if let data = try? JSONEncoder().encode(all) { modelSettingsData = data }
    }

    private func startSeparationProcess() {
        guard blockedReason == nil, let file = droppedFilePath, let model = selectedModel else { return }
        job.start(file: file, model: model, formatID: selectedFormatID, options: selectedAdditionalOptions, apiKey: account.apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State Variables
    
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("outputLocationString") private var outputLocationString: String = ""
    @AppStorage("favoriteModelIDsString") private var favoriteModelIDsString: String = ""
    
    @AppStorage("selectedPresetName") private var selectedPresetName: String = "Default"
    @AppStorage("accentColorData") private var accentColorData: Data = Data()
    
    @State private var showingSettings = false
    @State private var selectedModel: SeparationModel
    @State private var selectedOutputFormat: OutputFormat
    @State private var selectedAdditionalOptions: [String: String] = [:]
    
    @State private var favoriteIDs: Set<Int> = []
    @State private var isShowingModelPicker = false
    @State private var isShowingHistory = false
    
    @State private var droppedFilePath: URL?
    @State private var outputLocation: URL?
    @State private var processingState: ProcessingState = .idle
    @State private var statusMessage: String = "Drag & Drop Audio File"
    @State private var separationResults: [SeparatedFile] = []
    
    @State private var activeTaskHash: String?
    @State private var statusTimer: AnyCancellable?
    @State private var isTargeted = false
    
    init() {
        let initialModel = AppData.models.first!
        _selectedModel = State(initialValue: initialModel)
        _selectedOutputFormat = State(initialValue: AppData.outputFormats.first!)
        
        if !outputLocationString.isEmpty, let url = URL(string: outputLocationString) {
            _outputLocation = State(initialValue: url)
        }
        
        let savedIDs = favoriteModelIDsString.split(separator: ",").compactMap { Int($0) }
        _favoriteIDs = State(initialValue: Set(savedIDs))
        
        var initialOptions: [String: String] = [:]
        if let options = initialModel.additionalOptions {
            for option in options {
                if let firstValue = option.values.first {
                    initialOptions[option.parameterName] = firstValue.parameterValue
                }
            }
        }
        _selectedAdditionalOptions = State(initialValue: initialOptions)
    }
    
    enum ProcessingState { case idle, uploading, processing, finished, failed }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView {
                VStack(spacing: 24) {
                    dropZone
                    outputLocationView
                    controls
                    actionButton
                    if processingState == .uploading || processingState == .processing {
                        VStack { ProgressView().scaleEffect(1.5); Text(statusMessage).padding(.top, 8) }
                    }
                    if processingState == .finished && !separationResults.isEmpty { resultsView }
                    if processingState == .failed && statusMessage != "Drag & Drop Audio File" {
                        Text("Error: \(statusMessage)").foregroundColor(.red).padding().background(.regularMaterial).cornerRadius(16)
                    }
                }
                .padding(32)
            }
        }
        .frame(minWidth: 450, minHeight: 650).background(backgroundGradient)
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $isShowingHistory) { HistoryView(outputLocation: outputLocation) }
        .onChange(of: selectedModel) {
            var defaultOptions: [String: String] = [:]; if let options = selectedModel.additionalOptions {
                for option in options { if let firstValue = option.values.first { defaultOptions[option.parameterName] = firstValue.parameterValue } }
            }
            selectedAdditionalOptions = defaultOptions
        }
        .onChange(of: favoriteIDs) { favoriteModelIDsString = favoriteIDs.map { String($0) }.joined(separator: ",") }
    }

    private var sortedModels: [SeparationModel] {
        AppData.models.sorted { (a, b) in
            let isAFavorite = favoriteIDs.contains(a.id); let isBFavorite = favoriteIDs.contains(b.id)
            if isAFavorite && !isBFavorite { return true } else if !isAFavorite && isBFavorite { return false } else { return a.name < b.name }
        }
    }
    
    private var backgroundGradient: some View {
        let selectedPreset = AppearanceManager.presets.first { $0.name == selectedPresetName } ?? AppearanceManager.presets.first!
        return LinearGradient(gradient: Gradient(colors: selectedPreset.colors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
    
    private var loadedAccentColor: Color {
        if let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: accentColorData) {
            return Color(nsColor)
        }
        return .accentColor
    }

    private var headerView: some View {
        HStack {
            Text("MacVSep").font(.largeTitle).bold(); Spacer()
            Button(action: { isShowingHistory = true }) { Image(systemName: "clock.arrow.circlepath").font(.title2) }.buttonStyle(.plain)
            Button(action: { showingSettings.toggle() }) { Image(systemName: "gearshape.fill").font(.title2) }.buttonStyle(.plain)
        }
        .padding().background(.ultraThinMaterial)
    }
    
    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: droppedFilePath == nil ? "music.mic.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 60)).foregroundColor(droppedFilePath == nil ? .secondary : .green)
            Text(statusMessage).font(.headline).multilineTextAlignment(.center).frame(width: 250)
        }
        .frame(maxWidth: .infinity, minHeight: 200).background(.black.opacity(0.25)).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isTargeted ? Color.accentColor : .white.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [10])))
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                    DispatchQueue.main.async { self.droppedFilePath = url; self.statusMessage = url.lastPathComponent; self.separationResults = []; self.processingState = .idle }
                }
            })
            return true
        }
        .onTapGesture { showOpenFilePanel() }
    }
    
    private var outputLocationView: some View {
        VStack(alignment: .leading) {
            Text("Output Location").font(.headline)
            HStack {
                Image(systemName: "folder.fill").foregroundColor(.accentColor); Text(outputLocation?.lastPathComponent ?? "Choose a folder...").font(.callout).lineLimit(1); Spacer()
                Button("Choose...", action: showSavePanel)
            }
        }
        .padding(20).background(.regularMaterial).cornerRadius(16)
    }
    
    private var controls: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Separation Model").font(.caption).foregroundColor(.secondary)
                Button(action: { isShowingModelPicker = true }) {
                    HStack { Text(selectedModel.name); Spacer(); Image(systemName: "chevron.up.chevron.down").font(.caption) }
                    .padding(8).background(Color(nsColor: .controlBackgroundColor)).cornerRadius(5)
                }
                .buttonStyle(.plain).popover(isPresented: $isShowingModelPicker, arrowEdge: .bottom) {
                    ModelPickerView(sortedModels: sortedModels, favoriteIDs: $favoriteIDs, selectedModel: $selectedModel, isShowingPopover: $isShowingModelPicker)
                }
            }
            if let additionalOptions = selectedModel.additionalOptions {
                ForEach(additionalOptions, id: \.self) { option in
                    let binding = Binding<String>(get: { self.selectedAdditionalOptions[option.parameterName] ?? "" }, set: { self.selectedAdditionalOptions[option.parameterName] = $0 })
                    Picker(option.uiName, selection: binding) {
                        ForEach(option.values, id: \.self) { value in Text(value.displayName).tag(value.parameterValue) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            Picker("Output Format", selection: $selectedOutputFormat) {
                ForEach(AppData.outputFormats) { format in Text(format.name).tag(format) }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(20).background(.regularMaterial).cornerRadius(16)
    }
    
    private var actionButton: some View {
        Button(action: startSeparationProcess) {
            HStack { Image(systemName: "sparkles"); Text("Separate") }.font(.title3.bold()).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).controlSize(.large)
        .disabled(processingState != .idle || droppedFilePath == nil || outputLocation == nil || apiKey.isEmpty)
    }

    private var resultsView: some View {
        VStack(alignment: .leading) {
            Text("Results").font(.title2.bold()).padding(.bottom, 5)
            ForEach(separationResults) { file in
                HStack {
                    Image(systemName: "waveform"); Text(file.fileName); Spacer()
                    Button(action: { downloadFile(file) }) { Image(systemName: "square.and.arrow.down") }.buttonStyle(.borderless)
                }
                .padding().background(.regularMaterial).cornerRadius(12)
            }
        }
    }
    
    private func resetToIdleState(message: String? = nil) {
        statusTimer?.cancel(); activeTaskHash = nil; processingState = .idle
        statusMessage = message ?? (droppedFilePath?.lastPathComponent ?? "Drag & Drop Audio File")
    }
    
    private func toggleFavorite(for model: SeparationModel) {
        if favoriteIDs.contains(model.id) { favoriteIDs.remove(model.id) }
        else { favoriteIDs.insert(model.id) }
    }
    
    private func showOpenFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK, let url = panel.url {
            self.droppedFilePath = url; self.statusMessage = url.lastPathComponent
            self.separationResults = []; self.processingState = .idle
        }
    }
    
    private func showSavePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            self.outputLocation = url; self.outputLocationString = url.absoluteString
        }
    }
    
    private func startSeparationProcess() {
        guard let sourceURL = droppedFilePath else { return }
        processingState = .uploading; statusMessage = "Uploading file..."; separationResults = []
        APIService.shared.submitTask(filePath: sourceURL, apiKey: apiKey, modelID: selectedModel.id, formatID: selectedOutputFormat.id, additionalOptions: selectedAdditionalOptions) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let hash):
                    self.activeTaskHash = hash; self.processingState = .processing; self.statusMessage = "File uploaded. Waiting for processing..."
                    self.startStatusTimer()
                case .failure(let error): self.resetToIdleState(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func startStatusTimer() {
        statusTimer?.cancel()
        statusTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { _ in
            guard let hash = activeTaskHash else { self.resetToIdleState(message: "Error: No active task hash found."); return }
            APIService.shared.checkStatus(hash: hash) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.status == "done" {
                            self.statusTimer?.cancel(); self.processingState = .finished; self.statusMessage = "Separation Complete!"
                            if let files = response.data?.files {
                                self.separationResults = files.map { apiFile in SeparatedFile(fileName: apiFile.download, downloadURL: apiFile.url) }
                            }
                        } else if response.status == "failed" {
                            self.resetToIdleState(message: response.data?.message ?? "The separation process failed on the server.")
                        } else { self.statusMessage = response.status.capitalized }
                    case .failure(let error): self.resetToIdleState(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func downloadFile(_ file: SeparatedFile) {
        guard let outputDir = outputLocation else { return }
        let destinationURL = outputDir.appendingPathComponent(file.fileName)
        APIService.shared.downloadFile(fromURL: file.downloadURL, to: destinationURL) { result in
            switch result {
            case .success(_): print("Download complete for \(file.fileName)")
            case .failure(let error): print("Download failed for \(file.fileName): \(error.localizedDescription)")
            }
        }
    }
}

struct ModelPickerView: View {
    let sortedModels: [SeparationModel]; @Binding var favoriteIDs: Set<Int>; @Binding var selectedModel: SeparationModel; @Binding var isShowingPopover: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortedModels) { model in
                    HStack {
                        Text(model.name).padding(.vertical, 6).contentShape(Rectangle()).onTapGesture { self.selectedModel = model; self.isShowingPopover = false }
                        Spacer()
                        Button(action: { toggleFavorite(for: model) }) {
                            Image(systemName: favoriteIDs.contains(model.id) ? "star.fill" : "star").foregroundColor(favoriteIDs.contains(model.id) ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 100, maxHeight: 300).padding(.vertical, 5)
    }
    private func toggleFavorite(for model: SeparationModel) {
        if favoriteIDs.contains(model.id) { favoriteIDs.remove(model.id) } else { favoriteIDs.insert(model.id) }
    }
}

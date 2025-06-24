import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @State private var showingSettings = false
    
    @State private var selectedModel: SeparationModel
    @State private var selectedOutputFormat: OutputFormat
    @State private var selectedAdditionalOptions: [String: String] = [:]
    
    @State private var droppedFilePath: URL?
    @AppStorage("outputLocationString") private var outputLocationString: String = ""
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
        
        // --- FIX ---
        var initialOptions: [String: String] = [:]
        if let options = initialModel.additionalOptions {
            for option in options {
                if let firstValue = option.values.first {
                    initialOptions[option.parameterName] = firstValue.parameterValue
                }
            }
        }
        // Load the saved URL string at startup
        if !outputLocationString.isEmpty {
            _outputLocation = State(initialValue: URL(string: outputLocationString))
        } else {
            _outputLocation = State(initialValue: nil)
        }
        _selectedAdditionalOptions = State(initialValue: initialOptions)
    }
    
    enum ProcessingState {
        case idle, uploading, processing, finished, failed
    }

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
                        VStack {
                            ProgressView().scaleEffect(1.5)
                            Text(statusMessage).padding(.top, 8)
                        }
                    }
                    
                    if processingState == .finished && !separationResults.isEmpty {
                        resultsView
                    }
                    
                    if processingState == .failed {
                        Text("Error: \(statusMessage)")
                            .foregroundColor(.red)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(16)
                    }
                }
                .padding(32)
            }
        }
        .frame(minWidth: 450, minHeight: 650)
        .background(backgroundGradient)
        .sheet(isPresented: $showingSettings) { SettingsView() }
        // --- FIX 2b ---
        .onChange(of: selectedModel) { newModel in
            var defaultOptions: [String: String] = [:]
            if let options = newModel.additionalOptions {
                for option in options {
                    if let firstValue = option.values.first {
                        defaultOptions[option.parameterName] = firstValue.parameterValue
                    }
                }
            }
            selectedAdditionalOptions = defaultOptions
        }
    }

    private var headerView: some View {
        HStack {
            Text("MacVsep").font(.largeTitle).bold()
            Spacer()
            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gearshape.fill").font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding().background(.ultraThinMaterial)
    }
    
    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: droppedFilePath == nil ? "music.mic.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(droppedFilePath == nil ? .secondary : .green)
            
            Text(statusMessage)
                .font(.headline).multilineTextAlignment(.center).frame(width: 250)
        }
        .frame(maxWidth: .infinity, minHeight: 200).background(.black.opacity(0.25)).cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(isTargeted ? Color.accentColor : .white.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [10]))
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                    DispatchQueue.main.async {
                        self.droppedFilePath = url
                        self.statusMessage = url.lastPathComponent
                    }
                }
            })
            return true
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    private var outputLocationView: some View {
        VStack(alignment: .leading) {
            Text("Output Location").font(.headline)
            HStack {
                Image(systemName: "folder.fill").foregroundColor(.accentColor)
                Text(outputLocation?.lastPathComponent ?? "Choose a folder...").font(.callout).lineLimit(1)
                Spacer()
                Button("Choose...", action: showSavePanel)
            }
        }
        .padding(20).background(.regularMaterial).cornerRadius(16)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Picker("Separation Model", selection: $selectedModel) {
                ForEach(AppData.models) { model in
                    Text(model.name).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            if let additionalOptions = selectedModel.additionalOptions {
                ForEach(additionalOptions, id: \.self) { option in
                    let binding = Binding<String>(
                        get: { self.selectedAdditionalOptions[option.parameterName] ?? "" },
                        set: { self.selectedAdditionalOptions[option.parameterName] = $0 }
                    )
                    
                    Picker(option.uiName, selection: binding) {
                        ForEach(option.values, id: \.self) { value in
                            Text(value.displayName).tag(value.parameterValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Picker("Output Format", selection: $selectedOutputFormat) {
                ForEach(AppData.outputFormats) { format in
                    Text(format.name).tag(format)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(20).background(.regularMaterial).cornerRadius(16)
    }
    
    private var actionButton: some View {
        Button(action: startSeparationProcess) {
            HStack { Image(systemName: "sparkles"); Text("Separate") }
            .font(.title3.bold()).frame(maxWidth: .infinity)
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
                    Button(action: { downloadFile(file) }) { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(.borderless)
                }
                .padding().background(.regularMaterial).cornerRadius(12)
            }
        }
    }
    
    private func showSavePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK { self.outputLocation = panel.url
            self.outputLocationString = panel.url?.absoluteString ?? "" }
    }
    
    private func startSeparationProcess() {
        guard let sourceURL = droppedFilePath else { return }
        
        processingState = .uploading
        statusMessage = "Uploading file..."
        separationResults = []

        APIService.shared.submitTask(
            filePath: sourceURL,
            apiKey: apiKey,
            modelID: selectedModel.id,
            formatID: selectedOutputFormat.id,
            additionalOptions: selectedAdditionalOptions
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let hash):
                    self.activeTaskHash = hash
                    self.processingState = .processing
                    self.statusMessage = "File uploaded. Waiting for processing..."
                    self.startStatusTimer()
                case .failure(let error):
                    self.processingState = .failed
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func startStatusTimer() {
        statusTimer?.cancel()
        statusTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { _ in
            guard let hash = activeTaskHash else { statusTimer?.cancel(); return }
            
            APIService.shared.checkStatus(hash: hash) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.statusMessage = response.status.capitalized
                        if response.status == "done" {
                            self.statusTimer?.cancel()
                            self.processingState = .finished
                            self.statusMessage = "Separation Complete!"
                            if let files = response.data?.files {
                                self.separationResults = files.map { apiFile in SeparatedFile(fileName: apiFile.download, downloadURL: apiFile.url) }
                            }
                        } else if response.status == "failed" {
                            self.statusTimer?.cancel()
                            self.processingState = .failed
                            self.statusMessage = "The separation process failed on the server."
                        }
                    case .failure(let error):
                        self.statusTimer?.cancel()
                        self.processingState = .failed
                        self.statusMessage = error.localizedDescription
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

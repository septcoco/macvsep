import SwiftUI

struct HistoryView: View {
    @AppStorage("localJobHistory") private var localJobHistoryData: Data = Data()
    @Environment(\.presentationMode) var presentationMode
    
    let outputLocation: URL?
    
    @State private var historyJobs: [LocalJob] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Separation History")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            if historyJobs.isEmpty {
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                    Text("Your separation history is empty.")
                    Text("Completed jobs will appear here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(historyJobs) { job in
                    HistoryRowView(job: job, outputLocation: outputLocation)
                }
                .listStyle(InsetListStyle())
            }
        }
        .frame(minWidth: 550, minHeight: 400)
        .onAppear(perform: loadHistory)
    }
    
    private func loadHistory() {
        if let decodedJobs = try? JSONDecoder().decode([LocalJob].self, from: localJobHistoryData) {
            self.historyJobs = decodedJobs
        }
    }
}

struct HistoryRowView: View {
    let job: LocalJob
    let outputLocation: URL?
    
    @State private var liveStatus: String?
    @State private var downloadLinks: [APIFileResult] = []
    
    @State private var isDownloading = false
    @State private var downloadFinished = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(job.inputFileName)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(job.modelName)
                    .font(.subheadline)
                Text(job.submissionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let status = liveStatus {
                if status.lowercased() == "done" {
                    Button(action: reDownload) {
                        if isDownloading {
                            ProgressView().controlSize(.small)
                        } else if downloadFinished {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                    }
                    .buttonStyle(.plain)
                    .controlSize(.large)
                    .disabled(outputLocation == nil || isDownloading)
                    .help("Re-download to your currently selected output folder")
                } else {
                    Text(status.capitalized)
                        .font(.headline)
                        .foregroundColor(statusColor(for: status))
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.vertical, 8)
        .opacity(liveStatus == "Expired" ? 0.5 : 1.0)
        .onAppear(perform: checkLiveStatus)
    }
    
    private func checkLiveStatus() {
        APIService.shared.checkStatus(hash: job.hash) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.status == "not_found" {
                        self.liveStatus = "Expired"
                    } else {
                        self.liveStatus = response.status
                        if response.status == "done" {
                            self.downloadLinks = response.data?.files ?? []
                        }
                    }
                case .failure:
                    self.liveStatus = "Error"
                }
            }
        }
    }
    
    private func reDownload() {
        guard let outputDir = outputLocation, !downloadLinks.isEmpty else { return }
        isDownloading = true
        downloadFinished = false
        let dispatchGroup = DispatchGroup()
        for fileResult in downloadLinks {
            dispatchGroup.enter()
            let destinationURL = outputDir.appendingPathComponent(fileResult.download)
            APIService.shared.downloadFile(fromURL: fileResult.url, to: destinationURL) { result in
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            isDownloading = false
            downloadFinished = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                downloadFinished = false
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "done": return .green
        case "failed", "error", "expired": return .red
        default: return .orange
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(outputLocation: nil)
    }
}

import SwiftUI

struct HistoryView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @Environment(\.presentationMode) var presentationMode
    let outputLocation: URL?
    @State private var historyJobs: [HistoryJob] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Separation History").font(.largeTitle).bold(); Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }.buttonStyle(.borderedProminent)
            }
            .padding().background(.ultraThinMaterial)
            
            if isLoading { ProgressView("Loading History...").frame(maxWidth: .infinity, maxHeight: .infinity) }
            else if let errorMessage = errorMessage { Text("Error: \(errorMessage)").foregroundColor(.red).frame(maxWidth: .infinity, maxHeight: .infinity) }
            else if historyJobs.isEmpty {
                VStack {
                    Image(systemName: "clock.fill").font(.largeTitle).foregroundColor(.secondary).padding(.bottom, 5)
                    Text("Your separation history is empty.").font(.caption).foregroundColor(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(historyJobs) { job in
                    HistoryRowView(job: job, outputLocation: outputLocation)
                }.listStyle(InsetListStyle())
            }
        }
        .frame(minWidth: 550, minHeight: 400).onAppear(perform: loadHistory)
    }
    
    private func loadHistory() {
        isLoading = true; errorMessage = nil
        APIService.shared.fetchHistory(apiKey: apiKey) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobs): self.historyJobs = jobs
                case .failure(let error): self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}

struct HistoryRowView: View {
    let job: HistoryJob
    let outputLocation: URL?
    @State private var liveStatus: StatusResponse?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(liveStatus?.data?.files?.first?.download ?? job.hash).fontWeight(.bold).lineLimit(1)
                    Text(job.algorithm.name).font(.subheadline)
                    if let timeLeft = job.time_left { Text("Expires in: ~\(timeLeft) hrs").font(.caption).foregroundColor(.secondary) }
                }
                Spacer()
                if let status = liveStatus?.status {
                    if status.lowercased() == "done" && job.job_exists {
                        Button(action: reDownload) {
                            if isDownloading { ProgressView().controlSize(.small) }
                            else { Image(systemName: "arrow.down.circle.fill") }
                        }.buttonStyle(.plain).controlSize(.large).disabled(outputLocation == nil || isDownloading)
                    } else { Text(job.job_exists ? status.capitalized : "Expired").font(.headline).foregroundColor(statusColor(for: status)) }
                } else { ProgressView().controlSize(.small) }
            }
            if isDownloading { ProgressView(value: downloadProgress).progressViewStyle(LinearProgressViewStyle()).padding(.top, 4) }
        }
        .padding(.vertical, 8).opacity(job.job_exists ? 1.0 : 0.5).onAppear(perform: checkLiveStatus)
    }
    
    private func checkLiveStatus() {
        APIService.shared.checkStatus(hash: job.hash) { result in
            DispatchQueue.main.async {
                if case .success(let response) = result { self.liveStatus = response } else { self.liveStatus = StatusResponse(success: false, status: "Error", data: nil) }
            }
        }
    }
    
    private func reDownload() {
        guard let outputDir = outputLocation, let files = liveStatus?.data?.files, !files.isEmpty else { return }
        isDownloading = true; downloadProgress = 0
        let totalFiles = files.count; var completedFiles = 0
        let dispatchGroup = DispatchGroup()
        for fileResult in files {
            dispatchGroup.enter()
            let destinationURL = outputDir.appendingPathComponent(fileResult.download)
            APIService.shared.downloadFile(fromURL: fileResult.url, to: destinationURL, progressHandler: { progress in
                let totalProgress = (Double(completedFiles) + progress) / Double(totalFiles)
                DispatchQueue.main.async { self.downloadProgress = totalProgress }
            }) { result in
                if case .success = result { completedFiles += 1 }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            isDownloading = false
            let message = completedFiles > 1 ? "\(completedFiles) files were saved." : "'\(files.first!.download)' was saved."
            NotificationManager.shared.sendNotification(title: "Download Complete", body: completedFiles > 0 ? message : "Could not retrieve files from server.")
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "done": return .green; case "failed", "error": return .red; default: return job.job_exists ? .orange : .secondary
        }
    }
}

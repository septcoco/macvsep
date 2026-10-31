import SwiftUI

struct HistoryView: View {
    @State private var account = Account.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var historyJobs: [HistoryJob] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Separation History").font(.largeTitle).bold(); Spacer()
                Button(action: { Task { await loadHistory() } }) { Image(systemName: "arrow.clockwise") }.buttonStyle(.plain).disabled(isLoading).help("Refresh")
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
                    HistoryRowView(job: job)
                }.listStyle(InsetListStyle())
            }
        }
        .frame(minWidth: 550, minHeight: 400).task { await loadHistory() }
    }

    private func loadHistory() async {
        isLoading = true; errorMessage = nil
        do { historyJobs = try await APIService.shared.fetchHistory(apiKey: account.apiKey) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}

struct HistoryRowView: View {
    let job: HistoryJob
    @State private var liveStatus: StatusResponse?
    @State private var downloads = Downloads.shared
    @State private var outputFolder = OutputFolder.shared

    private var files: [SeparatedFile] {
        (liveStatus?.data?.files ?? []).map { SeparatedFile(fileName: $0.download, downloadURL: $0.url) }
    }

    /// Hashes look like "20261031174216-516306bf3c-song.mp3"; the original file name comes last.
    private var inputName: String {
        let parts = job.hash.split(separator: "-", maxSplits: 2)
        return parts.count == 3 ? String(parts[2]) : job.hash
    }

    private var savedCount: Int {
        files.filter { if case .finished = downloads.state(for: $0) { return true } else { return false } }.count
    }

    var body: some View {
        let isDownloading = downloads.isBusy(files)
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(inputName).fontWeight(.bold).lineLimit(1)
                    Text(job.algorithm.name).font(.subheadline)
                    HStack(spacing: 8) {
                        if let timeLeft = job.time_left, job.job_exists { Text("Expires in: ~\(timeLeft) hrs") }
                        if let credits = job.credits, credits > 0 { Text("\(credits) credit\(credits == 1 ? "" : "s")") }
                    }.font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if !job.job_exists {
                    Text("Expired").font(.headline).foregroundColor(.secondary)
                } else if let status = liveStatus?.status {
                    if status.lowercased() == "done" && !files.isEmpty {
                        if !files.isEmpty && savedCount == files.count {
                            Button(action: { outputFolder.reveal(nil) }) { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                                .buttonStyle(.plain).controlSize(.large).help("Show in Finder")
                        } else {
                            Button(action: reDownload) {
                                if isDownloading { ProgressView().controlSize(.small) }
                                else { Image(systemName: "arrow.down.circle.fill") }
                            }.buttonStyle(.plain).controlSize(.large).disabled(outputFolder.url == nil || isDownloading)
                            .help("Download all \(files.count) files")
                        }
                    } else { Text(status.capitalized).font(.headline).foregroundColor(statusColor(for: status)) }
                } else { ProgressView().controlSize(.small) }
            }
            if isDownloading {
                ProgressView(value: overallProgress).progressViewStyle(LinearProgressViewStyle()).padding(.top, 4)
            }
        }
        .padding(.vertical, 8).opacity(job.job_exists ? 1.0 : 0.5)
        .task { if job.job_exists { await checkLiveStatus() } }
    }

    private var overallProgress: Double {
        guard !files.isEmpty else { return 0 }
        let total = files.reduce(0.0) { sum, file in
            switch downloads.state(for: file) {
            case .downloading(let progress): return sum + progress
            case .finished, .failed: return sum + 1
            case nil: return sum
            }
        }
        return total / Double(files.count)
    }

    private func checkLiveStatus() async {
        do { liveStatus = try await APIService.shared.checkStatus(hash: job.hash) }
        catch { liveStatus = StatusResponse(success: false, status: "Error", data: nil) }
    }

    private func reDownload() {
        Task { await downloads.download(files, inputName: inputName) }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "done": return .green; case "failed", "error", "not_found": return .red; default: return .orange
        }
    }
}

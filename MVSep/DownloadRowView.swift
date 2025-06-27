import SwiftUI

struct DownloadRowView: View {
    let file: SeparatedFile
    let outputLocation: URL?
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadFinished = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "waveform"); Text(file.fileName).lineLimit(1); Spacer()
                Button(action: download) {
                    if isDownloading { ProgressView().controlSize(.small) }
                    else if downloadFinished { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                    else { Image(systemName: "square.and.arrow.down") }
                }.buttonStyle(.borderless).disabled(isDownloading || downloadFinished)
            }
            if isDownloading { ProgressView(value: downloadProgress).progressViewStyle(LinearProgressViewStyle()) }
        }
        .padding().background(.regularMaterial).cornerRadius(12)
    }
    
    private func download() {
        guard let outputDir = outputLocation else { return }
        isDownloading = true; downloadProgress = 0
        let destinationURL = outputDir.appendingPathComponent(file.fileName)
        APIService.shared.downloadFile(fromURL: file.downloadURL, to: destinationURL, progressHandler: { progress in
            DispatchQueue.main.async { self.downloadProgress = progress }
        }) { result in
            DispatchQueue.main.async {
                self.isDownloading = false
                switch result {
                case .success:
                    self.downloadFinished = true
                    NotificationManager.shared.sendNotification(title: "Download Complete", body: "\(file.fileName) has been saved.")
                case .failure(let error):
                    NotificationManager.shared.sendNotification(title: "Download Failed", body: "Could not save \(file.fileName). Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

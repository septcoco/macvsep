import SwiftUI

struct DownloadRowView: View {
    let file: SeparatedFile
    let inputName: String
    @State private var downloads = Downloads.shared
    @State private var outputFolder = OutputFolder.shared

    var body: some View {
        let state = downloads.state(for: file)
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "waveform").foregroundColor(.secondary); Text(file.fileName).lineLimit(1).truncationMode(.middle); Spacer()
                switch state {
                case .downloading:
                    ProgressView().controlSize(.small)
                case .finished(let url):
                    Button(action: { outputFolder.reveal(url) }) { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                        .buttonStyle(.borderless).help("Show in Finder")
                case .failed(let message):
                    Button(action: download) { Image(systemName: "exclamationmark.arrow.circlepath").foregroundColor(.red) }
                        .buttonStyle(.borderless).help("\(message)\nClick to retry.")
                case nil:
                    Button(action: download) { Image(systemName: "square.and.arrow.down") }
                        .buttonStyle(.borderless).disabled(outputFolder.url == nil)
                }
            }
            if case .downloading(let progress) = state { ProgressView(value: progress).progressViewStyle(LinearProgressViewStyle()) }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    private func download() {
        Task { await downloads.download([file], inputName: inputName) }
    }
}

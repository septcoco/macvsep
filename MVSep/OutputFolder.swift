import AppKit
import Observation

/// The folder separations are saved to. Stored as a security-scoped bookmark so the sandbox
/// still lets us write there after the app is relaunched.
@MainActor @Observable
final class OutputFolder {
    static let shared = OutputFolder()

    private(set) var url: URL?
    private static let bookmarkKey = "outputFolderBookmark"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &isStale) {
                use(url)
                if isStale { saveBookmark(for: url) }
            }
        }
        UserDefaults.standard.removeObject(forKey: "outputLocationString")
    }

    func choose() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false; panel.canCreateDirectories = true
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        use(url)
        saveBookmark(for: url)
    }

    /// Where to save the results of one separation, creating a subfolder for it if the user asked for that.
    func destination(forInputNamed inputName: String) throws -> URL? {
        guard let url else { return nil }
        guard UserDefaults.standard.bool(forKey: "createJobSubfolders") else { return url }
        let base = (inputName as NSString).deletingPathExtension
        let name = base.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let folder = url.appendingPathComponent(name.isEmpty ? "Separation" : name, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func reveal(_ fileURL: URL? = nil) {
        if let fileURL { NSWorkspace.shared.activateFileViewerSelecting([fileURL]) }
        else if let url { NSWorkspace.shared.open(url) }
    }

    private func use(_ newURL: URL) {
        url?.stopAccessingSecurityScopedResource()
        _ = newURL.startAccessingSecurityScopedResource()
        url = newURL
    }

    private func saveBookmark(for url: URL) {
        if let data = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
        }
    }
}

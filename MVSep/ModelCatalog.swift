import Foundation
import Observation

/// The list of separation models. Starts from the last list fetched (or the one shipped with the app)
/// and refreshes from MVSep in the background, so new models show up without an app update.
@MainActor @Observable
final class ModelCatalog {
    static let shared = ModelCatalog()

    private(set) var models: [SeparationModel] = []
    private(set) var isRefreshing = false

    private let cacheURL: URL = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("Algorithms.json")
    }()

    private init() {
        let sources = [cacheURL, Bundle.main.url(forResource: "Algorithms", withExtension: "json")].compactMap { $0 }
        for source in sources {
            if let data = try? Data(contentsOf: source), let models = Self.decode(data), !models.isEmpty {
                self.models = models
                break
            }
        }
    }

    func model(withID id: Int) -> SeparationModel? { models.first { $0.id == id } }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        guard let data = try? await APIService.shared.fetchAlgorithms(), let models = Self.decode(data), !models.isEmpty else { return }
        self.models = models
        try? data.write(to: cacheURL, options: .atomic)
    }

    private static func decode(_ data: Data) -> [SeparationModel]? {
        guard let algorithms = try? JSONDecoder().decode([APIAlgorithm].self, from: data) else { return nil }
        return algorithms
            .filter { ($0.audio_widget ?? "single_upload") == "single_upload" }
            .map(\.model)
            .sorted { ($0.order, $0.name) < ($1.order, $1.name) }
    }
}

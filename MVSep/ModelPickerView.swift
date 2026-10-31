import SwiftUI

struct ModelPickerView: View {
    let models: [SeparationModel]
    @Binding var favoriteIDs: Set<Int>
    @Binding var selectedModelID: Int
    @Binding var isShowingPopover: Bool
    let isPremiumActive: Bool
    @State private var searchText = ""
    @State private var hoveredModelID: Int?

    private var filteredModels: [SeparationModel] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return models }
        return models.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.group.localizedCaseInsensitiveContains(query) }
    }

    /// Favorites first, then the server's groups in the order their first model appears.
    private var sections: [(title: String, models: [SeparationModel])] {
        let filtered = filteredModels
        var result: [(title: String, models: [SeparationModel])] = []
        let favorites = filtered.filter { favoriteIDs.contains($0.id) }.sorted { $0.name < $1.name }
        if !favorites.isEmpty { result.append(("Favorites", favorites)) }
        var groupOrder: [String] = []
        var grouped: [String: [SeparationModel]] = [:]
        for model in filtered {
            if grouped[model.group] == nil { groupOrder.append(model.group) }
            grouped[model.group, default: []].append(model)
        }
        // Retired models stay available but shouldn't crowd the list.
        let oldGroups = groupOrder.filter { $0.localizedCaseInsensitiveContains("old") }
        for group in groupOrder.filter({ !oldGroups.contains($0) }) + oldGroups { result.append((group, grouped[group]!)) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search \(models.count) models", text: $searchText).textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }.buttonStyle(.plain)
                }
            }
            .padding(10)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections, id: \.title) { section in
                        Section {
                            ForEach(section.models) { model in row(for: model) }
                        } header: {
                            Text(section.title).font(.caption.bold()).foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.vertical, 4).background(.bar)
                        }
                    }
                    if sections.isEmpty { Text("No models match your search.").foregroundColor(.secondary).padding() }
                }
            }
        }
        .frame(width: 420).frame(minHeight: 100, maxHeight: 420)
    }

    private func row(for model: SeparationModel) -> some View {
        HStack {
            Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(.accentColor).opacity(model.id == selectedModelID ? 1 : 0)
            Text(model.name).fontWeight(model.id == selectedModelID ? .semibold : .regular).lineLimit(1)
                .padding(.vertical, 6)
            if model.tier == .premium { PremiumBadge(locked: !isPremiumActive) }
            Spacer()
            Button(action: { toggleFavorite(for: model) }) {
                Image(systemName: favoriteIDs.contains(model.id) ? "star.fill" : "star")
                    .foregroundColor(favoriteIDs.contains(model.id) ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .background(model.id == hoveredModelID ? Color.accentColor.opacity(0.12) : .clear)
        .onHover { hoveredModelID = $0 ? model.id : (hoveredModelID == model.id ? nil : hoveredModelID) }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedModelID = model.id
            isShowingPopover = false
        }
        .help(tooltip(for: model))
    }

    private func tooltip(for model: SeparationModel) -> String {
        var stats = ["Used \(model.usage.formatted()) times this month"]
        if let rating = model.rating { stats.insert(String(format: "Rated %.1f/5", rating), at: 0) }
        return model.summary.isEmpty ? stats.joined(separator: " · ") : "\(model.summary)\n\n\(stats.joined(separator: " · "))"
    }

    private func toggleFavorite(for model: SeparationModel) {
        if favoriteIDs.contains(model.id) {
            favoriteIDs.remove(model.id)
        } else {
            favoriteIDs.insert(model.id)
        }
    }
}

/// Small "Premium" tag shown next to premium-only models.
struct PremiumBadge: View {
    let locked: Bool

    var body: some View {
        Label("Premium", systemImage: locked ? "lock.fill" : "crown.fill")
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundColor(locked ? .secondary : .orange)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background((locked ? Color.secondary : Color.orange).opacity(0.15), in: Capsule())
            .help(locked ? "Turn on Premium in Settings to use this model." : "Premium model")
    }
}

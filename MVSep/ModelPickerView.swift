import SwiftUI

struct ModelPickerView: View {
    let sortedModels: [SeparationModel]
    @Binding var favoriteIDs: Set<Int>
    @Binding var selectedModel: SeparationModel
    @Binding var isShowingPopover: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortedModels) { model in
                    HStack {
                        Text(model.name)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedModel = model
                                self.isShowingPopover = false
                            }
                        
                        Spacer()
                        
                        Button(action: {
                            toggleFavorite(for: model)
                        }) {
                            Image(systemName: favoriteIDs.contains(model.id) ? "star.fill" : "star")
                                .foregroundColor(favoriteIDs.contains(model.id) ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 100, maxHeight: 300)
        .padding(.vertical, 5)
    }
    
    private func toggleFavorite(for model: SeparationModel) {
        if favoriteIDs.contains(model.id) {
            favoriteIDs.remove(model.id)
        } else {
            favoriteIDs.insert(model.id)
        }
    }
}

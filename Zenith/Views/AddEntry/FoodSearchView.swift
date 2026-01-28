import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodItem.name) private var foodItems: [FoodItem]
    @State private var searchText = ""

    let onSelect: (FoodItem) -> Void

    private var filtered: [FoodItem] {
        if searchText.isEmpty { return foodItems }
        return foodItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filtered, id: \.id) { item in
            Button {
                onSelect(item)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.body)
                        HStack(spacing: 8) {
                            MacroLabel("P", value: item.proteinGrams, color: .proteinColor)
                            MacroLabel("F", value: item.fatGrams, color: .fatColor)
                            MacroLabel("C", value: item.carbsGrams, color: .carbsColor)
                        }
                    }
                    Spacer()
                    Text("\(item.calories) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Search Foods")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

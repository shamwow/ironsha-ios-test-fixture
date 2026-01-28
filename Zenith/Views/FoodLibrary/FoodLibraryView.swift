import SwiftUI
import SwiftData

struct FoodLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.name) private var foodItems: [FoodItem]
    @State private var searchText = ""

    private var filtered: [FoodItem] {
        if searchText.isEmpty { return foodItems }
        return foodItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filtered, id: \.id) { item in
                NavigationLink {
                    FoodItemDetailView(foodItem: item)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.body)
                            HStack(spacing: 6) {
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
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(filtered[index])
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Food Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FoodItemDetailView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if foodItems.isEmpty {
                ContentUnavailableView(
                    "No saved foods",
                    systemImage: "carrot",
                    description: Text("Tap + to create your first food item.")
                )
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

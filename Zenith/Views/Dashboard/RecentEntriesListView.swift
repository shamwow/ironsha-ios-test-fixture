import SwiftUI
import SwiftData

// Original name kept as typealias for compatibility
typealias RecentEntriesListView = RecentEntriesCardView

struct RecentEntriesCardView: View {
    let entries: [FoodEntry]
    let onDelete: (FoodEntry) -> Void

    private var groupedEntries: [(String, [FoodEntry])] {
        let mealOrder = ["breakfast", "lunch", "dinner", "snack"]
        let grouped = Dictionary(grouping: entries, by: \.mealType)
        return mealOrder.compactMap { meal in
            guard let items = grouped[meal], !items.isEmpty else { return nil }
            return (meal, items)
        }
    }

    var body: some View {
        if entries.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No entries yet")
                    .font(.subheadline.weight(.semibold))
                Text("Tap + to log your first meal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(spacing: 12) {
                ForEach(groupedEntries, id: \.0) { mealType, items in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(mealType.capitalized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.name)
                                            .font(.body)
                                        Text("\(entry.servings, specifier: "%.1f") serving\(entry.servings == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(entry.totalCalories) kcal")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDelete(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                if index < items.count - 1 {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

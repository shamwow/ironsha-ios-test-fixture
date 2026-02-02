import SwiftUI
import SwiftData

// Original name kept as typealias for compatibility
typealias RecentEntriesListView = RecentEntriesCardView

struct RecentEntriesCardView: View {
    let entries: [FoodEntry]
    let onDelete: (FoodEntry) -> Void
    var onEdit: ((FoodEntry) -> Void)?

    private var sortedEntries: [FoodEntry] {
        entries.sorted { $0.loggedAt > $1.loggedAt }
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
            VStack(spacing: 0) {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.headline)
                            Text("\(entry.servings, specifier: "%.1f") serving\(entry.servings == 1 ? "" : "s") · \(entry.loggedAt, format: .dateTime.hour().minute())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        FlowLayout(spacing: 6) {
                            nutrientPill(value: "\(entry.totalCalories)", label: "calories", color: Color.theme)
                            nutrientPill(value: "\(String(format: "%.0f", entry.totalProtein))g", label: "protein", color: .proteinColor)
                            nutrientPill(value: "\(String(format: "%.0f", entry.totalFat))g", label: "fat", color: .fatColor)
                            nutrientPill(value: "\(String(format: "%.0f", entry.totalCarbs))g", label: "carbs", color: .carbsColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEdit?(entry)
                    }
                    .contextMenu {
                        Button {
                            onEdit?(entry)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            withAnimation {
                                onDelete(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if index < sortedEntries.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func nutrientPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.semibold))
            Text(label)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

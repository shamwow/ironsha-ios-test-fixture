import SwiftData
import SwiftUI

/// Original name kept as typealias for compatibility
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
            VStack(spacing: .spacingSmall) {
                Image(systemName: "fork.knife")
                    .font(.iconMedium)
                    .foregroundStyle(.secondary)
                Text("No entries yet")
                    .font(.subheadlineSemibold)
                Text("Tap + to log your first meal.")
                    .font(.captionRegular)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingXlarge)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(spacing: .spacingNone) {

                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: .spacingSmall) {
                        VStack(alignment: .leading, spacing: .spacingXxs) {
                            Text(entry.name)
                                .font(.headline)
                            Text(
                                "\(entry.servings, specifier: "%.1f") serving\(entry.servings == 1 ? "" : "s") · \(entry.loggedAt, format: .dateTime.hour().minute())"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        FlowLayout(spacing: .flowLayoutSpacing) {
                            nutrientPill(value: "\(entry.totalCalories)", label: "calories", color: Color.theme)
                            nutrientPill(
                                value: "\(String(format: "%.0f", entry.totalProtein))g",
                                label: "protein",
                                color: .proteinColor
                            )
                            nutrientPill(
                                value: "\(String(format: "%.0f", entry.totalFat))g",
                                label: "fat",
                                color: .fatColor
                            )
                            nutrientPill(
                                value: "\(String(format: "%.0f", entry.totalCarbs))g",
                                label: "carbs",
                                color: .carbsColor
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .paddingMedium)
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
                            .padding(.leading, .paddingMedium)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func nutrientPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: .pillSpacing) {
            Text(value)
                .font(.captionSemibold)
            Text(label)
                .font(.caption2Medium)
        }
        .foregroundStyle(Color.cardBackground)
        .padding(.horizontal, .paddingXs)
        .padding(.vertical, .pillPadding)
        .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}

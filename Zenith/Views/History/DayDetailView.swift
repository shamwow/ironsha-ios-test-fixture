import SwiftData
import SwiftUI

struct DayDetailView: View {
    let date: Date
    let entries: [FoodEntry]
    let calorieGoal: Int

    private var totalCalories: Int {
        entries.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalProtein: Double {
        entries.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalFat: Double {
        entries.reduce(0) { $0 + $1.totalFat }
    }

    private var totalCarbs: Double {
        entries.reduce(0) { $0 + $1.totalCarbs }
    }

    private var sortedEntries: [FoodEntry] {
        entries.sorted { $0.loggedAt > $1.loggedAt }
    }

    var body: some View {
        List {
            Section {
                CalorieRingView(consumed: totalCalories, goal: calorieGoal)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                MacroSummaryView(protein: totalProtein, fat: totalFat, carbs: totalCarbs)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(sortedEntries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                            Text(
                                "\(entry.servings, specifier: "%.1f") serving\(entry.servings == 1 ? "" : "s") · \(entry.loggedAt, format: .dateTime.hour().minute())"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(entry.totalCalories) kcal")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(date.shortFormatted)
    }
}

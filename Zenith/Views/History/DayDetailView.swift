import SwiftUI
import SwiftData

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

            let grouped = Dictionary(grouping: entries, by: \.mealType)
            let mealOrder = ["breakfast", "lunch", "dinner", "snack"]

            ForEach(mealOrder, id: \.self) { meal in
                if let items = grouped[meal], !items.isEmpty {
                    Section(meal.capitalized) {
                        ForEach(items, id: \.id) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                    Text("\(entry.servings, specifier: "%.1f") serving\(entry.servings == 1 ? "" : "s")")
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
            }
        }
        .navigationTitle(date.shortFormatted)
    }
}

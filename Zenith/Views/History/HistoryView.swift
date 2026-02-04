import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \FoodEntry.loggedAt, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var settings: [UserSettings]

    private var calorieGoal: Int {
        settings.first?.dailyCalorieGoal ?? 2000
    }

    private var groupedByDay: [(Date, [FoodEntry])] {
        let grouped = Dictionary(grouping: allEntries) { entry in
            entry.loggedAt.startOfDay
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedByDay, id: \.0) { date, entries in
                NavigationLink {
                    DayDetailView(date: date, entries: entries, calorieGoal: calorieGoal)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(date.isToday ? "Today" : date.shortFormatted)
                                .font(.bodyMedium)
                            Text(date.weekdayName)
                                .font(.captionRegular)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        let total = entries.reduce(0) { $0 + $1.totalCalories }
                        let progress = min(Double(total) / Double(calorieGoal), 1.0)
                        let isOver = total > calorieGoal

                        HStack(spacing: 12) {
                            Text("\(total) kcal")
                                .font(.subheadlineMonospaced)
                                .foregroundStyle(.secondary)

                            ZStack {
                                Circle()
                                    .stroke(
                                        isOver ? Color.ringOver.opacity(0.2) : Color.ringUnder.opacity(0.2),
                                        lineWidth: 4
                                    )
                                    .frame(width: 30, height: 30)

                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        isOver ? Color.ringOver : Color.ringUnder,
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                    )
                                    .frame(width: 30, height: 30)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if allEntries.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "calendar",
                    description: Text("Your logged meals will appear here.")
                )
            }
        }
    }
}

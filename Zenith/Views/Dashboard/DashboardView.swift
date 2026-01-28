import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \FoodEntry.loggedAt, order: .reverse)
    private var allEntries: [FoodEntry]
    @State private var selectedDate: Date = .now
    @State private var showDatePicker = false
    @State private var pickerDate: Date = .now
    @State private var slideOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var showCalorieInHeader = false

    private var selectedEntries: [FoodEntry] {
        let start = selectedDate.startOfDay
        let end = selectedDate.endOfDay
        return allEntries.filter { $0.loggedAt >= start && $0.loggedAt <= end }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var calorieGoal: Int {
        settings.first?.dailyCalorieGoal ?? 2000
    }

    private var totalCalories: Int {
        selectedEntries.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalProtein: Double {
        selectedEntries.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalFat: Double {
        selectedEntries.reduce(0) { $0 + $1.totalFat }
    }

    private var totalCarbs: Double {
        selectedEntries.reduce(0) { $0 + $1.totalCarbs }
    }

    private var remaining: Int {
        calorieGoal - totalCalories
    }

    private var headerTitle: String {
        if showCalorieInHeader {
            let r = remaining
            return r >= 0 ? "\(r) remaining" : "\(abs(r)) over"
        }
        return isToday ? "Today" : selectedDate.weekdayName
    }

    private let slideOut: Animation = .easeIn(duration: 0.18)
    private let slideIn: Animation = .spring(response: 0.35, dampingFraction: 0.86)

    private func goBack() {
        isAnimating = true
        withAnimation(slideOut) {
            slideOffset = 300
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
            slideOffset = -300
            withAnimation(slideIn) {
                slideOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = false
            }
        }
    }

    private func goForward() {
        isAnimating = true
        withAnimation(slideOut) {
            slideOffset = -300
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
            slideOffset = 300
            withAnimation(slideIn) {
                slideOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = false
            }
        }
    }

    private func applyPickerDate(_ newDate: Date) {
        let oldDay = selectedDate.startOfDay
        let newDay = newDate.startOfDay
        guard oldDay != newDay else { return }

        let direction: CGFloat = newDay > oldDay ? -300 : 300
        withAnimation(slideOut) {
            slideOffset = direction
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            selectedDate = newDate
            slideOffset = -direction
            withAnimation(slideIn) {
                slideOffset = 0
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            HStack {
                ZStack(alignment: .leading) {
                    if !showCalorieInHeader {
                        Text(isToday ? "Today" : selectedDate.weekdayName)
                            .font(.title.bold())
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0, anchor: .top).combined(with: .opacity),
                                removal: .scale(scale: 0, anchor: .bottom).combined(with: .opacity)
                            ))
                    }

                    if showCalorieInHeader {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(totalCalories)")
                                .font(.title.bold())
                            Text("/ \(calorieGoal) kcal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0, anchor: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0, anchor: .top).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showCalorieInHeader)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .disabled(isAnimating)

                    Button {
                        pickerDate = selectedDate
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text(selectedDate.dayAndMonth)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize()

                    Button {
                        goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .disabled(isToday || isAnimating)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))
            .offset(x: slideOffset)

            // Scrollable content
            ScrollView {
                VStack(spacing: 16) {
                    CalorieRingView(consumed: totalCalories, goal: calorieGoal)
                        .padding(.horizontal, 16)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: CalorieRingVisibilityKey.self,
                                    value: geo.frame(in: .named("dashScroll")).maxY
                                )
                            }
                        )

                    VStack(spacing: 8) {
                        Text("Macros")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        MacroSummaryView(protein: totalProtein, fat: totalFat, carbs: totalCarbs)
                    }
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    RecentEntriesCardView(entries: selectedEntries) { entry in
                        modelContext.delete(entry)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "dashScroll")
            .onPreferenceChange(CalorieRingVisibilityKey.self) { maxY in
                let shouldShow = maxY < 0
                if shouldShow != showCalorieInHeader {
                    showCalorieInHeader = shouldShow
                }
            }
            .offset(x: slideOffset)
        }
        .clipped()
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showDatePicker, onDismiss: {
            applyPickerDate(pickerDate)
        }) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $pickerDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .navigationTitle("Go to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            pickerDate = .now
                            showDatePicker = false
                        } label: {
                            Text("Today")
                        }
                        .disabled(Calendar.current.isDateInToday(pickerDate))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showDatePicker = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .tint(Color.theme)
            .presentationDetents([.medium])
        }
    }
}

private struct CalorieRingVisibilityKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


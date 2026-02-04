import SwiftData
import SwiftUI

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
    @State private var editingEntry: FoodEntry?

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
        ZStack(alignment: .top) {
            // Scrollable content
            ScrollView {
                VStack(spacing: .spacingLarge) {
                    CalorieRingView(consumed: totalCalories, goal: calorieGoal)
                        .padding(.horizontal, .paddingMedium)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        let maxY = geo.frame(in: .global).maxY
                                        let shouldShow = maxY < 175
                                        if shouldShow != showCalorieInHeader { showCalorieInHeader = shouldShow }
                                    }
                                    .onChange(of: geo.frame(in: .global).maxY) { _, newValue in
                                        let shouldShow = newValue < 175
                                        if shouldShow != showCalorieInHeader { showCalorieInHeader = shouldShow }
                                    }
                            }
                        )

                    VStack(spacing: .spacingSmall) {
                        Text("Macros")
                            .font(.subheadlineSemibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        MacroSummaryView(
                            protein: totalProtein,
                            fat: totalFat,
                            carbs: totalCarbs,
                            proteinGoal: settings.first?.dailyProteinGoal ?? 150,
                            fatGoal: settings.first?.dailyFatGoal ?? 65,
                            carbsGoal: settings.first?.dailyCarbsGoal ?? 250
                        )
                    }
                    .padding(.paddingMedium)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, .paddingMedium)

                    RecentEntriesCardView(entries: selectedEntries, onDelete: { entry in
                        modelContext.delete(entry)
                        try? modelContext.save()
                    }, onEdit: { entry in
                        editingEntry = entry
                    })
                    .padding(.horizontal, .paddingMedium)
                }
                .padding(.top, 74)
                .padding(.bottom, 100)
            }
            .offset(x: slideOffset)

            // Fixed header overlay
            HStack {
                ZStack(alignment: .leading) {
                    if !showCalorieInHeader {
                        Text(isToday ? "Today" : selectedDate.weekdayName)
                            .font(.pageTitle)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0, anchor: .top).combined(with: .opacity),
                                removal: .scale(scale: 0, anchor: .bottom).combined(with: .opacity)
                            ))
                    }

                    if showCalorieInHeader {
                        HStack(alignment: .firstTextBaseline, spacing: .spacingXxs) {
                            Text("\(totalCalories)")
                                .font(.pageTitle)
                            Text("/ \(calorieGoal) kcal")
                                .font(.subheadlineRegular)
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

                HStack(spacing: .spacingSmall) {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.iconChevron)
                    }
                    .disabled(isAnimating)

                    Button {
                        pickerDate = selectedDate
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.iconSmall)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text(selectedDate.dayAndMonth)
                        .font(.subheadlineRegular)
                        .foregroundStyle(.secondary)
                        .fixedSize()

                    Button {
                        goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.iconChevron)
                    }
                    .disabled(isToday || isAnimating)
                }
            }
            .padding(.horizontal, .paddingXlarge)
            .padding(.vertical, 10)
            .offset(x: slideOffset)
            .background(.ultraThinMaterial)
        }
        .background(Color.surfaceBackground)
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
                                .font(.iconToolbar)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .tint(Color.theme)
            .presentationDetents([.medium])
        }
        .sheet(item: $editingEntry) { entry in
            AddEntryView(editingEntry: entry)
                .tint(Color.theme)
                .interactiveDismissDisabled()
        }
    }
}

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
    @State private var headerHeight: CGFloat = 0

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

    private let slideOut: Animation = .easeIn(duration: 0.18)
    private let slideIn: Animation = .spring(response: 0.35, dampingFraction: 0.86)

    // MARK: - Date Navigation

    private func selectDate(_ newDate: Date) {
        let oldDay = selectedDate.startOfDay
        let newDay = newDate.startOfDay
        guard oldDay != newDay else { return }
        guard !isAnimating else { return }

        isAnimating = true
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = false
            }
        }
    }

    // MARK: - Body

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
                .padding(.top, headerHeight)
                .padding(.bottom, 100)
            }
            .offset(x: slideOffset)

            // Fixed header overlay
            VStack(spacing: .spacingSmall) {
                ZStack(alignment: .leading) {
                    if !showCalorieInHeader {
                        Text(isToday ? "Today" : selectedDate.weekdayName)
                            .font(.titleBold)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0, anchor: .top).combined(with: .opacity),
                                removal: .scale(scale: 0, anchor: .bottom).combined(with: .opacity)
                            ))
                    }

                    if showCalorieInHeader {
                        HStack(alignment: .firstTextBaseline, spacing: .spacingXxs) {
                            Text("\(totalCalories)")
                                .font(.titleBold)
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
                .frame(maxWidth: .infinity, alignment: .leading)

                WeekStripView(
                    selectedDate: selectedDate,
                    entries: allEntries,
                    calorieGoal: calorieGoal,
                    isAnimating: isAnimating,
                    onDateSelected: { day in selectDate(day) },
                    onLongPress: {
                        pickerDate = selectedDate
                        showDatePicker = true
                    }
                )
            }
            .padding(.horizontal, .paddingMedium)
            .padding(.vertical, .paddingSmall)
            .background(.ultraThinMaterial)
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { headerHeight = geo.size.height }
                        .onChange(of: geo.size.height) { _, newValue in headerHeight = newValue }
                }
            )
        }
        .background(Color.surfaceBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showDatePicker, onDismiss: {
            selectDate(pickerDate)
        }) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $pickerDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                    Spacer()
                }
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
                        .accessibilityIdentifier("datePickerToday")
                        .accessibilityLabel("Today")
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
                        .accessibilityIdentifier("datePickerClose")
                        .accessibilityLabel("Close")
                    }
                }
            }
            .tint(Color.theme)
            .presentationDetents([.height(460)])
        }
        .sheet(item: $editingEntry) { entry in
            AddEntryView(editingEntry: entry)
                .tint(Color.theme)
                .interactiveDismissDisabled()
        }
    }
}

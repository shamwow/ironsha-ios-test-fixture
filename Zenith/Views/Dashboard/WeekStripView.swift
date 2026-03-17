import SwiftData
import SwiftUI

struct WeekStripView: View {
    let selectedDate: Date
    let entries: [FoodEntry]
    let calorieGoal: Int
    let isAnimating: Bool
    let onDateSelected: (Date) -> Void
    let onLongPress: () -> Void

    @State private var displayedWeekStart: Date = Date.now.startOfWeek
    @State private var visualSelection: Date = .now
    @State private var dragOffset: CGFloat = 0
    @State private var pageWidth: CGFloat = 0

    private let circleSize: CGFloat = 36
    private let stripHeight: CGFloat = 66
    private let calendar = Calendar.current
    private let swipeThreshold: CGFloat = 50

    // MARK: - Week Data

    private var previousWeekDays: [Date] {
        guard let start = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeekStart) else { return [] }
        return (0 ..< 7).map { calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    private var currentWeekDays: [Date] {
        (0 ..< 7).map { calendar.date(byAdding: .day, value: $0, to: displayedWeekStart)! }
    }

    private var nextWeekDays: [Date] {
        guard let start = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeekStart) else { return [] }
        return (0 ..< 7).map { calendar.date(byAdding: .day, value: $0, to: start)! }
    }

    private var canGoForward: Bool {
        displayedWeekStart < Date.now.startOfWeek
    }

    // MARK: - Swipe Navigation

    private func completeSwipe(forward: Bool) {
        guard pageWidth > 0 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            dragOffset = forward ? -pageWidth : pageWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                let delta = forward ? 1 : -1
                displayedWeekStart = calendar.date(byAdding: .weekOfYear, value: delta, to: displayedWeekStart)!
                dragOffset = 0
            }
        }
    }

    private func cancelSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            dragOffset = 0
        }
    }

    // MARK: - Day Status

    enum DayStatus {
        case noEntries, underGoal, overGoal, future
    }

    private func statusFor(day: Date) -> DayStatus {
        if day.startOfDay > Date.now.startOfDay { return .future }
        let start = day.startOfDay
        let end = day.endOfDay
        let dayEntries = entries.filter { $0.loggedAt >= start && $0.loggedAt <= end }
        if dayEntries.isEmpty { return .noEntries }
        let total = dayEntries.reduce(0) { $0 + $1.totalCalories }
        return total > calorieGoal ? .overGoal : .underGoal
    }

    private func statusColor(for status: DayStatus) -> Color {
        switch status {
        case .noEntries: return .theme
        case .underGoal: return .theme
        case .overGoal: return .zenithRed
        case .future: return .clear
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            HStack(spacing: 0) {
                weekPage(days: previousWeekDays)
                    .frame(width: width)
                weekPage(days: currentWeekDays)
                    .frame(width: width)
                weekPage(days: nextWeekDays)
                    .frame(width: width)
            }
            .offset(x: -width + dragOffset)
            .onAppear { pageWidth = width }
            .onChange(of: width) { _, newWidth in pageWidth = newWidth }
        }
        .frame(height: stripHeight)
        .clipShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let translation = value.translation.width
                    if !canGoForward, translation < 0 {
                        dragOffset = translation * 0.2
                    } else {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    let predicted = value.predictedEndTranslation.width

                    if predicted < -swipeThreshold, canGoForward {
                        completeSwipe(forward: true)
                    } else if predicted > swipeThreshold {
                        completeSwipe(forward: false)
                    } else {
                        cancelSwipe()
                    }
                }
        )
        .onAppear {
            displayedWeekStart = selectedDate.startOfWeek
            visualSelection = selectedDate
        }
        .onChange(of: selectedDate) { _, newValue in
            visualSelection = newValue
            let newWeek = newValue.startOfWeek
            if newWeek != displayedWeekStart {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    displayedWeekStart = newWeek
                    dragOffset = 0
                }
            }
        }
    }

    // MARK: - Week Page

    private func weekPage(days: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let isFuture = day.startOfDay > Date.now.startOfDay

                dayColumn(for: day)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("day_\(day.dayNumber)")
                    .onTapGesture {
                        guard !isFuture, !isAnimating else { return }
                        visualSelection = day
                        onDateSelected(day)
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        onLongPress()
                    }
            }
        }
    }

    // MARK: - Day Column

    @ViewBuilder
    private func dayColumn(for day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: visualSelection)
        let isDayToday = calendar.isDateInToday(day)
        let status = statusFor(day: day)
        let isFuture = status == .future

        VStack(spacing: .spacingXxs) {
            Text(day.shortWeekdayInitial)
                .font(.caption2Medium)
                .foregroundStyle(isFuture ? Color.secondary.opacity(0.3) : .secondary)

            ZStack {
                circleIndicator(for: status)

                Text("\(day.dayNumber)")
                    .font(.captionSemibold)
                    .foregroundStyle(
                        isFuture ? Color.secondary.opacity(0.3) : Color.primary
                    )
            }
            .frame(width: circleSize, height: circleSize)
        }
        .padding(.vertical, .paddingXs)
        .padding(.horizontal, .paddingXxs)
        .background(
            isSelected
                ? Color.theme.opacity(0.18)
                : isDayToday ? Color.secondary.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    // MARK: - Circle Indicator

    @ViewBuilder
    private func circleIndicator(for status: DayStatus) -> some View {
        switch status {
        case .noEntries:
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .foregroundStyle(Color.secondary.opacity(0.4))
        case .underGoal:
            Circle()
                .strokeBorder(Color.theme, lineWidth: 2)
        case .overGoal:
            Circle()
                .strokeBorder(Color.zenithRed, lineWidth: 2)
        case .future:
            Color.clear
        }
    }
}

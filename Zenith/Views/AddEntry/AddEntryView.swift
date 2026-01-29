import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodEntry.loggedAt, order: .reverse) private var allEntries: [FoodEntry]

    @State private var name: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var fatText: String
    @State private var carbsText: String

    private var editingEntry: FoodEntry?

    private var isEditing: Bool { editingEntry != nil }

    init(prefillCandidate: FoodCandidate? = nil, editingEntry: FoodEntry? = nil) {
        self.editingEntry = editingEntry
        if let entry = editingEntry {
            _name = State(initialValue: entry.name)
            _caloriesText = State(initialValue: "\(entry.calories)")
            _proteinText = State(initialValue: entry.proteinGrams > 0 ? "\(entry.proteinGrams)" : "")
            _fatText = State(initialValue: entry.fatGrams > 0 ? "\(entry.fatGrams)" : "")
            _carbsText = State(initialValue: entry.carbsGrams > 0 ? "\(entry.carbsGrams)" : "")
            _servings = State(initialValue: entry.servings)
            _mealType = State(initialValue: entry.mealType)
        } else if let c = prefillCandidate {
            _name = State(initialValue: c.name)
            _caloriesText = State(initialValue: "\(c.calories)")
            _proteinText = State(initialValue: c.proteinGrams > 0 ? "\(c.proteinGrams)" : "")
            _fatText = State(initialValue: c.fatGrams > 0 ? "\(c.fatGrams)" : "")
            _carbsText = State(initialValue: c.carbsGrams > 0 ? "\(c.carbsGrams)" : "")
            _servings = State(initialValue: 1.0)
            _mealType = State(initialValue: "breakfast")
        } else {
            _name = State(initialValue: "")
            _caloriesText = State(initialValue: "")
            _proteinText = State(initialValue: "")
            _fatText = State(initialValue: "")
            _carbsText = State(initialValue: "")
            _servings = State(initialValue: 1.0)
            _mealType = State(initialValue: "breakfast")
        }
    }
    @State private var servings: Double
    @State private var mealType: String
    @State private var showAutoComplete = false
    @State private var showNameError = false
    @State private var showCaloriesError = false
    @State private var showHeaderTitle = false
    @FocusState private var nameFieldFocused: Bool

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

    private var calories: Int {
        Int(caloriesText) ?? 0
    }

    private var protein: Double {
        Double(proteinText) ?? 0
    }

    private var fat: Double {
        Double(fatText) ?? 0
    }

    private var carbs: Double {
        Double(carbsText) ?? 0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && calories > 0
    }

    private var filteredEntries: [FoodEntry] {
        guard !name.isEmpty else { return [] }
        let query = name.lowercased()
        // Get unique entries by name, keeping only the most recent (already sorted by loggedAt desc)
        var seen = Set<String>()
        return allEntries.filter { entry in
            let lowerName = entry.name.lowercased()
            guard lowerName.contains(query) else { return false }
            guard !seen.contains(lowerName) else { return false }
            seen.insert(lowerName)
            return true
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // Large title in content
                    Text(isEditing ? "Edit Entry" : "Add Entry")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.theme)
                        .opacity(showHeaderTitle ? 0 : 1)
                        .padding(.leading, 16)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        let maxY = geo.frame(in: .global).maxY
                                        let shouldShow = maxY < 100
                                        if shouldShow != showHeaderTitle { showHeaderTitle = shouldShow }
                                    }
                                    .onChange(of: geo.frame(in: .global).maxY) { _, newValue in
                                        let shouldShow = newValue < 100
                                        if shouldShow != showHeaderTitle { showHeaderTitle = shouldShow }
                                    }
                            }
                        )

                    // Name field
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Name", required: false)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Enter food name", text: $name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .focused($nameFieldFocused)
                            .onChange(of: name) { _, newValue in
                                if showNameError && !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    showNameError = false
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAutoComplete = !newValue.isEmpty && !filteredEntries.isEmpty
                                }
                            }
                            .background(.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(showNameError ? Color.error : Color.clear, lineWidth: 2)
                            )

                        if showNameError {
                            Text("required")
                                .font(.caption)
                                .foregroundStyle(Color.error)
                                .padding(.leading, 4)
                        }
                    }
                        .overlay(alignment: .top) {
                            if showAutoComplete && nameFieldFocused {
                                VStack(spacing: 0) {
                                    ForEach(filteredEntries.prefix(5)) { entry in
                                        Button {
                                            selectFromEntry(entry)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(entry.name)
                                                        .foregroundStyle(.primary)
                                                    Text("\(entry.calories) kcal")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.up.left")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if entry.id != filteredEntries.prefix(5).last?.id {
                                            Divider()
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                                .offset(y: 52)
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                            }
                        }
                        .zIndex(100)

                }
                .zIndex(100)

                // Nutrition (Calories + Macros)
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Nutrition", required: false)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calories")
                                    .foregroundStyle(showCaloriesError ? Color.error : .primary)
                                if showCaloriesError {
                                    Text("required")
                                        .font(.caption)
                                        .foregroundStyle(Color.error)
                                }
                            }
                            Spacer()
                            TextField("0", text: $caloriesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .onChange(of: caloriesText) { _, newValue in
                                    if showCaloriesError && (Int(newValue) ?? 0) > 0 {
                                        showCaloriesError = false
                                    }
                                }
                            Text("kcal")
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(
                            showCaloriesError
                                ? Color.error.opacity(0.1)
                                : Color.clear,
                            in: UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 10)
                        )

                        Divider().padding(.leading, 12)
                        macroRow(label: "Protein", text: $proteinText)
                        Divider().padding(.leading, 12)
                        macroRow(label: "Fat", text: $fatText)
                        Divider().padding(.leading, 12)
                        macroRow(label: "Carbs", text: $carbsText)
                    }
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(showCaloriesError ? Color.error : Color.clear, lineWidth: 2)
                    )
                }

                // Servings
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Servings", required: false)

                    HStack {
                        Text("\(servings, specifier: "%.1f")")
                            .font(.body.monospacedDigit())
                        Spacer()
                        Stepper("", value: $servings, in: 0.5...20, step: 0.5)
                            .labelsHidden()
                    }
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }

                // Meal type selector
                HStack(spacing: 12) {
                    ForEach(mealTypes, id: \.self) { type in
                        MealTypeButton(
                            type: type,
                            isSelected: mealType == type
                        ) {
                            mealType = type
                        }
                    }
                }

                if isEditing {
                    Button(role: .destructive) {
                        deleteEntry()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Entry")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .padding(.top, 44)
            .padding(.bottom, 80)
            .contentShape(Rectangle())
            .onTapGesture {
                if showAutoComplete || nameFieldFocused {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAutoComplete = false
                        nameFieldFocused = false
                    }
                }
            }
        }
            // Floating header overlay
            ZStack {
                if showHeaderTitle {
                    Text(isEditing ? "Edit Entry" : "Add Entry")
                        .font(.headline)
                        .foregroundStyle(Color.theme)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showHeaderTitle)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color(.systemGroupedBackground), location: 0),
                        .init(color: Color(.systemGroupedBackground), location: 0.6),
                        .init(color: Color(.systemGroupedBackground).opacity(0), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                // Log Entry button
                Button {
                    if isValid {
                        saveEntry()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                                showNameError = true
                            }
                            if calories <= 0 {
                                showCaloriesError = true
                            }
                        }
                    }
                } label: {
                    Text(isEditing ? "Save Changes" : "Log Entry")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.theme : Color.gray, in: Capsule())
                        .shadow(color: isValid ? Color.theme.opacity(0.4) : Color.clear, radius: 8, y: 4)
                }

            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func sectionHeader(_ title: String, required: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if required {
                Text("(required)")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .padding(.leading, 16)
    }

    private func macroRow(label: String, text: Binding<String>, unit: String = "g") -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(unit == "kcal" ? .numberPad : .decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func selectFromEntry(_ entry: FoodEntry) {
        name = entry.name
        caloriesText = "\(entry.calories)"
        proteinText = entry.proteinGrams > 0 ? "\(entry.proteinGrams)" : ""
        fatText = entry.fatGrams > 0 ? "\(entry.fatGrams)" : ""
        carbsText = entry.carbsGrams > 0 ? "\(entry.carbsGrams)" : ""
        showAutoComplete = false
        nameFieldFocused = false
    }

    private func deleteEntry() {
        if let entry = editingEntry {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        dismiss()
    }

    private func saveEntry() {
        if let entry = editingEntry {
            entry.name = name.trimmingCharacters(in: .whitespaces)
            entry.calories = calories
            entry.proteinGrams = protein
            entry.fatGrams = fat
            entry.carbsGrams = carbs
            entry.servings = servings
            entry.mealType = mealType
        } else {
            let entry = FoodEntry(
                name: name.trimmingCharacters(in: .whitespaces),
                calories: calories,
                proteinGrams: protein,
                fatGrams: fat,
                carbsGrams: carbs,
                servings: servings,
                mealType: mealType
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}

private struct MealTypeButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch type {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        case "snack": return "carrot.fill"
        default: return "fork.knife"
        }
    }

    private var label: String {
        type.capitalized
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(height: 28)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.theme : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? Color.theme : .primary)
        }
        .buttonStyle(.plain)
    }
}


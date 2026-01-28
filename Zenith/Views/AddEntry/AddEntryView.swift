import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodItem.name) private var savedFoods: [FoodItem]

    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var servings: Double = 1.0
    @State private var mealType = "breakfast"
    @State private var saveAsFood = true
    @State private var selectedFoodItem: FoodItem?
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

    private var filteredFoods: [FoodItem] {
        guard !name.isEmpty else { return [] }
        let query = name.lowercased()
        return savedFoods.filter { $0.name.lowercased().contains(query) }
    }

    private var isUsingExistingFood: Bool {
        if selectedFoodItem != nil { return true }
        let trimmedName = name.trimmingCharacters(in: .whitespaces).lowercased()
        return savedFoods.contains { $0.name.lowercased() == trimmedName }
    }

    var body: some View {
        ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // Large title in content
                    Text("Add Entry")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.theme)
                        .opacity(showHeaderTitle ? 0 : 1)
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
                                if let selected = selectedFoodItem, selected.name != newValue {
                                    selectedFoodItem = nil
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAutoComplete = !newValue.isEmpty && !filteredFoods.isEmpty && selectedFoodItem == nil
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
                                    ForEach(filteredFoods.prefix(5)) { food in
                                        Button {
                                            selectFood(food)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(food.name)
                                                        .foregroundStyle(.primary)
                                                    Text("\(food.calories) kcal")
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

                                        if food.id != filteredFoods.prefix(5).last?.id {
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
                    Text("Add Entry")
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
                    Text("Log Entry")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.theme : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: isValid ? Color.theme.opacity(0.4) : Color.clear, radius: 8, y: 4)
                }

                // Save Item button - only show when creating a new food item
                if !isUsingExistingFood && !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        saveAsFood.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .semibold))

                                Image(systemName: saveAsFood ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .background(Circle().fill(.white).padding(-1))
                                    .offset(x: 4, y: 2)
                            }
                            Text("Save Item")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(saveAsFood ? Color.theme : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(saveAsFood ? Color.theme : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isUsingExistingFood)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: name.isEmpty)
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

    private func selectFood(_ food: FoodItem) {
        selectedFoodItem = food
        name = food.name
        caloriesText = "\(food.calories)"
        proteinText = food.proteinGrams > 0 ? "\(food.proteinGrams)" : ""
        fatText = food.fatGrams > 0 ? "\(food.fatGrams)" : ""
        carbsText = food.carbsGrams > 0 ? "\(food.carbsGrams)" : ""
        showAutoComplete = false
        nameFieldFocused = false
    }

    private func saveEntry() {
        if saveAsFood && !isUsingExistingFood {
            let foodItem = FoodItem(
                name: name.trimmingCharacters(in: .whitespaces),
                calories: calories,
                proteinGrams: protein,
                fatGrams: fat,
                carbsGrams: carbs
            )
            modelContext.insert(foodItem)
        }

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
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.theme : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? Color.theme : .primary)
        }
        .buttonStyle(.plain)
    }
}


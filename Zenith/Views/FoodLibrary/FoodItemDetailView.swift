import SwiftUI
import SwiftData

struct FoodItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var foodItem: FoodItem?

    @State private var name = ""
    @State private var calories: Int = 0
    @State private var protein: Double = 0
    @State private var fat: Double = 0
    @State private var carbs: Double = 0

    private var isEditing: Bool { foodItem != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && calories > 0
    }

    var body: some View {
        Form {
            NutritionFormFields(
                name: $name,
                calories: $calories,
                protein: $protein,
                fat: $fat,
                carbs: $carbs
            )

            Section {
                Button(isEditing ? "Save Changes" : "Create Food") {
                    save()
                }
                .disabled(!isValid)
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
            }
        }
        .navigationTitle(isEditing ? "Edit Food" : "New Food")
        .onAppear {
            if let item = foodItem {
                name = item.name
                calories = item.calories
                protein = item.proteinGrams
                fat = item.fatGrams
                carbs = item.carbsGrams
            }
        }
    }

    private func save() {
        if let item = foodItem {
            item.name = name.trimmingCharacters(in: .whitespaces)
            item.calories = calories
            item.proteinGrams = protein
            item.fatGrams = fat
            item.carbsGrams = carbs
        } else {
            let item = FoodItem(
                name: name.trimmingCharacters(in: .whitespaces),
                calories: calories,
                proteinGrams: protein,
                fatGrams: fat,
                carbsGrams: carbs
            )
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }
}

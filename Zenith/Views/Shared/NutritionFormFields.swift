import SwiftUI

struct NutritionFormFields: View {
    @Binding var name: String
    @Binding var calories: Int
    @Binding var protein: Double
    @Binding var fat: Double
    @Binding var carbs: Double

    var body: some View {
        Section("Food Info") {
            TextField("Name", text: $name)

            HStack {
                Text("Calories")
                Spacer()
                TextField("kcal", value: $calories, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }

        Section("Macros (per serving)") {
            macroRow("Protein (g)", value: $protein)
            macroRow("Fat (g)", value: $fat)
            macroRow("Carbs (g)", value: $carbs)
        }
    }

    private func macroRow(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}

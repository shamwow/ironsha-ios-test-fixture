import SwiftUI

struct MacroSummaryView: View {
    let protein: Double
    let fat: Double
    let carbs: Double
    var proteinGoal: Double = 150
    var fatGoal: Double = 65
    var carbsGoal: Double = 250

    var body: some View {
        HStack(spacing: CGFloat.spacingXxlarge) {
            MacroRing(label: "Protein", value: protein, color: .proteinColor, goal: proteinGoal)
            MacroRing(label: "Fat", value: fat, color: .fatColor, goal: fatGoal)
            MacroRing(label: "Carbs", value: carbs, color: .carbsColor, goal: carbsGoal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CGFloat.paddingXs)
    }
}

private struct MacroRing: View {
    let label: String
    let value: Double
    let color: Color
    let goal: Double

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    var body: some View {
        VStack(spacing: CGFloat.flowLayoutSpacing) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: fraction)

                Text("\(Int(value))g")
                    .font(.macroValue)
            }
            .frame(width: CGFloat.macroRingSize, height: CGFloat.macroRingSize)

            Text(label)
                .font(.captionRegular)
                .foregroundStyle(.secondary)
        }
    }
}

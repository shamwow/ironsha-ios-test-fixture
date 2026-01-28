import SwiftUI

struct MacroSummaryView: View {
    let protein: Double
    let fat: Double
    let carbs: Double

    private var total: Double {
        protein + fat + carbs
    }

    var body: some View {
        HStack(spacing: 36) {
            MacroRing(label: "Protein", value: protein, color: .proteinColor, total: total)
            MacroRing(label: "Fat", value: fat, color: .fatColor, total: total)
            MacroRing(label: "Carbs", value: carbs, color: .carbsColor, total: total)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct MacroRing: View {
    let label: String
    let value: Double
    let color: Color
    let total: Double

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: fraction)

                Text("\(Int(value))g")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .frame(width: 64, height: 64)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

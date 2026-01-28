import SwiftUI

struct MacroLabel: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    init(_ name: String, value: Double, unit: String = "g", color: Color) {
        self.name = name
        self.value = value
        self.unit = unit
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(name): \(value, specifier: "%.1f")\(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1), in: Capsule())
    }
}

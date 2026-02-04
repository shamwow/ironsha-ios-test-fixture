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
        HStack(spacing: .spacingXs) {
            Circle()
                .fill(color)
                .frame(width: .dotIndicatorSize, height: .dotIndicatorSize)

            Text("\(name): \(value, specifier: "%.1f")\(unit)")
                .font(.captionRegular)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .paddingXs)
        .padding(.vertical, .paddingXxs)
        .background(color.opacity(0.1), in: Capsule())
    }
}

import SwiftUI

struct CalorieRingView: View {
    let consumed: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    private var remaining: Int {
        max(goal - consumed, 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eaten")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(consumed)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("kcal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.themeDark)

                    Text("\(remaining)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.themeDark)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeDark)

                    Capsule()
                        .fill(.white)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 14)
        }
        .padding(20)
        .background(Color.theme, in: RoundedRectangle(cornerRadius: 16))
    }
}

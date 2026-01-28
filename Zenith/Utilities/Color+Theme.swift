import SwiftUI

extension Color {
    static let theme = Color(red: 0.251, green: 0.267, blue: 0.576)
    static let themeDark = Color(red: 0.12, green: 0.13, blue: 0.30)
    static let themeBackground = Color.theme.opacity(0.08)

    static let zenithRed = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let error = Color(red: 0.753, green: 0.224, blue: 0.169)

    static let proteinColor = Color.theme
    static let fatColor = Color.theme.opacity(0.6)
    static let carbsColor = Color.theme.opacity(0.35)

    static let ringUnder = Color.theme
    static let ringOver = Color.zenithRed
}

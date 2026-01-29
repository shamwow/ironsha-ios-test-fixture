import SwiftUI

extension Color {
    static let theme = Color(red: 0.251, green: 0.267, blue: 0.576)
    static let themeDark = Color(red: 0.12, green: 0.13, blue: 0.30)
    static let themeBackground = Color.theme.opacity(0.08)

    static let zenithRed = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let error = Color(red: 0.753, green: 0.224, blue: 0.169)

    static let proteinColor = Color(red: 0.161, green: 0.502, blue: 0.725)  // #2980b9
    static let fatColor = Color(red: 0.953, green: 0.612, blue: 0.071)      // #f39c12
    static let carbsColor = Color(red: 0.753, green: 0.224, blue: 0.169)    // #c0392b

    static let ringUnder = Color.theme
    static let ringOver = Color.zenithRed
}

import SwiftUI

extension Font {
    // MARK: - Page Titles

    static let pageTitle = Font.system(size: 34, weight: .bold)

    // MARK: - Display Numbers

    static let calorieDisplay = Font.system(size: 28, weight: .bold, design: .rounded)
    static let macroValue = Font.system(size: 13, weight: .semibold, design: .rounded)

    // MARK: - Text Styles

    static let titleBold = Font.title.bold()
    static let headlineRegular = Font.headline
    static let subheadlineSemibold = Font.subheadline.weight(.semibold)
    static let subheadlineMedium = Font.subheadline.weight(.medium)
    static let subheadlineRegular = Font.subheadline
    static let subheadlineMonospaced = Font.subheadline.monospacedDigit()
    static let bodyMedium = Font.body.weight(.medium)
    static let bodyMonospaced = Font.body.monospacedDigit()
    static let captionSemibold = Font.caption.weight(.semibold)
    static let captionRegular = Font.caption
    static let captionMonospaced = Font.caption.monospacedDigit()
    static let caption2Medium = Font.caption2.weight(.medium)

    // MARK: - Icon Sizes

    static let iconLarge = Font.system(size: 60) // Empty state, large icons
    static let iconMedium = Font.system(size: 32) // Empty state icons
    static let iconRegular = Font.system(size: 28) // Close buttons
    static let iconToolbar = Font.system(size: 24, weight: .medium) // Bottom toolbar icons
    static let iconSmall = Font.system(size: 15, weight: .medium) // Calendar, small icons
    static let iconChevron = Font.system(size: 14, weight: .semibold) // Navigation chevrons
}

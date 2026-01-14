import SwiftUI

struct DashboardTheme {
    static let background = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.08, blue: 0.11),
            Color(red: 0.11, green: 0.13, blue: 0.18),
            Color(red: 0.08, green: 0.10, blue: 0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let cardBorder = Color(red: 0.20, green: 0.23, blue: 0.28)
    static let accent = Color(red: 0.18, green: 0.60, blue: 0.75)
    static let textPrimary = Color(red: 0.90, green: 0.93, blue: 0.97)
    static let textSecondary = Color(red: 0.68, green: 0.72, blue: 0.78)
    static let danger = Color(red: 0.86, green: 0.24, blue: 0.22)
    static let warning = Color(red: 0.96, green: 0.70, blue: 0.20)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.45)
}

extension Font {
    static func dashboardTitle(_ size: CGFloat) -> Font {
        .custom("Avenir Next Demi Bold", size: size)
    }

    static func dashboardBody(_ size: CGFloat) -> Font {
        .custom("Avenir Next", size: size)
    }

    static func dashboardMono(_ size: CGFloat) -> Font {
        .custom("Menlo", size: size)
    }
}

import SwiftUI

struct DashboardTheme {
    static let background = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.07, blue: 0.09),
            Color(red: 0.08, green: 0.10, blue: 0.13),
            Color(red: 0.06, green: 0.09, blue: 0.12),
            Color(red: 0.04, green: 0.06, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let cardBorder = Color(red: 0.18, green: 0.21, blue: 0.26)
    static let cardGlow = Color(red: 0.16, green: 0.22, blue: 0.28)
    static let accent = Color(red: 0.10, green: 0.64, blue: 0.70)
    static let accentSoft = Color(red: 0.12, green: 0.40, blue: 0.48)
    static let textPrimary = Color(red: 0.92, green: 0.95, blue: 0.98)
    static let textSecondary = Color(red: 0.62, green: 0.68, blue: 0.74)
    static let danger = Color(red: 0.86, green: 0.24, blue: 0.22)
    static let warning = Color(red: 0.96, green: 0.70, blue: 0.20)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.45)

    static let panelGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.15, blue: 0.19),
            Color(red: 0.09, green: 0.12, blue: 0.16)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

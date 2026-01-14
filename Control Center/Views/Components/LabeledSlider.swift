import SwiftUI

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.dashboardBody(12))
                    .foregroundStyle(DashboardTheme.textSecondary)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.dashboardMono(11))
                    .foregroundStyle(DashboardTheme.textPrimary)
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(DashboardTheme.accent)
        }
    }
}

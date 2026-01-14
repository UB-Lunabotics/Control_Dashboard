import SwiftUI

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.dashboardMono(10))
                    .foregroundStyle(DashboardTheme.textPrimary)
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(DashboardTheme.accent)
                .controlSize(.mini)
        }
    }
}

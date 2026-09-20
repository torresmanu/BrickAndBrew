import SwiftUI

/// Graphic number + unit. The number is the identity; the unit stays small and technical.
struct MetricView: View {
    let value: String
    var unit: String? = nil
    var valueFont: Font = Typography.metric
    var unitFont: Font = Typography.metricUnit
    var valueColor: Color = Palette.text
    var unitColor: Color = Palette.secondaryText
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
            if let unit, unit.isEmpty == false {
                Text(unit)
                    .font(unitFont)
                    .foregroundStyle(unitColor)
                    .tracking(2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(unit.map { "\(value) \($0.lowercased())" } ?? value)
    }
}

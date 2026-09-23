import SwiftUI

/// Level 3 moment: huge type and signal orange on ink, then back to the product.
/// Marketing stills already carry their own lockup, so this screen stays type-only.
struct CelebrationView: View {
    let kicker: String
    let title: String
    let value: String
    let unit: String
    var detail: String? = nil
    let dismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    var body: some View {
        Button(action: dismiss) {
            HStack(alignment: .top, spacing: 0) {
                accentRule
                copy
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Palette.background.ignoresSafeArea())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Dismisses the celebration")
        .onAppear(perform: announce)
    }

    private var accentRule: some View {
        Rectangle()
            .fill(Palette.accent)
            .frame(width: Spacing.xs)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Spacer()
            Text(kicker.uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(2)
            Text(title)
                .font(Typography.displayL)
                .foregroundStyle(Palette.paper)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
            MetricView(
                value: value,
                unit: unit,
                valueFont: Typography.displayXL,
                valueColor: Palette.accent,
                unitColor: Palette.paper
            )
            if let detail {
                Text(detail)
                    .font(Typography.body)
                    .foregroundStyle(Palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("TAP TO CLOSE")
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(2)
                .padding(.top, Spacing.lg)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandAppear(isReducedMotion: reduceMotion, trigger: didAppear)
    }

    private var accessibilityText: String {
        var parts = [kicker, title, "\(value) \(unit.lowercased())"]
        if let detail {
            parts.append(detail)
        }
        return parts.joined(separator: ". ")
    }

    private func announce() {
        didAppear = true
        Haptics.medium()
        Haptics.success()
    }
}

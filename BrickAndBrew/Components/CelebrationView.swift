import SwiftUI

/// Level 3 moment: huge type, orange, optional photography, then back to the product.
/// Product logic stays in the caller; this is presentation only.
struct CelebrationView: View {
    let kicker: String
    let title: String
    let value: String
    let unit: String
    var detail: String? = nil
    var photoName: String? = BrandPhoto.nightCheers
    let dismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    var body: some View {
        Button(action: dismiss) {
            ZStack {
                Palette.background.ignoresSafeArea()
                if let photoName {
                    Image(photoName)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(Palette.ink.opacity(0.55))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Spacer()
                    Text(kicker.uppercased())
                        .font(Typography.metadata)
                        .foregroundStyle(Palette.paper)
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
                        .foregroundStyle(Palette.paper.opacity(0.7))
                        .tracking(2)
                        .padding(.top, Spacing.lg)
                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .brandAppear(isReducedMotion: reduceMotion, trigger: didAppear)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Dismisses the celebration")
        .onAppear(perform: announce)
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

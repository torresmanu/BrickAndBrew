import SwiftUI

/// Editorial section label: small tracked metadata, optional trailing action copy.
struct SectionHeader: View {
    let title: String
    var accessory: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.8)
            Spacer(minLength: Spacing.sm)
            if let accessory {
                Text(accessory.uppercased())
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.secondaryText)
                    .tracking(1.4)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Thin rule used instead of wrapping every block in a card.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

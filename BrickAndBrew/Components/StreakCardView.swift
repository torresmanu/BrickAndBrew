import SwiftUI

/// Personal streak as a metric, not a floating card.
struct StreakCardView: View {
    let kind: StreakKind
    let streak: Streak
    var now: Date = Date()
    var calendar: Calendar = .current

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                kind.icon
                Text(kind.title.uppercased())
            }
            .font(Typography.metadata)
            .foregroundStyle(Palette.secondaryText)
            .symbolRenderingMode(.hierarchical)
            .tracking(1.6)

            MetricView(
                value: "\(streak.current)",
                unit: streak.current == 1 ? "DAY" : "DAYS",
                valueColor: streak.current > 0 ? Palette.text : Palette.secondaryText
            )

            Text(StreakCopy.longestCaption(streak).uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.2)

            Text(StreakCopy.line(kind: kind, streak: streak, now: now, calendar: calendar))
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Hairline()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let current = Formatters.streakDays(streak.current)
        let longest = StreakCopy.longestCaption(streak)
        let line = StreakCopy.line(kind: kind, streak: streak, now: now, calendar: calendar)
        return "\(kind.title), \(current), \(longest). \(line)"
    }
}

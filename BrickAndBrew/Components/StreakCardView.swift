import SwiftUI

/// Personal streak theater card: big current number, longest, one pub-table line.
struct StreakCardView: View {
    let kind: StreakKind
    let streak: Streak
    var now: Date = Date()
    var calendar: Calendar = .current

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(kind.title)
            } icon: {
                kind.icon
            }
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Palette.muted)
            .symbolRenderingMode(.hierarchical)

            Text("\(streak.current)")
                .font(Typography.heading1)
                .foregroundStyle(Palette.cream)
                .monospacedDigit()

            Text(StreakCopy.longestCaption(streak))
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)

            Text(StreakCopy.line(kind: kind, streak: streak, now: now, calendar: calendar))
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
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

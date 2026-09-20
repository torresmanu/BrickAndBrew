import SwiftUI

/// Shared pint / brick / combo mark. Hidden when the streak is cold.
struct StreakBadgeView: View {
    let kind: StreakKind
    let streak: Streak
    var symbolName: String? = nil
    var now: Date = Date()
    var calendar: Calendar = .current

    var body: some View {
        if streak.current > 0 {
            HStack(spacing: Spacing.xxs) {
                icon
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                Text("\(streak.current)")
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(streak.isAtRisk(now: now, calendar: calendar) ? Palette.secondaryText : Palette.accent)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let symbolName {
            Image(systemName: symbolName)
        } else {
            kind.icon
        }
    }

    private var accessibilityText: String {
        let days = Formatters.streakDays(streak.current)
        if streak.isAtRisk(now: now, calendar: calendar) {
            return "\(kind.title) streak \(days), at risk"
        }
        return "\(kind.title) streak \(days)"
    }
}

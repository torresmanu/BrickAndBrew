import Foundation

/// Training-streak lines. Views stay dumb; tone lives here.
enum StreakCopy {
    static let loadingMessage = "Counting training days…"
    static let emptyTitle = "No streak yet"
    static let emptyMessage = "Sync a swim, bike, or run to start a streak."
    static let brickSyncLag = "Brick streaks catch up when Strava syncs."

    static func line(
        kind: StreakKind,
        streak: Streak,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if streak.isAtRisk(now: now, calendar: calendar) {
            return atRiskNudge(kind: kind)
        }
        if streak.current == 0 {
            return emptyLine(kind: kind)
        }
        return currentLine(kind: kind, days: streak.current)
    }

    static func atRiskNudge(kind: StreakKind) -> String {
        switch kind {
        case .pint, .brickAndBrew:
            return ""
        case .brick:
            return "Yesterday's session is waiting for a sequel."
        }
    }

    static func cheerAfterBrick(days: Int) -> String {
        switch days {
        case 1:
            return "Brick is live. Strava showed up; the streak noticed."
        case 2:
            return "Two days of training."
        case 7:
            return "A week of bricks. Keep the easy days easy."
        default:
            return "Brick is \(Formatters.streakDays(days)) deep. Keep stacking."
        }
    }

    static func longestCaption(_ streak: Streak) -> String {
        guard streak.longest > 0 else { return "Longest — none yet" }
        return "Longest \(Formatters.streakDays(streak.longest))"
    }

    private static func emptyLine(kind: StreakKind) -> String {
        switch kind {
        case .pint, .brickAndBrew:
            return ""
        case .brick:
            return "No bricks on the calendar. The pool, road, and trail are still there."
        }
    }

    private static func currentLine(kind: StreakKind, days: Int) -> String {
        switch kind {
        case .pint, .brickAndBrew:
            return ""
        case .brick:
            return cheerAfterBrick(days: days)
        }
    }
}

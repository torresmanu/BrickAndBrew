import Foundation

/// Pub-table lines for streaks. Views stay dumb; tone lives here.
enum StreakCopy {
    static let loadingMessage = "Counting pints and bricks…"
    static let emptyTitle = "No streak yet"
    static let emptyMessage = "Log a pint or sync a session to start a streak."
    static let brickSyncLag = "Brick streaks catch up when Strava syncs."
    static let pintReminderTitle = "The tap is waiting"
    static let pintReminderFooter = "If yesterday's pint is unmatched, we'll ping once at 7:00 pm. On from the first time you open the crew. Turn it off anytime."
    static let pintReminderDenied = "Notifications are off for Brick & Brew. Turn them on in iOS Settings if you want the 7:00 pm pint ping."

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
        case .pint:
            return "Yesterday's pint is getting lonely."
        case .brick:
            return "Yesterday's session is waiting for a sequel."
        case .brickAndBrew:
            return "You trained and toasted yesterday. The pub rule wants an encore."
        }
    }

    static func cheerAfterPint(days: Int) -> String {
        switch days {
        case 1:
            return "You're on the board. First pint of the season."
        case 2:
            return "Two days. That's a habit, not a hobby."
        case 3:
            return "Three days. The tap knows your name."
        case 4:
            return "Four days. That's a tab, not a hobby."
        case 7:
            return "A full week of honest thirst. The crew has been notified (spiritually)."
        default:
            if days > 1, days.isMultiple(of: 7) {
                return "\(Formatters.streakDays(days)). That's a round the pub will remember."
            }
            return "\(Formatters.streakDays(days)). Keep the tab open."
        }
    }

    static func cheerAfterBrick(days: Int) -> String {
        switch days {
        case 1:
            return "Brick is live. Strava showed up; the streak noticed."
        case 2:
            return "Two days of honest work. The pint can wait — or not."
        case 7:
            return "A week of bricks. Recovery days are for the weak. (Kidding. Mostly.)"
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
        case .pint:
            return "The tap is patient. It will wait."
        case .brick:
            return "No bricks on the calendar. The pool, road, and trail are still there."
        case .brickAndBrew:
            return "Train and toast on the same day. That's the pub rule."
        }
    }

    private static func currentLine(kind: StreakKind, days: Int) -> String {
        switch kind {
        case .pint:
            return cheerAfterPint(days: days)
        case .brick:
            return cheerAfterBrick(days: days)
        case .brickAndBrew:
            switch days {
            case 1:
                return "Trained and toasted. That's the pub rule."
            case 7:
                return "Seven doubles. The Index is blushing."
            default:
                return "\(Formatters.streakDays(days)) of trained-and-toasted. The pub rule is proud."
            }
        }
    }
}

import Foundation

/// Decides if and when the 7:00 pm pint ping should fire. No UserNotifications here.
enum PintReminderPlanner: Sendable {
    static let hour = 19
    static let minute = 0
    static let identifier = "pint.atRisk"

    /// Next fire date, or nil when the pending request should be cancelled.
    static func nextFire(
        streak: Streak,
        now: Date = Date(),
        calendar: Calendar = .current,
        enabled: Bool
    ) -> Date? {
        guard enabled, streak.current > 0 else { return nil }

        if streak.isAtRisk(now: now, calendar: calendar) {
            guard let todayFire = fireDate(on: now, calendar: calendar), now < todayFire else {
                return nil
            }
            return todayFire
        }

        // Locked in today: schedule tomorrow so a skip still gets one ping.
        guard let last = streak.lastQualifyingDay, calendar.isDate(last, inSameDayAs: now) else {
            return nil
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return nil
        }
        return fireDate(on: tomorrow, calendar: calendar)
    }

    static func fireDate(on day: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }
}

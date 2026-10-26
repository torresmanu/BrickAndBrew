import Foundation

enum Formatters {
    static func kilometers(_ meters: Double) -> String {
        let km = meters / Scoring.metersPerKilometer
        return String(format: "%.1f km", km)
    }

    static func points(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f pts", value)
        }
        return String(format: "%.1f pts", value)
    }

    static func movingTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    /// Race-card clock: `48:33` or `2:28:49`. Never negative.
    static func raceTime(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let remainder = clamped % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%d:%02d", minutes, remainder)
    }

    /// Medal-card date, e.g. `26 JULY 2026`.
    static func raceDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = timeZone
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }

    /// Filename-safe UTC day stamp.
    static func raceFileStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Swim stays in meters under 3 km; bike and run stay in kilometers.
    static func raceDistance(meters: Double, sport: SportKind) -> String {
        if sport == .swim, meters < 3_000 {
            return "\(grouped(meters, fractionDigits: 0)) m"
        }
        return kilometers(meters)
    }

    static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func beerCount(_ count: Int) -> String {
        count == 1 ? "1 beer" : "\(count) beers"
    }

    static func streakDays(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    /// Whole numbers stay compact; fractions keep one decimal for the scoring guide.
    static func compactNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    /// Zero-padded rank used as a graphic: 01, 02, 12.
    static func rank(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    /// Points without the unit, so MetricView can set PTS in display type.
    static func pointsValue(_ value: Double) -> String {
        grouped(value, fractionDigits: value == value.rounded() ? 0 : 1)
    }

    /// Receipt sign for a points delta. Uses a minus sign so negative tax lines stay tabular.
    static func signedPointsValue(_ value: Double) -> String {
        let amount = pointsValue(abs(value))
        if value > 0 {
            return "+\(amount)"
        }
        if value < 0 {
            return "−\(amount)"
        }
        return amount
    }

    /// Kilometers without the unit, so MetricView can set KM beside the number.
    static func distanceValue(meters: Double) -> String {
        grouped(meters / Scoring.metersPerKilometer, fractionDigits: 1)
    }

    static func beerUnit(_ count: Int) -> String {
        count == 1 ? "PINT" : "PINTS"
    }

    private static func grouped(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits == 0 ? 0 : min(1, fractionDigits)
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? compactNumber(value)
    }
}

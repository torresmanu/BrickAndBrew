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

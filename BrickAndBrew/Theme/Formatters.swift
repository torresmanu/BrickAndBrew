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
}

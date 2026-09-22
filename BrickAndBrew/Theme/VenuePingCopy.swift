import Foundation

/// In-app copy for the nearby pint ping. Plist purpose strings stay in Info.plist.
enum VenuePingCopy {
    static let toggleTitle = "Nearby pint"
    static let footer =
        "On from the first time you open the crew. Between 6:00 pm and 2:00 am, if you linger at a bar, brewery, or restaurant, we'll ask once whether to log a pint. We skip saved home and work. Location stays on this iPhone and never goes to the crew board."
    static let denied =
        "Location or notifications are off for Brick & Brew. Turn on Always and Precise Location — and notifications — in iOS Settings if you want the nearby pint ping."
    static let needsAlways =
        "The first iOS sheet only offers While Using. If a second sheet asked to Change to Always, pick that. Otherwise open Settings → Brick & Brew → Location → Always."
    static let needsPrecise =
        "Nearby pint needs Precise Location so we can tell a bar from your couch. Turn it on for Brick & Brew in iOS Settings."
    static let pausedAlways = "Paused. Allow Always Location in iOS Settings to resume."
    static let pausedPrecise = "Paused. Turn on Precise Location for Brick & Brew in iOS Settings."
    static let homeTitle = "Home"
    static let workTitle = "Work"
    static let setHome = "Set home"
    static let setWork = "Set work"
    static let clear = "Clear"
    static let emptyPlace = "Not set — we'll still ping if a bar is nearby."
    static let enabling = "Asking iOS for location…"
    static let findingSpot = "Finding this spot…"
    static let fixFailed = "We couldn't read this spot. Try again in a moment."
    static let fallbackLabel = "Saved location"
    static let notificationTitle = "Logging a pint?"
    static let homeAccessibility = "Home exclusion pin"
    static let workAccessibility = "Work exclusion pin"

    static func notificationBody(placeName: String) -> String {
        "Looks like you're at \(placeName). Logging a pint?"
    }
}

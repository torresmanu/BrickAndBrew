import Foundation

/// User-facing copy for the triathlon finisher card. Views stay dumb.
enum FinisherCopy {
    static let sectionTitle = "Finisher"
    static let loadingMessage = "Looking for a triathlon…"
    static let emptyTitle = "No triathlon yet"
    static let emptyMessage = "Finish a swim, then a bike, then a run in that order on race day and we hang a medal you can share."
    static let connectTitle = "Connect Strava"
    static let connectMessage = "Connect Strava so a swim-bike-run day can become a shareable finisher card."
    static let rulesFooter = "We look for consecutive qualifying swim → bike → run legs within 18 hours. Walks and other sports in between are ignored. Virtual rides and trail runs count. Super-sprint floors: 400 m, 10 km, 2.5 km."
    static let loadedFooter = "Minted from your Strava swim, bike, and run."
    static let shareTitle = "Share card"
    static let saveTitle = "Save to Photos"
    static let savingMessage = "Saving your card…"
    static let renderingMessage = "Rendering your card…"
    static let savedMessage = "Saved to Photos. Post it wherever the crew drinks."
    static let raceKicker = "BRICK & BREW"
    static let raceTitle = "TRIATHLON"
    static let raceSubtitle = "FINISHER"
    static let totalLabel = "TOTAL"
    static let celebrationKicker = "TRIATHLON"
    static let celebrationTitle = "FINISHER."
    static let feedHint = "1080 × 1080 · Instagram feed"
    static let storyHint = "1080 × 1920 · Instagram story"

    static func athleteLine(_ finish: TriathlonFinish) -> String {
        let name = finish.athleteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = finish.crewCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return code.isEmpty ? "CREW" : code.uppercased()
        }
        if code.isEmpty || code == "—" {
            return name.uppercased()
        }
        return "\(name.uppercased()) / \(code.uppercased())"
    }

    static func celebrationDetail(_ finish: TriathlonFinish) -> String {
        "\(finish.athleteName). \(Formatters.raceDate(finish.startDate)). Total \(Formatters.raceTime(finish.elapsedSeconds))."
    }

    static func teaserLine(_ finish: TriathlonFinish) -> String {
        "\(Formatters.raceDate(finish.startDate)) · \(Formatters.raceTime(finish.elapsedSeconds))"
    }

    static func formatHint(_ format: FinisherCardFormat) -> String {
        switch format {
        case .square: feedHint
        case .story: storyHint
        }
    }
}

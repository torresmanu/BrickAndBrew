import Foundation

extension MeViewModel {
    var currentFinishIds: Set<String> {
        if case .loaded(let finishes) = finisherState {
            return Set(finishes.map(\.id))
        }
        return []
    }

    /// After a Strava sync, cheer only if a new medal appeared and the race is still fresh.
    func noteNewFinish(previousIds: Set<String>, now: Date = Date()) {
        guard case .loaded(let finishes) = finisherState, let latest = finishes.first else {
            return
        }
        guard previousIds.contains(latest.id) == false else { return }
        let age = now.timeIntervalSince(latest.finishDate)
        guard age >= 0, age <= 72 * 60 * 60 else { return }
        pendingNewFinish = latest
        celebratedFinish = latest
        Haptics.success()
    }

    func consumeCelebratedFinish() -> TriathlonFinish? {
        let finish = celebratedFinish
        celebratedFinish = nil
        return finish
    }
}

import Foundation

@MainActor
@Observable
final class LogBeerViewModel {
    var count: Int = 1
    var note: String = ""
    var state: LoadState<[Beer]> = .loading
    var isSaving = false
    var bannerMessage: String?

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    func load() async {
        state = .loading
        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }
            let beers = try await session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
            state = beers.isEmpty ? .empty : .loaded(beers)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    func incrementCount() {
        count = min(count + 1, 12)
    }

    func decrementCount() {
        count = max(count - 1, 1)
    }

    func logBeers() async {
        guard isSaving == false else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }
            let beer = Beer(
                id: UUID().uuidString,
                userId: profile.id,
                teamId: team.id,
                count: count,
                loggedAt: Date(),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            _ = try await session.cloudKit.saveBeer(beer)
            note = ""
            count = 1
            Haptics.success()
            await load()
        } catch {
            Haptics.warning()
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't save that beer. Try again."
        }
    }

    func retry() async {
        await load()
    }
}

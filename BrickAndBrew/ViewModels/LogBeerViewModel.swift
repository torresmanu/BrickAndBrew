import Foundation
import UIKit

@MainActor
@Observable
final class LogBeerViewModel {
    var note: String = ""
    var state: LoadState<[Beer]> = .loading
    var isSaving = false
    var bannerMessage: String?
    var cheerMessage: String?
    var didScoreThisLog = false
    var pendingPhotoJPEG: Data?
    var isCameraPresented = false
    var showsOpenSettings = false
    var photoBeerIds: Set<String> = []

    private let session: AppSession
    private var loadGeneration = 0
    private var loadedTeamId: String?

    init(session: AppSession) {
        self.session = session
    }

    var pendingPhotoImage: UIImage? {
        guard let pendingPhotoJPEG else { return nil }
        return UIImage(data: pendingPhotoJPEG)
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        if loadedTeamId != nil && loadedTeamId != session.team?.id {
            state = .loading
            photoBeerIds = []
        } else {
            switch state {
            case .loaded, .empty:
                break
            default:
                state = .loading
            }
        }

        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }
            async let beersTask = session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
            async let photosTask = session.cloudKit.fetchBeerPhotos(userId: profile.id, teamId: team.id)
            let beers = try await beersTask
            let photos = (try? await photosTask) ?? []
            guard generation == loadGeneration else { return }
            loadedTeamId = team.id
            photoBeerIds = Set(photos.map(\.beerId))
            applyBeers(beers, seasonStart: team.seasonStart)
        } catch {
            guard generation == loadGeneration else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            switch state {
            case .loaded, .empty:
                bannerMessage = message
            default:
                state = .failed(message)
            }
        }
    }

    func requestCamera() async {
        guard CameraCapture.isAvailable else {
            bannerMessage = BrickError.cameraUnavailable.localizedDescription
            return
        }
        let allowed = await CameraCapture.requestAccess()
        if allowed {
            isCameraPresented = true
            return
        }
        showsOpenSettings = true
        bannerMessage = BrickError.cameraDenied.localizedDescription
    }

    func applyCapturedPhoto(_ data: Data) {
        isCameraPresented = false
        do {
            pendingPhotoJPEG = try ImageJPEGProcessor.makeJPEG(
                from: data,
                maxPixelSize: ImageJPEGProcessor.beerPhotoMaxPixelSize,
                squareCrop: false
            )
        } catch {
            pendingPhotoJPEG = nil
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? ImageJPEGProcessor.ProcessorError.invalidImage.localizedDescription
        }
    }

    func cancelCamera() {
        isCameraPresented = false
    }

    func removePendingPhoto() {
        pendingPhotoJPEG = nil
    }

    func logBeers() async {
        guard isSaving == false else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }
            let jpeg = pendingPhotoJPEG
            let beer = Beer(
                id: UUID().uuidString,
                userId: profile.id,
                teamId: team.id,
                count: 1,
                loggedAt: Date(),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            _ = try await session.cloudKit.saveBeer(beer)
            note = ""
            pendingPhotoJPEG = nil
            Haptics.success()

            if let jpeg {
                do {
                    _ = try await session.cloudKit.saveBeerPhoto(BeerPhoto(beer: beer), jpegData: jpeg)
                    photoBeerIds.insert(beer.id)
                } catch {
                    Haptics.warning()
                    bannerMessage = "That pint is on the board, but we couldn't save the photo. Try logging another with a new snap."
                }
            }

            do {
                let beers = try await session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
                applyBeers(beers, seasonStart: team.seasonStart)
                didScoreThisLog = await pintScoresOnIndex(
                    beers: beers,
                    team: team,
                    userId: profile.id
                )
            } catch {
                let optimistic = optimisticBeers(including: beer)
                applyBeers(optimistic, seasonStart: team.seasonStart)
                didScoreThisLog = await pintScoresOnIndex(
                    beers: optimistic,
                    team: team,
                    userId: profile.id
                )
            }
            cheerMessage = didScoreThisLog
                ? "On the Index. One pint on a training day adds \(Formatters.compactNumber(Scoring.pointsPerScoredPint)) points. Another today would not."
                : "Saved. It counts on the Index only once, and only on a day you also swim, bike, or run."
        } catch {
            Haptics.warning()
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "We couldn't save that beer. Try again."
        }
    }

    func dismissCheer() {
        cheerMessage = nil
    }

    func retry() async {
        await load()
    }

    private func applyBeers(_ beers: [Beer], seasonStart: Date) {
        state = beers.isEmpty ? .empty : .loaded(beers)
    }

    /// True only for the first pint today on a day that already has a qualifying brick.
    private func pintScoresOnIndex(beers: [Beer], team: Team, userId: String) async -> Bool {
        let activities: [Activity]
        do {
            activities = try await session.cloudKit.fetchActivities(teamId: team.id, since: team.seasonStart)
        } catch {
            return false
        }
        let calendar = Calendar.current
        let today = Date()
        let trainedToday = activities.contains { activity in
            activity.userId == userId
                && activity.startDate >= team.seasonStart
                && calendar.isDate(activity.startDate, inSameDayAs: today)
                && StreakCalculator.qualifies(activity)
        }
        guard trainedToday else { return false }
        let pintsToday = beers.filter { beer in
            beer.count >= 1 && calendar.isDate(beer.loggedAt, inSameDayAs: today)
        }
        return pintsToday.count == 1
    }

    private func optimisticBeers(including beer: Beer) -> [Beer] {
        if case .loaded(let existing) = state {
            return [beer] + existing
        }
        return [beer]
    }
}

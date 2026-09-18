import Foundation
import UIKit

@MainActor
@Observable
final class LogBeerViewModel {
    var count: Int = 1
    var note: String = ""
    var state: LoadState<[Beer]> = .loading
    var isSaving = false
    var bannerMessage: String?
    var cheerMessage: String?
    var pintStreak: Streak = .empty
    var pendingPhotoJPEG: Data?
    var isCameraPresented = false
    var showsOpenSettings = false
    var photoBeerIds: Set<String> = []

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    var showsPintNudge: Bool {
        cheerMessage == nil && pintStreak.isAtRisk()
    }

    var pendingPhotoImage: UIImage? {
        guard let pendingPhotoJPEG else { return nil }
        return UIImage(data: pendingPhotoJPEG)
    }

    func load() async {
        switch state {
        case .loaded, .empty:
            break
        default:
            state = .loading
        }

        do {
            guard let profile = session.profile, let team = session.team else {
                throw BrickError.missingProfile
            }
            async let beersTask = session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
            async let photosTask = session.cloudKit.fetchBeerPhotos(userId: profile.id, teamId: team.id)
            let beers = try await beersTask
            let photos = (try? await photosTask) ?? []
            photoBeerIds = Set(photos.map(\.beerId))
            applyBeers(beers, seasonStart: team.seasonStart)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            switch state {
            case .loaded, .empty:
                bannerMessage = message
            default:
                state = .failed(message)
            }
        }
    }

    func incrementCount() {
        count = min(count + 1, 12)
    }

    func decrementCount() {
        count = max(count - 1, 1)
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
                count: count,
                loggedAt: Date(),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            _ = try await session.cloudKit.saveBeer(beer)
            note = ""
            count = 1
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

            // The pour is on the board even if the list refresh fails.
            do {
                let beers = try await session.cloudKit.fetchBeers(userId: profile.id, teamId: team.id)
                applyBeers(beers, seasonStart: team.seasonStart)
            } catch {
                applyBeers(optimisticBeers(including: beer), seasonStart: team.seasonStart)
            }
            cheerMessage = StreakCopy.cheerAfterPint(days: pintStreak.current)
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
        pintStreak = StreakCalculator.summarize(
            activities: [],
            beers: beers,
            seasonStart: seasonStart
        ).pint
        Task {
            await PintReminderScheduler.refresh(pint: pintStreak)
        }
    }

    private func optimisticBeers(including beer: Beer) -> [Beer] {
        if case .loaded(let existing) = state {
            return [beer] + existing
        }
        return [beer]
    }
}

import CoreLocation
import Foundation
import UIKit

enum VenueAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case whenInUse
    case alwaysReduced
    case ready
}

enum VenueLocationError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        VenuePingCopy.fixFailed
    }
}

/// Visit monitoring for the nearby pint ping. Recreated at launch so iOS can deliver visits.
final class VenueVisitMonitor: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = VenueVisitMonitor()

    private let manager = CLLocationManager()
    private let stateLock = NSLock()
    private var authWaiters: [CheckedContinuation<Void, Never>] = []
    private var locationWaiter: CheckedContinuation<CLLocation, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.pausesLocationUpdatesAutomatically = true
        manager.showsBackgroundLocationIndicator = false
    }

    /// Must run from app init, not after async bootstrap, so visit relaunches have a delegate.
    func prepare() {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        manager.allowsBackgroundLocationUpdates = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        refreshMonitoring()
    }

    func refreshMonitoring() {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        if VenuePingSettings.isEnabled, authorization == .ready {
            manager.startMonitoringVisits()
        } else {
            manager.stopMonitoringVisits()
        }
    }

    func stopAndClear() {
        VenuePingScheduler.cancel()
        VenuePlaceStore.clearAll()
        refreshMonitoring()
    }

    var authorization: VenueAuthorization {
        switch manager.authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .restricted, .denied:
            .denied
        case .authorizedWhenInUse:
            .whenInUse
        case .authorizedAlways:
            manager.accuracyAuthorization == .fullAccuracy ? .ready : .alwaysReduced
        @unknown default:
            .denied
        }
    }

    func requestAlwaysPrecise() async -> VenueAuthorization {
        guard LaunchEnvironment.isRunningUnitTests == false else { return .denied }
        _ = await requestWhenInUse()
        switch authorization {
        case .denied, .notDetermined:
            return authorization
        case .ready:
            return .ready
        case .whenInUse, .alwaysReduced:
            break
        }
        if manager.authorizationStatus == .authorizedWhenInUse {
            await waitForAuthorizationChange(
                after: { self.manager.requestAlwaysAuthorization() },
                resumeIfStillActiveAfter: .seconds(1.2)
            )
        }
        return authorization
    }

    func requestWhenInUse() async -> VenueAuthorization {
        guard LaunchEnvironment.isRunningUnitTests == false else { return .denied }
        if manager.authorizationStatus == .notDetermined {
            await waitForAuthorizationChange(after: { self.manager.requestWhenInUseAuthorization() })
        }
        return authorization
    }

    func currentFix() async throws -> CLLocation {
        guard LaunchEnvironment.isRunningUnitTests == false else {
            throw VenueLocationError.unavailable
        }
        switch authorization {
        case .whenInUse, .alwaysReduced, .ready:
            break
        case .denied, .notDetermined:
            throw VenueLocationError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            stateLock.lock()
            if locationWaiter != nil {
                stateLock.unlock()
                continuation.resume(throwing: VenueLocationError.unavailable)
                return
            }
            locationWaiter = continuation
            stateLock.unlock()
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        resumeAuthWaiters()
        refreshMonitoring()
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        let snapshot = VenuePingPlanner.VisitSnapshot(
            coordinate: VenuePingPlanner.Coordinate(
                latitude: visit.coordinate.latitude,
                longitude: visit.coordinate.longitude
            ),
            arrivalDate: visit.arrivalDate,
            horizontalAccuracy: visit.horizontalAccuracy,
            isPrecise: manager.accuracyAuthorization == .fullAccuracy,
            isArrival: visit.departureDate == .distantFuture
        )
        Task { await handle(snapshot) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        resumeLocation(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeLocation(.failure(error))
    }

    private func handle(_ snapshot: VenuePingPlanner.VisitSnapshot) async {
        guard LaunchEnvironment.isRunningUnitTests == false else { return }
        guard VenuePingSettings.isEnabled, authorization == .ready else { return }

        let first = VenuePingPlanner.decide(
            enabled: true,
            visit: snapshot,
            home: VenuePlaceStore.home?.coordinate,
            work: VenuePlaceStore.work?.coordinate,
            nearbyPOI: nil,
            didLookupPOI: false,
            lastBeerLoggedAt: VenuePlaceStore.lastBeerLoggedAt,
            lastPingAt: VenuePlaceStore.lastPingAt
        )
        switch first {
        case .skip:
            return
        case .ping:
            return
        case .needsPOILookup:
            break
        }

        let poi = await VenuePlaceClassifier.nearestDrinkVenue(at: snapshot.coordinate)
        let final = VenuePingPlanner.decide(
            enabled: true,
            visit: snapshot,
            home: VenuePlaceStore.home?.coordinate,
            work: VenuePlaceStore.work?.coordinate,
            nearbyPOI: poi,
            didLookupPOI: true,
            lastBeerLoggedAt: VenuePlaceStore.lastBeerLoggedAt,
            lastPingAt: VenuePlaceStore.lastPingAt
        )
        guard case .ping(let placeName) = final else { return }
        VenuePlaceStore.markPinged(at: snapshot.arrivalDate)
        await VenuePingScheduler.notify(placeName: placeName)
    }

    private func waitForAuthorizationChange(
        after request: @escaping () -> Void,
        resumeIfStillActiveAfter: Duration? = nil
    ) async {
        await withCheckedContinuation { continuation in
            stateLock.lock()
            authWaiters.append(continuation)
            stateLock.unlock()
            request()
            if let resumeIfStillActiveAfter {
                Task { [weak self] in
                    try? await Task.sleep(for: resumeIfStillActiveAfter)
                    guard let self, UIApplication.shared.applicationState == .active else { return }
                    self.resumeAuthWaiters()
                }
            }
        }
    }

    @objc private func appDidBecomeActive() {
        resumeAuthWaiters()
        refreshMonitoring()
    }

    private func resumeAuthWaiters() {
        stateLock.lock()
        let waiters = authWaiters
        authWaiters.removeAll()
        stateLock.unlock()
        waiters.forEach { waiter in
            waiter.resume()
        }
    }

    private func resumeLocation(_ result: Result<CLLocation, Error>) {
        stateLock.lock()
        let waiter = locationWaiter
        locationWaiter = nil
        stateLock.unlock()
        waiter?.resume(with: result)
    }
}

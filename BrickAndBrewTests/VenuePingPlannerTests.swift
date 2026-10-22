import Foundation
import Testing
@testable import BrickAndBrew

struct VenuePingPlannerTests {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private let origin = VenuePingPlanner.Coordinate(latitude: 0, longitude: 0)

    @Test func eighteenIsInsideWindow() {
        #expect(VenuePingPlanner.isInWindow(day(9, hour: 18, minute: 0), calendar: gmt))
    }

    @Test func justBeforeEighteenIsOutsideWindow() {
        #expect(VenuePingPlanner.isInWindow(day(9, hour: 17, minute: 59), calendar: gmt) == false)
    }

    @Test func lateEveningIsInsideWindow() {
        #expect(VenuePingPlanner.isInWindow(day(9, hour: 23, minute: 59), calendar: gmt))
    }

    @Test func halfPastMidnightIsInsideWindow() {
        #expect(VenuePingPlanner.isInWindow(day(10, hour: 0, minute: 30), calendar: gmt))
    }

    @Test func twoInTheMorningIsOutsideWindow() {
        #expect(VenuePingPlanner.isInWindow(day(10, hour: 2, minute: 0), calendar: gmt) == false)
    }

    @Test func disabledNeverPings() {
        let decision = VenuePingPlanner.decide(
            enabled: false,
            visit: arrival(at: day(9, hour: 19)),
            home: nil,
            work: nil,
            nearbyPOI: bar(distance: 20),
            didLookupPOI: true,
            lastBeerLoggedAt: nil,
            lastPingAt: nil,
            calendar: gmt
        )
        #expect(decision == .skip(.disabled))
    }

    @Test func reducedAccuracySkips() {
        var visit = arrival(at: day(9, hour: 19))
        visit.isPrecise = false
        let decision = decide(visit: visit, didLookupPOI: false)
        #expect(decision == .skip(.notPrecise))
    }

    @Test func poorVisitAccuracySkips() {
        var visit = arrival(at: day(9, hour: 19))
        visit.horizontalAccuracy = 151
        let decision = decide(visit: visit, didLookupPOI: false)
        #expect(decision == .skip(.poorAccuracy))
    }

    @Test func departureDoesNotPing() {
        var visit = arrival(at: day(9, hour: 19))
        visit.isArrival = false
        let decision = decide(visit: visit, didLookupPOI: false)
        #expect(decision == .skip(.notArrival))
    }

    @Test func alreadyLoggedTodaySkips() {
        let arrivalAt = day(9, hour: 19)
        let decision = decide(
            visit: arrival(at: arrivalAt),
            didLookupPOI: false,
            lastBeerLoggedAt: day(9, hour: 12)
        )
        #expect(decision == .skip(.alreadyLoggedToday))
    }

    @Test func alreadyPingedTodaySkips() {
        let arrivalAt = day(9, hour: 21)
        let decision = decide(
            visit: arrival(at: arrivalAt),
            didLookupPOI: false,
            lastPingAt: day(9, hour: 18, minute: 10)
        )
        #expect(decision == .skip(.alreadyPingedToday))
    }

    @Test func beerYesterdayDoesNotBlockTonight() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            didLookupPOI: false,
            lastBeerLoggedAt: day(8, hour: 21)
        )
        #expect(decision == .needsPOILookup)
    }

    @Test func homeWithinFortyMetersSkipsWithoutLookup() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            home: east(40),
            didLookupPOI: false
        )
        #expect(decision == .skip(.atHome))
    }

    @Test func workWithinFortyMetersSkipsWithoutLookup() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            work: east(40),
            didLookupPOI: false
        )
        #expect(decision == .skip(.atWork))
    }

    @Test func homeAtOneTwentyWithCloserBarAllowsPing() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            home: east(120),
            nearbyPOI: bar(distance: 40),
            didLookupPOI: true
        )
        #expect(decision == .ping(placeName: "The Tap"))
    }

    @Test func homeAtOneTwentyWithoutBarSkips() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            home: east(120),
            nearbyPOI: nil,
            didLookupPOI: true
        )
        #expect(decision == .skip(.atHome))
    }

    @Test func homeAtOneTwentyWithFartherBarSkips() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            home: east(120),
            nearbyPOI: bar(distance: 130),
            didLookupPOI: true
        )
        #expect(decision == .skip(.atHome))
    }

    @Test func farFromHomeNeedsPOILookup() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            home: east(400),
            didLookupPOI: false
        )
        #expect(decision == .needsPOILookup)
    }

    @Test func lookupWithNoPOISkips() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 19)),
            nearbyPOI: nil,
            didLookupPOI: true
        )
        #expect(decision == .skip(.noMatchingPOI))
    }

    @Test func matchingPOIPings() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 0, minute: 30)),
            nearbyPOI: bar(distance: 25),
            didLookupPOI: true
        )
        #expect(decision == .ping(placeName: "The Tap"))
    }

    @Test func seventeenFiftyNineDoesNotReachLookup() {
        let decision = decide(
            visit: arrival(at: day(9, hour: 17, minute: 59)),
            didLookupPOI: false
        )
        #expect(decision == .skip(.outsideWindow))
    }

    private func decide(
        visit: VenuePingPlanner.VisitSnapshot,
        home: VenuePingPlanner.Coordinate? = nil,
        work: VenuePingPlanner.Coordinate? = nil,
        nearbyPOI: VenuePingPlanner.NearbyPOI? = nil,
        didLookupPOI: Bool,
        lastBeerLoggedAt: Date? = nil,
        lastPingAt: Date? = nil
    ) -> VenuePingPlanner.Decision {
        VenuePingPlanner.decide(
            enabled: true,
            visit: visit,
            home: home,
            work: work,
            nearbyPOI: nearbyPOI,
            didLookupPOI: didLookupPOI,
            lastBeerLoggedAt: lastBeerLoggedAt,
            lastPingAt: lastPingAt,
            calendar: gmt
        )
    }

    private func arrival(at date: Date) -> VenuePingPlanner.VisitSnapshot {
        VenuePingPlanner.VisitSnapshot(
            coordinate: origin,
            arrivalDate: date,
            horizontalAccuracy: 20,
            isPrecise: true,
            isArrival: true
        )
    }

    private func bar(distance: Double) -> VenuePingPlanner.NearbyPOI {
        VenuePingPlanner.NearbyPOI(
            name: "The Tap",
            coordinate: east(distance),
            distanceMeters: distance
        )
    }

    /// Offset east of the equator origin so haversine meters stay predictable.
    private func east(_ meters: Double) -> VenuePingPlanner.Coordinate {
        let degrees = meters / 111_195.0
        return VenuePingPlanner.Coordinate(latitude: 0, longitude: degrees)
    }

    private func day(_ day: Int, hour: Int, minute: Int = 0) -> Date {
        gmt.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }
}

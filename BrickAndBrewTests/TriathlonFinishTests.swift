import CloudKit
import CoreGraphics
import Foundation
import Testing
@testable import BrickAndBrew

struct TriathlonFinishTests {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func olympicDayInOrderIsAFinish() throws {
        let swim = leg(.swim, day: 26, hour: 7, minute: 2, meters: 1_500, moving: 28 * 60 + 12)
        let ride = leg(.ride, day: 26, hour: 7, minute: 42, meters: 40_200, moving: 72 * 60 + 4)
        let run = leg(.run, day: 26, hour: 9, minute: 6, meters: 10_100, moving: 48 * 60 + 33)

        let finishes = TriathlonDetector.detect(
            activities: [run, swim, ride],
            athleteName: "Alex Rivera",
            crewCode: "BRICK"
        )

        let finish = try #require(finishes.first)
        #expect(finishes.count == 1)
        #expect(finish.swim.id == swim.id)
        #expect(finish.ride.id == ride.id)
        #expect(finish.run.id == run.id)
        #expect(finish.athleteName == "Alex Rivera")
        #expect(finish.crewCode == "BRICK")
        #expect(finish.elapsedSeconds == 2 * 3600 + 52 * 60 + 33)
        #expect(finish.movingSeconds == (28 * 60 + 12) + (72 * 60 + 4) + (48 * 60 + 33))
    }

    @Test func wrongOrderDoesNotCount() {
        let ride = leg(.ride, day: 26, hour: 7, meters: 40_000, moving: 4_000)
        let swim = leg(.swim, day: 26, hour: 8, meters: 1_500, moving: 1_800)
        let run = leg(.run, day: 26, hour: 9, meters: 10_000, moving: 3_000)
        let finishes = TriathlonDetector.detect(
            activities: [ride, swim, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.isEmpty)
    }

    @Test func missingDisciplineDoesNotCount() {
        let swim = leg(.swim, day: 26, hour: 7, meters: 1_500, moving: 1_800)
        let ride = leg(.ride, day: 26, hour: 8, meters: 40_000, moving: 4_000)
        let finishes = TriathlonDetector.detect(
            activities: [swim, ride],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.isEmpty)
    }

    @Test func activitiesTooFarApartDoNotCount() {
        let swim = leg(.swim, day: 26, hour: 7, meters: 1_500, moving: 1_800)
        let ride = leg(.ride, day: 26, hour: 8, meters: 40_000, moving: 4_000)
        // Run starts more than 18 hours after the swim, even as a consecutive triple.
        let run = leg(.run, day: 27, hour: 4, meters: 10_000, moving: 3_000)
        let finishes = TriathlonDetector.detect(
            activities: [swim, ride, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.isEmpty)
        #expect(run.startDate.timeIntervalSince(swim.startDate) > TriathlonDetector.maximumElapsed)
    }

    @Test func walkBetweenLegsIsIgnored() {
        let swim = leg(.swim, day: 26, hour: 7, meters: 1_500, moving: 1_800)
        let walk = leg(.other, day: 26, hour: 7, minute: 40, meters: 800, moving: 600, type: "Walk")
        let ride = leg(.ride, day: 26, hour: 8, meters: 40_000, moving: 4_000)
        let run = leg(.run, day: 26, hour: 9, minute: 30, meters: 10_000, moving: 3_000)
        let finishes = TriathlonDetector.detect(
            activities: [swim, walk, ride, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.count == 1)
        #expect(finishes.first?.swim.id == swim.id)
        #expect(finishes.first?.run.id == run.id)
    }

    @Test func extraRideBetweenBikeAndRunBreaksTheRace() {
        let swim = leg(.swim, day: 26, hour: 7, meters: 1_500, moving: 1_800)
        let ride = leg(.ride, day: 26, hour: 8, meters: 40_000, moving: 4_000)
        let extraRide = leg(.ride, day: 26, hour: 9, meters: 12_000, moving: 2_000, stravaId: 99)
        let run = leg(.run, day: 26, hour: 10, meters: 10_000, moving: 3_000)
        let finishes = TriathlonDetector.detect(
            activities: [swim, ride, extraRide, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.isEmpty)
    }

    @Test func shortLegsBelowSuperSprintFloorsDoNotCount() {
        let swim = leg(.swim, day: 26, hour: 7, meters: 399, moving: 1_200)
        let ride = leg(.ride, day: 26, hour: 8, meters: 9_999, moving: 2_000)
        let run = leg(.run, day: 26, hour: 9, meters: 2_499, moving: 1_200)
        let finishes = TriathlonDetector.detect(
            activities: [swim, ride, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.isEmpty)
    }

    @Test func mappedStravaSportTypesStillFormARace() throws {
        let start = instant(day: 26, hour: 7)
        let swimDTO = dto(
            id: 1,
            type: "Swim",
            sportType: "OpenWaterSwim",
            distance: 1_500,
            moving: 1_800,
            start: start
        )
        let rideDTO = dto(
            id: 2,
            type: "Ride",
            sportType: "VirtualRide",
            distance: 40_000,
            moving: 4_000,
            start: instant(day: 26, hour: 8)
        )
        let runDTO = dto(
            id: 3,
            type: "Run",
            sportType: "TrailRun",
            distance: 10_000,
            moving: 3_000,
            start: instant(day: 26, hour: 9, minute: 30)
        )

        let activities = [swimDTO, rideDTO, runDTO].compactMap {
            ActivityMapper.map($0, userId: "p1", teamId: "t1")
        }
        #expect(activities.map(\.sport) == [.swim, .ride, .run])

        let finishes = TriathlonDetector.detect(
            activities: activities,
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.count == 1)
        #expect(try #require(finishes.first).swim.type == "OpenWaterSwim")
        #expect(try #require(finishes.first).ride.type == "VirtualRide")
        #expect(try #require(finishes.first).run.type == "TrailRun")
    }

    @Test func newestFinishIsFirstAndLegsAreNotReused() {
        let first = [
            leg(.swim, day: 12, hour: 7, meters: 1_500, moving: 1_800, stravaId: 1),
            leg(.ride, day: 12, hour: 8, meters: 40_000, moving: 4_000, stravaId: 2),
            leg(.run, day: 12, hour: 9, meters: 10_000, moving: 3_000, stravaId: 3)
        ]
        let second = [
            leg(.swim, day: 26, hour: 7, meters: 1_900, moving: 2_000, stravaId: 4),
            leg(.ride, day: 26, hour: 8, meters: 90_000, moving: 8_000, stravaId: 5),
            leg(.run, day: 26, hour: 11, meters: 21_100, moving: 5_000, stravaId: 6)
        ]
        let finishes = TriathlonDetector.detect(
            activities: first + second,
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.count == 2)
        #expect(finishes.first?.swim.stravaId == 4)
        #expect(finishes.last?.swim.stravaId == 1)
    }

    @Test func ironmanLengthDayStillFitsTheWindow() {
        let swim = leg(.swim, day: 26, hour: 6, meters: 3_800, moving: 4_200)
        let ride = leg(.ride, day: 26, hour: 7, minute: 30, meters: 180_000, moving: 6 * 3600)
        let run = leg(.run, day: 26, hour: 16, meters: 42_200, moving: 4 * 3600)
        let finishes = TriathlonDetector.detect(
            activities: [swim, ride, run],
            athleteName: "Alex",
            crewCode: "BRICK"
        )
        #expect(finishes.count == 1)
        #expect(finishes.first?.elapsedSeconds == 14 * 3600)
    }

    @Test func raceTimeFormatsMinutesAndHours() {
        #expect(Formatters.raceTime(0) == "0:00")
        #expect(Formatters.raceTime(48) == "0:48")
        #expect(Formatters.raceTime(48 * 60 + 33) == "48:33")
        #expect(Formatters.raceTime(2 * 3600 + 28 * 60 + 49) == "2:28:49")
        #expect(Formatters.raceTime(-12) == "0:00")
    }

    @Test func raceDateMatchesMedalCardCopy() {
        let date = instant(day: 26, hour: 7)
        #expect(Formatters.raceDate(date, timeZone: gmt.timeZone) == "26 JULY 2026")
        #expect(Formatters.raceFileStamp(date) == "2026-07-26")
    }

    @Test func raceDistanceKeepsSwimInMeters() {
        let swim = Formatters.raceDistance(meters: 1_500, sport: .swim)
        #expect(swim.hasSuffix(" m"))
        #expect(swim.contains("1"))
        #expect(Formatters.raceDistance(meters: 40_200, sport: .ride) == "40.2 km")
        #expect(Formatters.raceDistance(meters: 10_100, sport: .run) == "10.1 km")
    }

    @Test func athleteLineJoinsNameAndCrewCode() {
        #expect(FinisherCopy.athleteLine(.preview) == "ALEX RIVERA / BRICK")
    }

    @Test func photosDeniedCopyTellsTheUserToShareInstead() {
        let message = BrickError.photosDenied.localizedDescription ?? ""
        #expect(message.contains("Photos access is off"))
        #expect(message.contains("share"))
    }

    @Test func cardFormatsExportAtInstagramPixelSizes() {
        #expect(FinisherCardFormat.square.pixelSize.width == 1080)
        #expect(FinisherCardFormat.square.pixelSize.height == 1080)
        #expect(FinisherCardFormat.story.pixelSize.width == 1080)
        #expect(FinisherCardFormat.story.pixelSize.height == 1920)
    }

    @Test func decodesTheGooglePolylineSample() {
        let points = PolylineCodec.decode(PolylineCodec.googleSample)
        #expect(points.count == 3)
        #expect(abs(points[0].latitude - 38.5) < 0.00001)
        #expect(abs(points[0].longitude - (-120.2)) < 0.00001)
        #expect(abs(points[1].latitude - 40.7) < 0.00001)
        #expect(abs(points[2].longitude - (-126.453)) < 0.00001)
    }

    @Test func encodeRoundTripsDecodedPoints() {
        let original = PolylineCodec.decode(PolylineCodec.sampleBike)
        let again = PolylineCodec.decode(PolylineCodec.encode(original))
        #expect(again.count == original.count)
        if let first = original.first, let restored = again.first {
            #expect(abs(first.latitude - restored.latitude) < 0.00002)
            #expect(abs(first.longitude - restored.longitude) < 0.00002)
        }
    }

    @Test func emptyAndTruncatedPolylinesDoNotCrash() {
        #expect(PolylineCodec.decode("") == [])
        #expect(PolylineCodec.decode("   ") == [])
        _ = PolylineCodec.decode("!")
        _ = PolylineCodec.decode("%%%%")
        #expect(PolylineCodec.usesFallback(nil))
        #expect(PolylineCodec.usesFallback(""))
    }

    @Test func aSinglePingIsNotADrawableRoute() {
        let ping = [GeoPoint(latitude: 41.38, longitude: 2.17)]
        #expect(PolylineCodec.isDrawable(ping) == false)
        let stuck = [
            GeoPoint(latitude: 41.38, longitude: 2.17),
            GeoPoint(latitude: 41.38, longitude: 2.17)
        ]
        #expect(PolylineCodec.isDrawable(stuck) == false)
        #expect(PolylineCodec.points(fitting: ping, in: CGRect(x: 0, y: 0, width: 100, height: 60)).isEmpty)
    }

    @Test func sampleRacePolylinesFitInsideAPlate() {
        let rect = CGRect(x: 0, y: 0, width: 120, height: 64)
        let swim = PolylineCodec.points(fitting: PolylineCodec.decode(PolylineCodec.sampleSwim), in: rect)
        let bike = PolylineCodec.points(fitting: PolylineCodec.decode(PolylineCodec.sampleBike), in: rect)
        let run = PolylineCodec.points(fitting: PolylineCodec.decode(PolylineCodec.sampleRun), in: rect)
        #expect(swim.count >= 8)
        #expect(bike.count >= 8)
        #expect(run.count >= 8)
        #expect(PolylineCodec.usesFallback(PolylineCodec.sampleSwim) == false)
        #expect(TriathlonFinish.preview.swim.summaryPolyline == PolylineCodec.sampleSwim)
        #expect(PolylineCodec.usesFallback(TriathlonFinish.previewWithoutGPS.swim.summaryPolyline))
        #expect(PolylineCodec.usesFallback(TriathlonFinish.previewWithoutGPS.ride.summaryPolyline))
        #expect(PolylineCodec.usesFallback(TriathlonFinish.previewWithoutGPS.run.summaryPolyline))
        for point in swim + bike + run {
            #expect(point.x >= rect.minX - 0.01)
            #expect(point.x <= rect.maxX + 0.01)
            #expect(point.y >= rect.minY - 0.01)
            #expect(point.y <= rect.maxY + 0.01)
        }
    }

    @Test func poolSwimFallsBackWhileOutdoorLegsStayDrawn() {
        let finish = TriathlonFinish.previewPoolSwim
        #expect(PolylineCodec.usesFallback(finish.swim.summaryPolyline))
        #expect(PolylineCodec.usesFallback(finish.ride.summaryPolyline) == false)
        #expect(PolylineCodec.usesFallback(finish.run.summaryPolyline) == false)
    }

    @Test func cloudKitOmitsAnEmptyPolyline() {
        let original = Activity(
            id: "activity-p1-8",
            stravaId: 8,
            userId: "p1",
            teamId: "t1",
            type: "Swim",
            sport: .swim,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            distanceMeters: 1_500,
            movingTimeSeconds: 1_800,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            summaryPolyline: nil
        )
        let record = original.makeRecord()
        #expect(record[CloudKitKey.Activity.summaryPolyline] == nil)
        #expect(Activity(record: record)?.summaryPolyline == nil)
    }

    @Test func cloudKitRoundTripsAPolyline() {
        let original = Activity(
            id: "activity-p1-9",
            stravaId: 9,
            userId: "p1",
            teamId: "t1",
            type: "Run",
            sport: .run,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            distanceMeters: 5_000,
            movingTimeSeconds: 1_500,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            summaryPolyline: PolylineCodec.googleSample
        )
        let restored = Activity(record: original.makeRecord())
        #expect(restored?.summaryPolyline == PolylineCodec.googleSample)
        #expect(restored?.sport == .run)
    }

    private func instant(day: Int, hour: Int, minute: Int = 0) -> Date {
        gmt.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute))!
    }

    private func leg(
        _ sport: SportKind,
        day: Int,
        hour: Int,
        minute: Int = 0,
        meters: Double,
        moving: Int,
        type: String? = nil,
        stravaId: Int64? = nil
    ) -> Activity {
        let id = stravaId ?? Int64(sport.hashValue + day + hour + minute + Int(meters))
        return Activity(
            id: "activity-p1-\(id)",
            stravaId: id,
            userId: "p1",
            teamId: "t1",
            type: type ?? sport.rawValue,
            sport: sport,
            startDate: instant(day: day, hour: hour, minute: minute),
            distanceMeters: meters,
            movingTimeSeconds: moving,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
    }

    private func dto(
        id: Int64,
        type: String,
        sportType: String,
        distance: Double,
        moving: Int,
        start: Date
    ) -> StravaActivityDTO {
        StravaActivityDTO(
            id: id,
            name: sportType,
            type: type,
            sportType: sportType,
            distance: distance,
            movingTime: moving,
            elapsedTime: moving,
            totalElevationGain: 0,
            startDate: start,
            averageHeartrate: nil,
            maxHeartrate: nil
        )
    }
}

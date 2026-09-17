import Foundation
import Testing
@testable import BrickAndBrew

struct ScoringTests {
    @Test func swimKilometerIsWorthTen() {
        let points = Scoring.trainingPoints(meters: 1000, sport: .swim)
        #expect(points == 10)
    }

    @Test func runKilometerIsWorthThree() {
        let points = Scoring.trainingPoints(meters: 1000, sport: .run)
        #expect(points == 3)
    }

    @Test func rideKilometerIsWorthOne() {
        let points = Scoring.trainingPoints(meters: 1000, sport: .ride)
        #expect(points == 1)
    }

    @Test func otherSportsDoNotScore() {
        let points = Scoring.trainingPoints(meters: 5000, sport: .other)
        #expect(points == 0)
    }

    @Test func beerAddsTwoPointsEach() {
        #expect(Scoring.beerPoints(count: 3) == 6)
    }

    @Test func negativeBeersDoNotScore() {
        #expect(Scoring.beerPoints(count: -2) == 0)
    }

    @Test func totalIndexAddsTrainingAndBeers() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 1000,
            runMeters: 1000,
            rideMeters: 1000,
            beerCount: 2
        )
        // 10 + 3 + 1 + 4
        #expect(entry.totalIndex == 18)
    }
}

struct ActivityMappingTests {
    @Test func mapsSwimSportType() {
        #expect(ActivityMapper.sport(type: "Swim", sportType: "Swim") == .swim)
    }

    @Test func mapsTrailRunToRunBoard() {
        #expect(ActivityMapper.sport(type: "Run", sportType: "TrailRun") == .run)
    }

    @Test func mapsVirtualRideToBikeBoard() {
        #expect(ActivityMapper.sport(type: "Ride", sportType: "VirtualRide") == .ride)
    }

    @Test func mapsGravelRideToBikeBoard() {
        #expect(ActivityMapper.sport(type: "Ride", sportType: "GravelRide") == .ride)
    }

    @Test func walksDoNotCountAsRun() {
        #expect(ActivityMapper.sport(type: "Walk", sportType: "Walk") == .other)
    }

    @Test func dropsActivitiesWithoutAStartDate() {
        let dto = StravaActivityDTO(
            id: 9,
            name: "Ghost",
            type: "Run",
            sportType: "Run",
            distance: 1000,
            movingTime: 300,
            elapsedTime: 300,
            totalElevationGain: 0,
            startDate: nil,
            averageHeartrate: 140,
            maxHeartrate: 160
        )
        #expect(ActivityMapper.map(dto, userId: "u1", teamId: "t1") == nil)
    }

    @Test func mapsSummaryFieldsFromStrava() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let dto = StravaActivityDTO(
            id: 42,
            name: "Threshold",
            type: "Run",
            sportType: "TrailRun",
            distance: 5_000,
            movingTime: 1_500,
            elapsedTime: 1_560,
            totalElevationGain: 80,
            startDate: start,
            averageHeartrate: 152,
            maxHeartrate: 171
        )
        let activity = try #require(ActivityMapper.map(dto, userId: "user-1", teamId: "team-1"))
        #expect(activity.stravaId == 42)
        #expect(activity.sport == .run)
        #expect(activity.type == "TrailRun")
        #expect(activity.distanceMeters == 5_000)
        #expect(activity.movingTimeSeconds == 1_500)
        #expect(activity.averageHeartrate == 152)
        #expect(activity.maxHeartrate == 171)
        #expect(activity.elevationGain == 80)
        #expect(activity.id == "activity-user-1-42")
    }
}

struct LeaderboardBuilderTests {
    @Test func ignoresTrainingAndBeersBeforeSeasonStart() {
        let season = Date(timeIntervalSince1970: 2_000)
        let profile = Profile(
            id: "p1",
            appleUserId: "a1",
            displayName: "Sam",
            teamId: "t1",
            stravaAthleteId: nil,
            stravaAthleteName: nil
        )
        let oldRun = Activity(
            id: "old",
            stravaId: 1,
            userId: "p1",
            teamId: "t1",
            type: "Run",
            sport: .run,
            startDate: Date(timeIntervalSince1970: 1_000),
            distanceMeters: 10_000,
            movingTimeSeconds: 3_000,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
        let newRun = Activity(
            id: "new",
            stravaId: 2,
            userId: "p1",
            teamId: "t1",
            type: "Run",
            sport: .run,
            startDate: Date(timeIntervalSince1970: 3_000),
            distanceMeters: 1_000,
            movingTimeSeconds: 300,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
        let oldBeer = Beer(id: "b0", userId: "p1", teamId: "t1", count: 10, loggedAt: Date(timeIntervalSince1970: 500), note: nil)
        let newBeer = Beer(id: "b1", userId: "p1", teamId: "t1", count: 2, loggedAt: Date(timeIntervalSince1970: 4_000), note: nil)

        let entries = LeaderboardBuilder.build(
            profiles: [profile],
            activities: [oldRun, newRun],
            beers: [oldBeer, newBeer],
            seasonStart: season
        )

        #expect(entries.count == 1)
        #expect(entries[0].runMeters == 1_000)
        #expect(entries[0].beerCount == 2)
        #expect(entries[0].totalIndex == Scoring.trainingPoints(meters: 1_000, sport: .run) + Scoring.beerPoints(count: 2))
    }

    @Test func ranksBySelectedBoard() {
        let low = LeaderboardEntry(userId: "a", displayName: "A", swimMeters: 0, runMeters: 0, rideMeters: 10_000, beerCount: 0)
        let high = LeaderboardEntry(userId: "b", displayName: "B", swimMeters: 0, runMeters: 0, rideMeters: 1_000, beerCount: 20)
        let ranked = LeaderboardBuilder.ranked([low, high], board: .beers)
        #expect(ranked.first?.userId == "b")
    }
}

struct InviteCodeTests {
    @Test func normalizesAndValidatesCodes() {
        #expect(InviteCode.normalized("  brick1 ") == "BRICK1")
        #expect(InviteCode.isValid("CREW"))
        #expect(InviteCode.isValid("AB") == false)
        #expect(InviteCode.isValid("CREW-1") == false)
    }
}

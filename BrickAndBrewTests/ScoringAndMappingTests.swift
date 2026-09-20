import AuthenticationServices
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

    @Test func beerAddsTwelvePointsEach() {
        #expect(Scoring.beerPoints(count: 3) == 36)
    }

    @Test func negativeBeersDoNotScore() {
        #expect(Scoring.beerPoints(count: -2) == 0)
    }

    @Test func coveredTrainingMatchesBeersTimesCoverage() {
        #expect(Scoring.coveredTrainingPoints(beerCount: 2) == 40)
        #expect(Scoring.coveredTrainingPoints(beerCount: -1) == 0)
    }

    @Test func totalIndexAddsTrainingAndBeersWhenPintsCoverTheLoad() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 1000,
            runMeters: 1000,
            rideMeters: 1000,
            beerCount: 2
        )
        // Training 14 is inside 40 covered points, so no grind tax: 10 + 3 + 1 + 24.
        #expect(entry.grindTax == 0)
        #expect(entry.totalIndex == 38)
    }

    @Test func grindTaxHitsUncoveredTraining() {
        let tax = Scoring.grindTax(trainingPoints: 100, beerCount: 2)
        // 40 points covered; 60 uncovered; tax = 60 × 1.25.
        #expect(tax == 75)
    }

    @Test func trainingWithoutBeersGoesNegative() {
        let index = Scoring.totalIndex(
            swimMeters: 10_000,
            runMeters: 0,
            rideMeters: 0,
            beerCount: 0
        )
        // 100 training points, no coverage, tax 125 → −25.
        #expect(index == -25)
    }

    @Test func extraBeersBeatExtraKilometersOnTheIndex() {
        let grinder = LeaderboardEntry(
            userId: "g",
            displayName: "Grinder",
            swimMeters: 10_000,
            runMeters: 10_000,
            rideMeters: 80_000,
            beerCount: 2
        )
        let drinker = LeaderboardEntry(
            userId: "d",
            displayName: "Drinker",
            swimMeters: 1_000,
            runMeters: 1_000,
            rideMeters: 8_000,
            beerCount: 20
        )
        #expect(drinker.totalIndex > grinder.totalIndex)
    }

    @Test func uncoveredPenaltyPercentMatchesRate() {
        #expect(Scoring.uncoveredTrainingPenaltyPercent == 25)
    }

    @Test func compactNumberKeepsGuideCopyReadable() {
        #expect(Formatters.compactNumber(12) == "12")
        #expect(Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer / Scoring.runPointsPerKilometer) == "6.7")
    }

    @Test func signedPointsValueKeepsReceiptSigns() {
        #expect(Formatters.signedPointsValue(50) == "+\(Formatters.pointsValue(50))")
        #expect(Formatters.signedPointsValue(-2.5) == "−\(Formatters.pointsValue(2.5))")
        #expect(Formatters.signedPointsValue(0) == Formatters.pointsValue(0))
    }

    @Test func uncoveredTrainingIsLoadPastPintCoverage() {
        #expect(Scoring.uncoveredTrainingPoints(trainingPoints: 50, beerCount: 2) == 10)
        #expect(Scoring.grindTaxSurcharge(trainingPoints: 50, beerCount: 2) == 2.5)
        #expect(Scoring.grindTax(trainingPoints: 50, beerCount: 2) == 12.5)
    }

    @Test func streakDaysUsesSingularForOne() {
        #expect(Formatters.streakDays(1) == "1 day")
        #expect(Formatters.streakDays(12) == "12 days")
        #expect(Formatters.streakDays(0) == "0 days")
    }
}

struct ScoreBreakdownTests {
    @Test func coveredLoadShowsSportsAndBeersWithNoTax() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 1_000,
            runMeters: 1_000,
            rideMeters: 1_000,
            beerCount: 2
        )
        let breakdown = entry.scoreBreakdown(for: .overall)
        #expect(breakdown.lines.map(\.id) == ["swim", "ride", "run", "beers"])
        #expect(breakdown.lines.map(\.points) == [10, 1, 3, 24])
        #expect(breakdown.total == 38)
        #expect(breakdown.lines.reduce(0) { $0 + $1.points } == breakdown.total)
        #expect(breakdown.footnote == "Pints cover the training load. No grind tax.")
    }

    @Test func bikeAndBeersSplitUncoveredVolumeFromGrindTax() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 0,
            runMeters: 0,
            rideMeters: 50_000,
            beerCount: 2
        )
        let breakdown = entry.scoreBreakdown(for: .overall)
        #expect(breakdown.lines.map(\.id) == ["ride", "beers", "uncovered", "tax"])
        #expect(breakdown.lines.map(\.points) == [50, 24, -10, -2.5])
        #expect(breakdown.total == 61.5)
        #expect(breakdown.total == entry.totalIndex)
        #expect(breakdown.footnote.contains("10 went uncovered"))
    }

    @Test func emptyIndexHasFriendlyCopyAndZeroTotal() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 0,
            runMeters: 0,
            rideMeters: 0,
            beerCount: 0
        )
        let breakdown = entry.scoreBreakdown(for: .overall)
        #expect(breakdown.isEmpty)
        #expect(breakdown.total == 0)
        #expect(breakdown.emptyMessage.contains("The Index stays at zero"))
    }

    @Test func trainingWithoutBeersDropsTheLoadThenTaxesIt() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 10_000,
            runMeters: 0,
            rideMeters: 0,
            beerCount: 0
        )
        let breakdown = entry.scoreBreakdown(for: .overall)
        #expect(breakdown.lines.map(\.points) == [100, -100, -25])
        #expect(breakdown.total == -25)
        #expect(breakdown.total == entry.totalIndex)
        #expect(breakdown.footnote.contains("No pints this season"))
    }

    @Test func sportBoardOnlyShowsThatSport() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 0,
            runMeters: 0,
            rideMeters: 50_000,
            beerCount: 2
        )
        let breakdown = entry.scoreBreakdown(for: .ride)
        #expect(breakdown.lines.map(\.points) == [50])
        #expect(breakdown.total == 50)
        #expect(breakdown.footnote.contains("grind tax only hits the Index"))
    }

    @Test func beersBoardIgnoresTraining() {
        let entry = LeaderboardEntry(
            userId: "1",
            displayName: "Alex",
            swimMeters: 1_000,
            runMeters: 0,
            rideMeters: 0,
            beerCount: 2
        )
        let breakdown = entry.scoreBreakdown(for: .beers)
        #expect(breakdown.lines.map(\.points) == [24])
        #expect(breakdown.total == 24)
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
        #expect(entries[0].totalIndex == Scoring.totalIndex(
            swimMeters: 0,
            runMeters: 1_000,
            rideMeters: 0,
            beerCount: 2
        ))
    }

    @Test func ranksBySelectedBoard() {
        let low = LeaderboardEntry(userId: "a", displayName: "A", swimMeters: 0, runMeters: 0, rideMeters: 10_000, beerCount: 0)
        let high = LeaderboardEntry(userId: "b", displayName: "B", swimMeters: 0, runMeters: 0, rideMeters: 1_000, beerCount: 20)
        let ranked = LeaderboardBuilder.ranked([low, high], board: .beers)
        #expect(ranked.first?.userId == "b")
    }

    @Test func attachesSeasonStreaksToEachEntry() {
        var gmt = Calendar(identifier: .gregorian)
        gmt.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = gmt.date(from: DateComponents(year: 2026, month: 1, day: 9, hour: 12))!
        let day8 = gmt.date(from: DateComponents(year: 2026, month: 1, day: 8, hour: 12))!
        let season = gmt.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let profile = Profile(
            id: "p1",
            appleUserId: "a1",
            displayName: "Sam",
            teamId: "t1",
            stravaAthleteId: nil,
            stravaAthleteName: nil
        )
        let run = Activity(
            id: "r1",
            stravaId: 2,
            userId: "p1",
            teamId: "t1",
            type: "Run",
            sport: .run,
            startDate: day8,
            distanceMeters: 5_000,
            movingTimeSeconds: 1_500,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
        let pint = Beer(id: "b1", userId: "p1", teamId: "t1", count: 1, loggedAt: day8, note: nil)

        let entries = LeaderboardBuilder.build(
            profiles: [profile],
            activities: [run],
            beers: [pint],
            seasonStart: season,
            now: now,
            calendar: gmt
        )

        #expect(entries[0].streaks.pint.current == 1)
        #expect(entries[0].streaks.brick.current == 1)
        #expect(entries[0].streaks.brickAndBrew.current == 1)
        #expect(entries[0].streaks.pint.isAtRisk(now: now, calendar: gmt))
        #expect(entries[0].streaks.brick.isAtRisk(now: now, calendar: gmt))
        #expect(entries[0].streaks.brickAndBrew.isAtRisk(now: now, calendar: gmt))
    }

    @Test func decodesLegacySnapshotsWithoutStreaks() throws {
        let json = """
        {"userId":"a","displayName":"A","swimMeters":0,"runMeters":0,"rideMeters":0,"beerCount":2}
        """
        let entry = try JSONDecoder().decode(LeaderboardEntry.self, from: Data(json.utf8))
        #expect(entry.beerCount == 2)
        #expect(entry.streaks == .empty)
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

struct DisplayNameTests {
    @Test func trimsAndRejectsBlankNames() throws {
        #expect(DisplayName.normalized("  Alex  ") == "Alex")
        #expect(throws: BrickError.missingDisplayName) {
            try DisplayName.validated("   ")
        }
    }

    @Test func acceptsARecognizableName() throws {
        #expect(try DisplayName.validated("  Alex Rivera ") == "Alex Rivera")
    }

    @Test func rejectsNamesOverTheLimit() {
        let tooLong = String(repeating: "a", count: DisplayName.maxLength + 1)
        #expect(throws: BrickError.displayNameTooLong) {
            try DisplayName.validated(tooLong)
        }
    }
}

struct AppleSignInErrorMappingTests {
    @Test func cancelledSignInShowsCancelledMessage() {
        let error = ASAuthorizationError(.canceled)
        #expect(AuthService.userMessage(forSignInError: error) == BrickError.appleSignInCancelled.localizedDescription)
    }

    @Test func unknownAuthorizationErrorIsNotTreatedAsCancel() {
        // Apple reports Code=1000 (.unknown) when the Sign in with Apple entitlement is missing.
        let error = ASAuthorizationError(.unknown)
        #expect(AuthService.userMessage(forSignInError: error) == BrickError.appleSignInFailed.localizedDescription)
    }
}

struct AccountDeletionTests {
    @Test func accountDeletionErrorAsksTheUserToRetry() {
        let message = BrickError.accountDeletionFailed.localizedDescription ?? ""
        #expect(message.contains("couldn't delete your account"))
    }
}

struct StreakCalculatorTests {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    /// Noon UTC on 1-based day-of-month in January 2026, so start-of-day math stays off midnight.
    private func day(_ day: Int, hour: Int = 12) -> Date {
        gmt.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour))!
    }

    @Test func emptyHistoryIsZero() {
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [],
            seasonStart: day(1),
            now: day(10),
            calendar: gmt
        )
        #expect(set == .empty)
    }

    @Test func sameDayDuplicatesCountOnce() {
        let beers = [
            beer(loggedAt: day(8, hour: 11), count: 1),
            beer(loggedAt: day(8, hour: 22), count: 2)
        ]
        let set = StreakCalculator.summarize(
            activities: [],
            beers: beers,
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.pint.current == 1)
        #expect(set.pint.longest == 1)
    }

    @Test func threeBeersInOneLogStillOnePintDay() {
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [beer(loggedAt: day(8), count: 3)],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.pint.current == 1)
    }

    @Test func yesterdayKeepsTheStreakAliveAndAtRisk() {
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [beer(loggedAt: day(7)), beer(loggedAt: day(8))],
            seasonStart: day(1),
            now: day(9),
            calendar: gmt
        )
        #expect(set.pint.current == 2)
        #expect(set.pint.longest == 2)
        #expect(set.pint.isAtRisk(now: day(9), calendar: gmt))
    }

    @Test func todayLocksTheStreakIn() {
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [beer(loggedAt: day(7)), beer(loggedAt: day(8)), beer(loggedAt: day(9))],
            seasonStart: day(1),
            now: day(9),
            calendar: gmt
        )
        #expect(set.pint.current == 3)
        #expect(set.pint.isAtRisk(now: day(9), calendar: gmt) == false)
    }

    @Test func twoDayGapResetsCurrentButKeepsLongest() {
        let beers = [beer(loggedAt: day(3)), beer(loggedAt: day(4)), beer(loggedAt: day(5)), beer(loggedAt: day(8))]
        let set = StreakCalculator.summarize(
            activities: [],
            beers: beers,
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.pint.current == 1)
        #expect(set.pint.longest == 3)
        #expect(set.pint.isAtRisk(now: day(8), calendar: gmt) == false)
    }

    @Test func seasonStartCutsHistory() {
        let beers = [beer(loggedAt: day(2)), beer(loggedAt: day(3)), beer(loggedAt: day(8))]
        let set = StreakCalculator.summarize(
            activities: [],
            beers: beers,
            seasonStart: day(7),
            now: day(8),
            calendar: gmt
        )
        #expect(set.pint.current == 1)
        #expect(set.pint.longest == 1)
    }

    @Test func otherSportDoesNotCountAsBrick() {
        let walk = activity(sport: .other, start: day(8), meters: 8_000, moving: 3_600)
        let set = StreakCalculator.summarize(
            activities: [walk],
            beers: [],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.brick.current == 0)
    }

    @Test func shortRunBelowDistanceAndTimeFloorsDoesNotCount() {
        let jog = activity(sport: .run, start: day(8), meters: 500, moving: 5 * 60)
        let set = StreakCalculator.summarize(
            activities: [jog],
            beers: [],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.brick.current == 0)
    }

    @Test func shortRunStillCountsWhenItTakesTime() {
        let jog = activity(sport: .run, start: day(8), meters: 500, moving: 12 * 60)
        let set = StreakCalculator.summarize(
            activities: [jog],
            beers: [],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.brick.current == 1)
    }

    @Test func distanceFloorCountsEvenWhenTheWatchIsFast() {
        let swim = activity(sport: .swim, start: day(8), meters: 200, moving: 4 * 60)
        let set = StreakCalculator.summarize(
            activities: [swim],
            beers: [],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.brick.current == 1)
    }

    @Test func comboNeedsTrainingAndAPintOnTheSameDay() {
        let run = activity(sport: .run, start: day(8), meters: 5_000, moving: 1_500)
        let set = StreakCalculator.summarize(
            activities: [run],
            beers: [beer(loggedAt: day(8, hour: 20))],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.pint.current == 1)
        #expect(set.brick.current == 1)
        #expect(set.brickAndBrew.current == 1)
    }

    @Test func comboDoesNotFormWhenThePintIsADifferentDay() {
        let run = activity(sport: .run, start: day(8), meters: 5_000, moving: 1_500)
        let set = StreakCalculator.summarize(
            activities: [run],
            beers: [beer(loggedAt: day(7))],
            seasonStart: day(1),
            now: day(8),
            calendar: gmt
        )
        #expect(set.brickAndBrew.current == 0)
        #expect(set.pint.isAtRisk(now: day(8), calendar: gmt))
    }

    @Test func midnightSplitsPintDays() {
        let late = beer(loggedAt: day(8, hour: 23))
        let early = beer(loggedAt: day(9, hour: 0))
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [late, early],
            seasonStart: day(1),
            now: day(9, hour: 1),
            calendar: gmt
        )
        #expect(set.pint.current == 2)
        #expect(calendarDaysApart(set.pint.lastQualifyingDay, day(9)) == true)
    }

    @Test func olderThanYesterdayBreaksCurrent() {
        let set = StreakCalculator.summarize(
            activities: [],
            beers: [beer(loggedAt: day(5)), beer(loggedAt: day(6))],
            seasonStart: day(1),
            now: day(9),
            calendar: gmt
        )
        #expect(set.pint.current == 0)
        #expect(set.pint.longest == 2)
        #expect(set.pint.isAtRisk(now: day(9), calendar: gmt) == false)
    }

    @Test func boardPicksTheStreakKindForTheBadge() {
        #expect(LeaderboardBoard.overall.streakKind == .brickAndBrew)
        #expect(LeaderboardBoard.beers.streakKind == .pint)
        #expect(LeaderboardBoard.swim.streakKind == .brick)
        #expect(LeaderboardBoard.run.streakKind == .brick)
        #expect(LeaderboardBoard.ride.streakKind == .brick)
        #expect(LeaderboardBoard.swim.sport == .swim)
        #expect(LeaderboardBoard.run.sport == .run)
        #expect(LeaderboardBoard.ride.sport == .ride)
        #expect(LeaderboardBoard.ride.sport?.systemImage == "figure.outdoor.cycle")
        #expect(LeaderboardBoard.overall.sport == nil)
        #expect(LeaderboardBoard.beers.sport == nil)
    }

    private func calendarDaysApart(_ last: Date?, _ expected: Date) -> Bool {
        guard let last else { return false }
        return gmt.isDate(last, inSameDayAs: expected)
    }

    private func beer(loggedAt: Date, count: Int = 1) -> Beer {
        Beer(id: UUID().uuidString, userId: "p1", teamId: "t1", count: count, loggedAt: loggedAt, note: nil)
    }

    private func activity(sport: SportKind, start: Date, meters: Double, moving: Int) -> Activity {
        Activity(
            id: UUID().uuidString,
            stravaId: Int64(meters),
            userId: "p1",
            teamId: "t1",
            type: sport.rawValue,
            sport: sport,
            startDate: start,
            distanceMeters: meters,
            movingTimeSeconds: moving,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
    }
}

struct PintReminderPlannerTests {
    private var gmt: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func disabledNeverFires() {
        let fire = PintReminderPlanner.nextFire(
            streak: atRiskStreak(now: day(9, hour: 15)),
            now: day(9, hour: 15),
            calendar: gmt,
            enabled: false
        )
        #expect(fire == nil)
    }

    @Test func zeroStreakNeverFires() {
        let fire = PintReminderPlanner.nextFire(
            streak: .empty,
            now: day(9, hour: 15),
            calendar: gmt,
            enabled: true
        )
        #expect(fire == nil)
    }

    @Test func atRiskBeforeSevenSchedulesToday() throws {
        let now = day(9, hour: 15)
        let fire = try #require(
            PintReminderPlanner.nextFire(
                streak: atRiskStreak(now: now),
                now: now,
                calendar: gmt,
                enabled: true
            )
        )
        #expect(gmt.component(.hour, from: fire) == 19)
        #expect(gmt.isDate(fire, inSameDayAs: now))
    }

    @Test func atRiskAfterSevenDoesNotFireLate() {
        let now = day(9, hour: 20)
        let fire = PintReminderPlanner.nextFire(
            streak: atRiskStreak(now: now),
            now: now,
            calendar: gmt,
            enabled: true
        )
        #expect(fire == nil)
    }

    @Test func loggedTodaySchedulesTomorrow() throws {
        let now = day(9, hour: 15)
        let fire = try #require(
            PintReminderPlanner.nextFire(
                streak: lockedInStreak(now: now),
                now: now,
                calendar: gmt,
                enabled: true
            )
        )
        let tomorrow = gmt.date(byAdding: .day, value: 1, to: gmt.startOfDay(for: now))!
        #expect(gmt.isDate(fire, inSameDayAs: tomorrow))
        #expect(gmt.component(.hour, from: fire) == 19)
    }

    @Test func midnightStillUsesStartOfDayForAtRisk() throws {
        let now = day(9, hour: 0)
        let fire = try #require(
            PintReminderPlanner.nextFire(
                streak: atRiskStreak(now: now),
                now: now,
                calendar: gmt,
                enabled: true
            )
        )
        #expect(gmt.isDate(fire, inSameDayAs: now))
        #expect(gmt.component(.hour, from: fire) == 19)
    }

    private func day(_ day: Int, hour: Int) -> Date {
        gmt.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour))!
    }

    private func atRiskStreak(now: Date) -> Streak {
        let yesterday = gmt.date(byAdding: .day, value: -1, to: gmt.startOfDay(for: now))!
        return Streak(current: 2, longest: 2, lastQualifyingDay: yesterday)
    }

    private func lockedInStreak(now: Date) -> Streak {
        Streak(current: 3, longest: 3, lastQualifyingDay: now)
    }
}

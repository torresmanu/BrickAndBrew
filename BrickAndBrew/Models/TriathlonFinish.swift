import CoreGraphics
import Foundation

/// Instagram-ready export sizes. Designed at 360 pt and rendered at 3× (1080 px).
enum FinisherCardFormat: String, CaseIterable, Identifiable, Sendable {
    case square
    case story

    var id: String { rawValue }

    /// Layout size in points. ImageRenderer multiplies by `exportScale` for pixels.
    var designSize: CGSize {
        switch self {
        case .square:
            CGSize(width: 360, height: 360)
        case .story:
            CGSize(width: 360, height: 640)
        }
    }

    /// 360 × 3 = 1080, matching Instagram feed and story width.
    var exportScale: CGFloat { 3 }

    var pixelSize: CGSize {
        CGSize(
            width: designSize.width * exportScale,
            height: designSize.height * exportScale
        )
    }

    var title: String {
        switch self {
        case .square: "Feed"
        case .story: "Story"
        }
    }

    var isStory: Bool {
        self == .story
    }
}

/// One inferred race: a swim, then a bike, then a run from the athlete's Strava log.
struct TriathlonFinish: Identifiable, Sendable, Hashable {
    let swim: Activity
    let ride: Activity
    let run: Activity
    let athleteName: String
    let crewCode: String

    var id: String {
        "\(swim.id)|\(ride.id)|\(run.id)"
    }

    var startDate: Date { swim.startDate }

    /// Watch-stop after the run, used for elapsed race time.
    var finishDate: Date {
        run.startDate.addingTimeInterval(TimeInterval(max(0, run.movingTimeSeconds)))
    }

    /// Wall-clock from swim start to run finish, including transitions.
    var elapsedSeconds: Int {
        max(0, Int(finishDate.timeIntervalSince(startDate).rounded()))
    }

    var movingSeconds: Int {
        max(0, swim.movingTimeSeconds) + max(0, ride.movingTimeSeconds) + max(0, run.movingTimeSeconds)
    }

    func activity(for sport: SportKind) -> Activity {
        switch sport {
        case .swim: swim
        case .ride: ride
        case .run: run
        case .other: swim
        }
    }

    var shareFilename: String {
        let stamp = Formatters.raceFileStamp(startDate)
        return "brick-and-brew-finisher-\(stamp).png"
    }
}

/// Detects triathlon finishes from synced Strava activities.
///
/// Rules (also covered by unit tests):
/// 1. Only `SportKind` swim / ride / run count. Mapping already treats OpenWaterSwim,
///    VirtualRide, GravelRide, TrailRun, etc. as those sports. Walk, hike, yoga, and
///    a Strava "Triathlon" multi-sport file (stored as `.other`) are ignored and do
///    not break the sequence.
/// 2. Legs must meet super-sprint floors so a casual brick does not mint a medal:
///    400 m swim, 10 km bike, 2.5 km run, and a positive moving time.
/// 3. After filtering, activities are sorted by start date. A finish is three
///    consecutive qualifying legs in order swim → bike → run.
/// 4. The run must finish within 18 hours of the swim start (Ironman cutoff is 17h).
/// 5. Start times must be strictly increasing so overlapping files cannot match.
/// 6. Matching legs are consumed so one activity cannot sit in two medals.
/// 7. Results are newest-first. The Me tab shows the latest; older finishes stay
///    reachable from that section.
enum TriathlonDetector: Sendable {
    static let minimumSwimMeters = 400.0
    static let minimumRideMeters = 10_000.0
    static let minimumRunMeters = 2_500.0
    static let maximumElapsed: TimeInterval = 18 * 60 * 60
    static let raceOrder: [SportKind] = [.swim, .ride, .run]

    static func detect(
        activities: [Activity],
        athleteName: String,
        crewCode: String
    ) -> [TriathlonFinish] {
        let legs = activities
            .filter(isQualifyingLeg)
            .sorted(by: chronological)

        guard legs.count >= 3 else { return [] }

        var finishes: [TriathlonFinish] = []
        var index = 0
        while index + 2 < legs.count {
            let swim = legs[index]
            let ride = legs[index + 1]
            let run = legs[index + 2]
            if let finish = makeFinish(
                swim: swim,
                ride: ride,
                run: run,
                athleteName: athleteName,
                crewCode: crewCode
            ) {
                finishes.append(finish)
                // Skip the whole race so these legs cannot form a second medal.
                index += 3
            } else {
                index += 1
            }
        }

        return finishes.reversed()
    }

    static func isQualifyingLeg(_ activity: Activity) -> Bool {
        guard activity.movingTimeSeconds > 0 else { return false }
        switch activity.sport {
        case .swim:
            return activity.distanceMeters >= minimumSwimMeters
        case .ride:
            return activity.distanceMeters >= minimumRideMeters
        case .run:
            return activity.distanceMeters >= minimumRunMeters
        case .other:
            return false
        }
    }

    private static func makeFinish(
        swim: Activity,
        ride: Activity,
        run: Activity,
        athleteName: String,
        crewCode: String
    ) -> TriathlonFinish? {
        guard swim.sport == .swim, ride.sport == .ride, run.sport == .run else {
            return nil
        }
        guard swim.startDate < ride.startDate, ride.startDate < run.startDate else {
            return nil
        }

        let finish = TriathlonFinish(
            swim: swim,
            ride: ride,
            run: run,
            athleteName: athleteName,
            crewCode: crewCode
        )
        guard TimeInterval(finish.elapsedSeconds) <= maximumElapsed else {
            return nil
        }
        return finish
    }

    private static func chronological(_ lhs: Activity, _ rhs: Activity) -> Bool {
        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }
        return lhs.stravaId < rhs.stravaId
    }
}

extension TriathlonFinish {
    /// Olympic-distance sample used by SwiftUI previews, with GPS tracks.
    static let preview = sample(
        swimPolyline: PolylineCodec.sampleSwim,
        ridePolyline: PolylineCodec.sampleBike,
        runPolyline: PolylineCodec.sampleRun
    )

    /// Pool swim + indoor bike + no run GPS — fallback art on the mount.
    static let previewWithoutGPS = sample(
        swimPolyline: nil,
        ridePolyline: nil,
        runPolyline: nil
    )

    /// Pool swim with outdoor bike and run — mixed fallback on one plate.
    static let previewPoolSwim = sample(
        swimPolyline: nil,
        ridePolyline: PolylineCodec.sampleBike,
        runPolyline: PolylineCodec.sampleRun
    )

    private static func sample(
        swimPolyline: String?,
        ridePolyline: String?,
        runPolyline: String?
    ) -> TriathlonFinish {
        TriathlonFinish(
            swim: previewActivity(
                sport: .swim,
                type: "OpenWaterSwim",
                stravaId: 11,
                hour: 7,
                minute: 2,
                meters: 1_500,
                moving: 28 * 60 + 12,
                polyline: swimPolyline
            ),
            ride: previewActivity(
                sport: .ride,
                type: "Ride",
                stravaId: 12,
                hour: 7,
                minute: 42,
                meters: 40_200,
                moving: 72 * 60 + 4,
                polyline: ridePolyline
            ),
            run: previewActivity(
                sport: .run,
                type: "Run",
                stravaId: 13,
                hour: 9,
                minute: 6,
                meters: 10_100,
                moving: 48 * 60 + 33,
                polyline: runPolyline
            ),
            athleteName: "Alex Rivera",
            crewCode: "BRICK"
        )
    }

    private static func previewActivity(
        sport: SportKind,
        type: String,
        stravaId: Int64,
        hour: Int,
        minute: Int,
        meters: Double,
        moving: Int,
        polyline: String?
    ) -> Activity {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 26, hour: hour, minute: minute)
        ) ?? Date()
        return Activity(
            id: "activity-preview-\(stravaId)",
            stravaId: stravaId,
            userId: "preview",
            teamId: "team-brick",
            type: type,
            sport: sport,
            startDate: start,
            distanceMeters: meters,
            movingTimeSeconds: moving,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil,
            summaryPolyline: polyline
        )
    }
}

import Foundation

struct StravaActivityDTO: Decodable, Sendable, Equatable {
    let id: Int64
    let name: String?
    let type: String?
    let sportType: String?
    let distance: Double?
    let movingTime: Int?
    let elapsedTime: Int?
    let totalElevationGain: Double?
    let startDate: Date?
    let averageHeartrate: Double?
    let maxHeartrate: Double?
}

enum ActivityMapper {
    /// Prefer Strava `sport_type` (GravelRide, TrailRun, etc.) then fall back to `type`.
    static func sport(type: String?, sportType: String?) -> SportKind {
        let raw = (sportType ?? type ?? "").lowercased()
        if raw.contains("swim") {
            return .swim
        }
        if raw.contains("run") || raw.contains("walk") || raw.contains("hike") {
            // Walk/hike stay out of the triathlon run board.
            if raw.contains("walk") || raw.contains("hike") {
                return .other
            }
            return .run
        }
        if raw.contains("ride") || raw.contains("bike") || raw.contains("virtualride") {
            return .ride
        }
        return .other
    }

    static func map(_ dto: StravaActivityDTO, userId: String, teamId: String) -> Activity? {
        guard let startDate = dto.startDate else {
            return nil
        }

        let type = dto.sportType ?? dto.type ?? "Workout"
        return Activity(
            id: Activity.recordName(userId: userId, stravaId: dto.id),
            stravaId: dto.id,
            userId: userId,
            teamId: teamId,
            type: type,
            sport: sport(type: dto.type, sportType: dto.sportType),
            startDate: startDate,
            distanceMeters: dto.distance ?? 0,
            movingTimeSeconds: dto.movingTime ?? dto.elapsedTime ?? 0,
            averageHeartrate: dto.averageHeartrate,
            maxHeartrate: dto.maxHeartrate,
            elevationGain: dto.totalElevationGain
        )
    }
}

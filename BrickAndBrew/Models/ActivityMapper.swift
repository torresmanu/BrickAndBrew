import Foundation

struct StravaActivityDTO: Sendable, Equatable {
    /// Decimal activity id, taken from `id_str` when Strava sends it.
    let id: String
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
        guard let stravaId = StravaObjectID.objectID(dto.id), let startDate = dto.startDate else {
            return nil
        }

        let type = dto.sportType ?? dto.type ?? "Workout"
        return Activity(
            id: Activity.recordName(userId: userId, stravaId: stravaId),
            stravaId: stravaId,
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

extension StravaActivityDTO: Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case sportType
        case distance
        case movingTime
        case elapsedTime
        case totalElevationGain
        case startDate
        case averageHeartrate
        case maxHeartrate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try StravaObjectID.decode(from: decoder),
            name: try container.decodeIfPresent(String.self, forKey: .name),
            type: try container.decodeIfPresent(String.self, forKey: .type),
            sportType: try container.decodeIfPresent(String.self, forKey: .sportType),
            distance: try container.decodeIfPresent(Double.self, forKey: .distance),
            movingTime: try container.decodeIfPresent(Int.self, forKey: .movingTime),
            elapsedTime: try container.decodeIfPresent(Int.self, forKey: .elapsedTime),
            totalElevationGain: try container.decodeIfPresent(Double.self, forKey: .totalElevationGain),
            startDate: try container.decodeIfPresent(Date.self, forKey: .startDate),
            averageHeartrate: try container.decodeIfPresent(Double.self, forKey: .averageHeartrate),
            maxHeartrate: try container.decodeIfPresent(Double.self, forKey: .maxHeartrate)
        )
    }
}

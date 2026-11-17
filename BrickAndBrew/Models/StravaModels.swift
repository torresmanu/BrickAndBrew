import Foundation

struct StravaTokenResponse: Decodable, Sendable {
    let tokenType: String?
    let expiresAt: Int
    let expiresIn: Int?
    let refreshToken: String
    let accessToken: String
    let athlete: StravaAthleteDTO?
}

struct StravaAthleteDTO: Sendable {
    /// Decimal athlete id, taken from `id_str` when Strava sends it.
    let id: String
    let firstname: String?
    let lastname: String?

    var displayName: String {
        [firstname, lastname]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }
}

struct StravaCredentials: Sendable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    /// Decimal athlete id. Empty when a refresh response did not include the athlete.
    var athleteId: String
    var athleteName: String

    var isExpired: Bool {
        // Refresh one minute early so a request never uses a dead token.
        expiresAt.addingTimeInterval(-60) <= Date()
    }
}

extension StravaAthleteDTO: Decodable {
    private enum CodingKeys: String, CodingKey {
        case firstname
        case lastname
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try StravaObjectID.decode(from: decoder),
            firstname: try container.decodeIfPresent(String.self, forKey: .firstname),
            lastname: try container.decodeIfPresent(String.self, forKey: .lastname)
        )
    }
}

extension StravaCredentials: Codable {
    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresAt
        case athleteId
        case athleteName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            accessToken: try container.decode(String.self, forKey: .accessToken),
            refreshToken: try container.decode(String.self, forKey: .refreshToken),
            expiresAt: try container.decode(Date.self, forKey: .expiresAt),
            athleteId: try StravaObjectID.decodeStored(from: container, forKey: .athleteId),
            athleteName: try container.decodeIfPresent(String.self, forKey: .athleteName) ?? ""
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(athleteId, forKey: .athleteId)
        try container.encode(athleteName, forKey: .athleteName)
    }
}

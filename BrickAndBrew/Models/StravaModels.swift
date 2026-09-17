import Foundation

struct StravaTokenResponse: Decodable, Sendable {
    let tokenType: String?
    let expiresAt: Int
    let expiresIn: Int?
    let refreshToken: String
    let accessToken: String
    let athlete: StravaAthleteDTO?
}

struct StravaAthleteDTO: Decodable, Sendable {
    let id: Int64
    let firstname: String?
    let lastname: String?

    var displayName: String {
        [firstname, lastname]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }
}

struct StravaCredentials: Codable, Sendable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var athleteId: Int64
    var athleteName: String

    var isExpired: Bool {
        // Refresh one minute early so a request never uses a dead token.
        expiresAt.addingTimeInterval(-60) <= Date()
    }
}

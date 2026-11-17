import CloudKit
import Foundation

enum CloudKitKey {
    enum RecordType {
        static let team = "Team"
        static let profile = "Profile"
        static let activity = "Activity"
        static let beer = "Beer"
        static let beerPhoto = "BeerPhoto"
    }

    enum Team {
        static let inviteCode = "inviteCode"
        static let name = "name"
        static let seasonStart = "seasonStart"
    }

    enum Profile {
        static let appleUserId = "appleUserId"
        static let displayName = "displayName"
        static let teamId = "teamId"
        /// Signed 64-bit athlete id. Written when `id_str` fits in Int64.
        static let stravaAthleteId = "stravaAthleteId"
        /// Decimal athlete id. Written only when the id is wider than Int64.
        static let stravaAthleteIdString = "stravaAthleteIdString"
        static let stravaAthleteName = "stravaAthleteName"
        static let avatar = "avatar"
    }

    enum Activity {
        /// Signed 64-bit activity id. Written when `id_str` fits in Int64.
        static let stravaId = "stravaId"
        /// Decimal activity id. Written only when the id is wider than Int64.
        static let stravaIdString = "stravaIdString"
        static let userId = "userId"
        static let teamId = "teamId"
        static let type = "type"
        static let sport = "sport"
        static let startDate = "startDate"
        static let distanceMeters = "distanceMeters"
        static let movingTimeSeconds = "movingTimeSeconds"
        static let averageHeartrate = "averageHeartrate"
        static let maxHeartrate = "maxHeartrate"
        static let elevationGain = "elevationGain"
    }

    enum Beer {
        static let userId = "userId"
        static let teamId = "teamId"
        static let count = "count"
        static let loggedAt = "loggedAt"
        static let note = "note"
    }

    enum BeerPhoto {
        static let beerId = "beerId"
        static let userId = "userId"
        static let teamId = "teamId"
        static let count = "count"
        static let loggedAt = "loggedAt"
        static let note = "note"
        static let photo = "photo"
    }
}

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
        static let stravaAthleteId = "stravaAthleteId"
        static let stravaAthleteName = "stravaAthleteName"
        static let avatar = "avatar"
    }

    enum Activity {
        static let stravaId = "stravaId"
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

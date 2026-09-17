import CloudKit
import Foundation

enum CloudKitKey {
    enum RecordType {
        static let team = "Team"
        static let profile = "Profile"
        static let activity = "Activity"
        static let beer = "Beer"
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
}

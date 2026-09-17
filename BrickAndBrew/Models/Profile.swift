import CloudKit
import Foundation

struct Profile: Identifiable, Sendable, Hashable {
    let id: String
    var appleUserId: String
    var displayName: String
    var teamId: String
    var stravaAthleteId: Int64?
    var stravaAthleteName: String?

    var isStravaConnected: Bool {
        stravaAthleteId != nil
    }

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }
}

extension Profile {
    /// CloudKit record names cannot include some Apple user-id punctuation.
    static func recordName(forAppleUserId appleUserId: String) -> String {
        let sanitized = appleUserId.replacingOccurrences(of: ".", with: "-")
        return "profile-\(sanitized)"
    }

    init?(record: CKRecord) {
        guard
            let appleUserId = record[CloudKitKey.Profile.appleUserId] as? String,
            let displayName = record[CloudKitKey.Profile.displayName] as? String
        else {
            return nil
        }

        id = record.recordID.recordName
        self.appleUserId = appleUserId
        self.displayName = displayName
        teamId = record[CloudKitKey.Profile.teamId] as? String ?? ""
        if let athleteId = record[CloudKitKey.Profile.stravaAthleteId] as? Int64 {
            stravaAthleteId = athleteId
        } else if let athleteId = record[CloudKitKey.Profile.stravaAthleteId] as? Int {
            stravaAthleteId = Int64(athleteId)
        } else {
            stravaAthleteId = nil
        }
        stravaAthleteName = record[CloudKitKey.Profile.stravaAthleteName] as? String
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitKey.RecordType.profile, recordID: recordID)
        record[CloudKitKey.Profile.appleUserId] = appleUserId as CKRecordValue
        record[CloudKitKey.Profile.displayName] = displayName as CKRecordValue
        record[CloudKitKey.Profile.teamId] = teamId as CKRecordValue
        if let stravaAthleteId {
            record[CloudKitKey.Profile.stravaAthleteId] = stravaAthleteId as CKRecordValue
        } else {
            record[CloudKitKey.Profile.stravaAthleteId] = nil
        }
        if let stravaAthleteName, stravaAthleteName.isEmpty == false {
            record[CloudKitKey.Profile.stravaAthleteName] = stravaAthleteName as CKRecordValue
        } else {
            record[CloudKitKey.Profile.stravaAthleteName] = nil
        }
        return record
    }
}

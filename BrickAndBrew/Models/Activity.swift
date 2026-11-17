import CloudKit
import Foundation

struct Activity: Identifiable, Sendable, Hashable {
    let id: String
    /// Decimal Strava activity id (`id_str`).
    var stravaId: String
    var userId: String
    var teamId: String
    var type: String
    var sport: SportKind
    var startDate: Date
    var distanceMeters: Double
    var movingTimeSeconds: Int
    var averageHeartrate: Double?
    var maxHeartrate: Double?
    var elevationGain: Double?

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    /// Stable CloudKit name. `stravaId` is the decimal id, so activities saved
    /// before the 64-bit change keep the same record.
    static func recordName(userId: String, stravaId: String) -> String {
        "activity-\(userId)-\(stravaId)"
    }
}

extension Activity {
    init?(record: CKRecord) {
        guard
            let stravaId = StravaObjectID.read(
                from: record,
                integerField: CloudKitKey.Activity.stravaId,
                stringField: CloudKitKey.Activity.stravaIdString
            ),
            let userId = record[CloudKitKey.Activity.userId] as? String,
            let teamId = record[CloudKitKey.Activity.teamId] as? String,
            let type = record[CloudKitKey.Activity.type] as? String,
            let startDate = record[CloudKitKey.Activity.startDate] as? Date
        else {
            return nil
        }

        id = record.recordID.recordName
        self.stravaId = stravaId
        self.userId = userId
        self.teamId = teamId
        self.type = type
        if let sportRaw = record[CloudKitKey.Activity.sport] as? String {
            sport = SportKind(rawValue: sportRaw) ?? .other
        } else {
            sport = .other
        }
        self.startDate = startDate
        distanceMeters = record[CloudKitKey.Activity.distanceMeters] as? Double ?? 0
        if let moving = record[CloudKitKey.Activity.movingTimeSeconds] as? Int {
            movingTimeSeconds = moving
        } else if let moving = record[CloudKitKey.Activity.movingTimeSeconds] as? Int64 {
            movingTimeSeconds = Int(moving)
        } else {
            movingTimeSeconds = 0
        }
        averageHeartrate = record[CloudKitKey.Activity.averageHeartrate] as? Double
        maxHeartrate = record[CloudKitKey.Activity.maxHeartrate] as? Double
        elevationGain = record[CloudKitKey.Activity.elevationGain] as? Double
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitKey.RecordType.activity, recordID: recordID)
        StravaObjectID.write(
            stravaId,
            to: record,
            integerField: CloudKitKey.Activity.stravaId,
            stringField: CloudKitKey.Activity.stravaIdString
        )
        record[CloudKitKey.Activity.userId] = userId as CKRecordValue
        record[CloudKitKey.Activity.teamId] = teamId as CKRecordValue
        record[CloudKitKey.Activity.type] = type as CKRecordValue
        record[CloudKitKey.Activity.sport] = sport.rawValue as CKRecordValue
        record[CloudKitKey.Activity.startDate] = startDate as CKRecordValue
        record[CloudKitKey.Activity.distanceMeters] = distanceMeters as CKRecordValue
        record[CloudKitKey.Activity.movingTimeSeconds] = movingTimeSeconds as CKRecordValue
        if let averageHeartrate {
            record[CloudKitKey.Activity.averageHeartrate] = averageHeartrate as CKRecordValue
        }
        if let maxHeartrate {
            record[CloudKitKey.Activity.maxHeartrate] = maxHeartrate as CKRecordValue
        }
        if let elevationGain {
            record[CloudKitKey.Activity.elevationGain] = elevationGain as CKRecordValue
        }
        return record
    }
}

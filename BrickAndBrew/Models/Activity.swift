import CloudKit
import Foundation

struct Activity: Identifiable, Sendable, Hashable {
    let id: String
    var stravaId: Int64
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

    static func recordName(userId: String, stravaId: Int64) -> String {
        "activity-\(userId)-\(stravaId)"
    }
}

extension Activity {
    init?(record: CKRecord) {
        guard
            let stravaId = int64(record[CloudKitKey.Activity.stravaId]),
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
        record[CloudKitKey.Activity.stravaId] = stravaId as CKRecordValue
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

private func int64(_ value: Any?) -> Int64? {
    if let number = value as? Int64 { return number }
    if let number = value as? Int { return Int64(number) }
    if let number = value as? Double { return Int64(number) }
    return nil
}

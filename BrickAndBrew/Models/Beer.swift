import CloudKit
import Foundation

struct Beer: Identifiable, Sendable, Hashable {
    let id: String
    var userId: String
    var teamId: String
    var count: Int
    var loggedAt: Date
    var note: String?

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }
}

extension Beer {
    init?(record: CKRecord) {
        guard
            let userId = record[CloudKitKey.Beer.userId] as? String,
            let teamId = record[CloudKitKey.Beer.teamId] as? String,
            let loggedAt = record[CloudKitKey.Beer.loggedAt] as? Date
        else {
            return nil
        }

        id = record.recordID.recordName
        self.userId = userId
        self.teamId = teamId
        if let count = record[CloudKitKey.Beer.count] as? Int {
            self.count = count
        } else if let count = record[CloudKitKey.Beer.count] as? Int64 {
            self.count = Int(count)
        } else {
            self.count = 1
        }
        self.loggedAt = loggedAt
        note = record[CloudKitKey.Beer.note] as? String
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitKey.RecordType.beer, recordID: recordID)
        record[CloudKitKey.Beer.userId] = userId as CKRecordValue
        record[CloudKitKey.Beer.teamId] = teamId as CKRecordValue
        record[CloudKitKey.Beer.count] = count as CKRecordValue
        record[CloudKitKey.Beer.loggedAt] = loggedAt as CKRecordValue
        if let note, note.isEmpty == false {
            record[CloudKitKey.Beer.note] = note as CKRecordValue
        }
        return record
    }
}

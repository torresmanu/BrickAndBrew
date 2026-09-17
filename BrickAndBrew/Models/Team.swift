import CloudKit
import Foundation

struct Team: Identifiable, Sendable, Hashable {
    let id: String
    var inviteCode: String
    var name: String
    var seasonStart: Date

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: "team-\(inviteCode.lowercased())")
    }
}

extension Team {
    init?(record: CKRecord) {
        guard
            let inviteCode = record[CloudKitKey.Team.inviteCode] as? String,
            let name = record[CloudKitKey.Team.name] as? String
        else {
            return nil
        }

        id = record.recordID.recordName
        self.inviteCode = inviteCode
        self.name = name
        seasonStart = record[CloudKitKey.Team.seasonStart] as? Date ?? Date()
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitKey.RecordType.team, recordID: recordID)
        record[CloudKitKey.Team.inviteCode] = inviteCode as CKRecordValue
        record[CloudKitKey.Team.name] = name as CKRecordValue
        record[CloudKitKey.Team.seasonStart] = seasonStart as CKRecordValue
        return record
    }
}

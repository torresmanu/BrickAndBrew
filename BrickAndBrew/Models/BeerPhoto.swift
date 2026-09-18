import CloudKit
import Foundation

struct BeerPhoto: Identifiable, Sendable, Hashable {
    let id: String
    var beerId: String
    var userId: String
    var teamId: String
    var count: Int
    var loggedAt: Date
    var note: String?
    var hasPhoto: Bool = false

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }
}

extension BeerPhoto {
    static func recordName(forBeerId beerId: String) -> String {
        "beerphoto-\(beerId)"
    }

    init(beer: Beer) {
        id = Self.recordName(forBeerId: beer.id)
        beerId = beer.id
        userId = beer.userId
        teamId = beer.teamId
        count = beer.count
        loggedAt = beer.loggedAt
        note = beer.note
        hasPhoto = true
    }

    init?(record: CKRecord) {
        guard
            let beerId = record[CloudKitKey.BeerPhoto.beerId] as? String,
            let userId = record[CloudKitKey.BeerPhoto.userId] as? String,
            let teamId = record[CloudKitKey.BeerPhoto.teamId] as? String,
            let loggedAt = record[CloudKitKey.BeerPhoto.loggedAt] as? Date
        else {
            return nil
        }

        id = record.recordID.recordName
        self.beerId = beerId
        self.userId = userId
        self.teamId = teamId
        self.loggedAt = loggedAt
        if let count = record[CloudKitKey.BeerPhoto.count] as? Int {
            self.count = count
        } else if let count = record[CloudKitKey.BeerPhoto.count] as? Int64 {
            self.count = Int(count)
        } else {
            self.count = 1
        }
        note = record[CloudKitKey.BeerPhoto.note] as? String
        hasPhoto = record[CloudKitKey.BeerPhoto.photo] is CKAsset
    }

    /// Writes caption fields only. Never touches `photo` so a retry cannot wipe the asset.
    func writeScalarFields(to record: CKRecord) {
        record[CloudKitKey.BeerPhoto.beerId] = beerId as CKRecordValue
        record[CloudKitKey.BeerPhoto.userId] = userId as CKRecordValue
        record[CloudKitKey.BeerPhoto.teamId] = teamId as CKRecordValue
        record[CloudKitKey.BeerPhoto.count] = count as CKRecordValue
        record[CloudKitKey.BeerPhoto.loggedAt] = loggedAt as CKRecordValue
        if let note, note.isEmpty == false {
            record[CloudKitKey.BeerPhoto.note] = note as CKRecordValue
        } else {
            record[CloudKitKey.BeerPhoto.note] = nil
        }
    }
}

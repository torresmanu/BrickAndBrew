import CloudKit
import Foundation

@MainActor
final class CloudKitService {
    private let containerIdentifier: String
    private let avatars: AvatarCache
    private let beerPhotos: BeerPhotoCache
    private lazy var container: CKContainer = CKContainer(identifier: containerIdentifier)
    private var database: CKDatabase { container.publicCloudDatabase }

    init(
        containerIdentifier: String = AppConfig.cloudKitContainerID,
        avatars: AvatarCache,
        beerPhotos: BeerPhotoCache
    ) {
        self.containerIdentifier = containerIdentifier
        self.avatars = avatars
        self.beerPhotos = beerPhotos
    }

    func requireICloud() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            throw BrickError.iCloudUnavailable
        }
    }

    func fetchTeam(inviteCode: String) async throws -> Team? {
        try await fetchTeam(recordName: "team-\(inviteCode.lowercased())")
    }

    func fetchTeam(recordName: String) async throws -> Team? {
        let recordID = CKRecord.ID(recordName: recordName)
        do {
            let record = try await database.record(for: recordID)
            return Team(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            throw mapped(error)
        }
    }

    func saveTeam(_ team: Team) async throws -> Team {
        try await save(team.makeRecord())
        return team
    }

    func fetchProfile(appleUserId: String) async throws -> Profile? {
        let recordID = CKRecord.ID(recordName: Profile.recordName(forAppleUserId: appleUserId))
        do {
            let record = try await database.record(for: recordID)
            persistAvatar(from: record)
            return Profile(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            throw mapped(error)
        }
    }

    /// Fetches the existing Profile record (or creates one) so scalar saves keep `avatar`.
    func saveProfile(_ profile: Profile) async throws -> Profile {
        let record = try await mutableProfileRecord(for: profile)
        profile.writeScalarFields(to: record)
        try await saveProfileRecord(record)
        persistAvatar(from: record)
        return Profile(record: record) ?? profile
    }

    func saveProfileAvatar(_ profile: Profile, jpegData: Data) async throws -> Profile {
        let record = try await mutableProfileRecord(for: profile)
        profile.writeScalarFields(to: record)
        let fileURL = try writeTempJPEG(jpegData)
        record[CloudKitKey.Profile.avatar] = CKAsset(fileURL: fileURL)
        do {
            try await saveProfileRecord(record)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }
        try? FileManager.default.removeItem(at: fileURL)
        avatars.store(userId: profile.id, jpeg: jpegData)
        return Profile(record: record) ?? profile
    }

    func removeProfileAvatar(_ profile: Profile) async throws -> Profile {
        let record = try await mutableProfileRecord(for: profile)
        profile.writeScalarFields(to: record)
        record[CloudKitKey.Profile.avatar] = nil
        try await saveProfileRecord(record)
        avatars.remove(userId: profile.id)
        return Profile(record: record) ?? profile
    }

    func fetchProfiles(teamId: String) async throws -> [Profile] {
        let predicate = NSPredicate(format: "%K == %@", CloudKitKey.Profile.teamId, teamId)
        let records = try await query(recordType: CloudKitKey.RecordType.profile, predicate: predicate)
        for record in records {
            persistAvatar(from: record)
        }
        return records.compactMap(Profile.init(record:))
    }

    func fetchActivities(teamId: String, since: Date) async throws -> [Activity] {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@",
            CloudKitKey.Activity.teamId,
            teamId,
            CloudKitKey.Activity.startDate,
            since as NSDate
        )
        let records = try await query(recordType: CloudKitKey.RecordType.activity, predicate: predicate)
        return records.compactMap(Activity.init(record:))
    }

    func upsertActivities(_ activities: [Activity]) async throws {
        guard activities.isEmpty == false else { return }
        let records = activities.map { $0.makeRecord() }
        try await modify(records)
    }

    func fetchBeers(teamId: String, since: Date) async throws -> [Beer] {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@",
            CloudKitKey.Beer.teamId,
            teamId,
            CloudKitKey.Beer.loggedAt,
            since as NSDate
        )
        let records = try await query(recordType: CloudKitKey.RecordType.beer, predicate: predicate)
        return records.compactMap(Beer.init(record:))
    }

    func fetchBeers(userId: String, teamId: String) async throws -> [Beer] {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            CloudKitKey.Beer.userId,
            userId,
            CloudKitKey.Beer.teamId,
            teamId
        )
        let records = try await query(recordType: CloudKitKey.RecordType.beer, predicate: predicate)
        return records
            .compactMap(Beer.init(record:))
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func saveBeer(_ beer: Beer) async throws -> Beer {
        try await save(beer.makeRecord())
        return beer
    }

    func saveBeerPhoto(_ photo: BeerPhoto, jpegData: Data) async throws -> BeerPhoto {
        let record = CKRecord(recordType: CloudKitKey.RecordType.beerPhoto, recordID: photo.recordID)
        photo.writeScalarFields(to: record)
        let fileURL = try writeTempJPEG(jpegData)
        record[CloudKitKey.BeerPhoto.photo] = CKAsset(fileURL: fileURL)
        do {
            try await save(record)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }
        try? FileManager.default.removeItem(at: fileURL)
        beerPhotos.store(beerId: photo.beerId, jpeg: jpegData)
        return BeerPhoto(record: record) ?? photo
    }

    func fetchBeerPhotos(teamId: String, since: Date) async throws -> [BeerPhoto] {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@",
            CloudKitKey.BeerPhoto.teamId,
            teamId,
            CloudKitKey.BeerPhoto.loggedAt,
            since as NSDate
        )
        let sort = [NSSortDescriptor(key: CloudKitKey.BeerPhoto.loggedAt, ascending: false)]
        let records = try await query(
            recordType: CloudKitKey.RecordType.beerPhoto,
            predicate: predicate,
            sortDescriptors: sort
        )
        for record in records {
            persistBeerPhoto(from: record)
        }
        return records.compactMap(BeerPhoto.init(record:))
    }

    func fetchBeerPhotos(userId: String, teamId: String) async throws -> [BeerPhoto] {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            CloudKitKey.BeerPhoto.userId,
            userId,
            CloudKitKey.BeerPhoto.teamId,
            teamId
        )
        let records = try await query(recordType: CloudKitKey.RecordType.beerPhoto, predicate: predicate)
        for record in records {
            persistBeerPhoto(from: record)
        }
        return records
            .compactMap(BeerPhoto.init(record:))
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    /// Removes this user's profile, activities, beers, and pint photos. Does not delete the Team record.
    func deleteAccountRecords(for profile: Profile) async throws {
        let teamId = profile.teamId.isEmpty ? nil : profile.teamId
        async let activityIDs = ownedRecordIDs(
            recordType: CloudKitKey.RecordType.activity,
            userId: profile.id,
            teamId: teamId
        )
        async let beerIDs = ownedRecordIDs(
            recordType: CloudKitKey.RecordType.beer,
            userId: profile.id,
            teamId: teamId
        )
        async let photoIDs = ownedRecordIDs(
            recordType: CloudKitKey.RecordType.beerPhoto,
            userId: profile.id,
            teamId: teamId
        )
        var recordIDs = try await activityIDs + beerIDs + photoIDs
        recordIDs.append(profile.recordID)
        try await delete(recordIDs)
    }

    private func save(_ record: CKRecord) async throws {
        try await modify([record])
    }

    /// `.changedKeys` leaves `avatar` untouched unless this call changed it.
    private func saveProfileRecord(_ record: CKRecord) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: CloudKitService.mapError(error))
                }
            }
            database.add(operation)
        }
    }

    private func mutableProfileRecord(for profile: Profile) async throws -> CKRecord {
        do {
            return try await database.record(for: profile.recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return CKRecord(recordType: CloudKitKey.RecordType.profile, recordID: profile.recordID)
        } catch {
            throw mapped(error)
        }
    }

    /// CloudKit asset URLs are temporary. Copy bytes into the disk cache, but
    /// keep the last file if the asset is present and the download failed.
    private func persistAvatar(from record: CKRecord) {
        let userId = record.recordID.recordName
        guard let asset = record[CloudKitKey.Profile.avatar] as? CKAsset else {
            avatars.remove(userId: userId)
            return
        }
        guard let url = asset.fileURL else { return }
        do {
            let data = try Data(contentsOf: url)
            guard data.isEmpty == false else { return }
            avatars.store(userId: userId, jpeg: data)
        } catch {
            return
        }
    }

    private func persistBeerPhoto(from record: CKRecord) {
        guard let beerId = record[CloudKitKey.BeerPhoto.beerId] as? String else { return }
        guard let asset = record[CloudKitKey.BeerPhoto.photo] as? CKAsset else {
            beerPhotos.remove(beerId: beerId)
            return
        }
        guard let url = asset.fileURL else { return }
        do {
            let data = try Data(contentsOf: url)
            guard data.isEmpty == false else { return }
            beerPhotos.store(beerId: beerId, jpeg: data)
        } catch {
            return
        }
    }

    private func writeTempJPEG(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("upload-\(UUID().uuidString).jpg")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func modify(_ records: [CKRecord]) async throws {
        for chunk in stride(from: 0, to: records.count, by: 400) {
            let slice = Array(records[chunk..<min(chunk + 400, records.count)])
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let operation = CKModifyRecordsOperation(recordsToSave: slice, recordIDsToDelete: nil)
                operation.savePolicy = .allKeys
                operation.qualityOfService = .userInitiated
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: CloudKitService.mapError(error))
                    }
                }
                database.add(operation)
            }
        }
    }

    /// Activity and Beer both store ownership in `userId` / `teamId`.
    private func ownedRecordIDs(recordType: String, userId: String, teamId: String?) async throws -> [CKRecord.ID] {
        let predicate: NSPredicate
        if let teamId {
            predicate = NSPredicate(
                format: "%K == %@ AND %K == %@",
                CloudKitKey.Activity.userId,
                userId,
                CloudKitKey.Activity.teamId,
                teamId
            )
        } else {
            predicate = NSPredicate(format: "%K == %@", CloudKitKey.Activity.userId, userId)
        }
        let records = try await query(recordType: recordType, predicate: predicate)
        return records.map(\.recordID)
    }

    private func delete(_ recordIDs: [CKRecord.ID]) async throws {
        guard recordIDs.isEmpty == false else { return }
        for chunk in stride(from: 0, to: recordIDs.count, by: 400) {
            let slice = Array(recordIDs[chunk..<min(chunk + 400, recordIDs.count)])
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: slice)
                // Allow already-deleted rows so a retry can finish the rest of the account.
                operation.isAtomic = false
                operation.qualityOfService = .userInitiated
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error) where Self.isAlreadyDeleted(error):
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: CloudKitService.mapError(error))
                    }
                }
                database.add(operation)
            }
        }
    }

    private func query(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [CKRecord] {
        var results: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        let first = CKQuery(recordType: recordType, predicate: predicate)
        first.sortDescriptors = sortDescriptors

        do {
            repeat {
                let page: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
                if let cursor {
                    page = try await database.records(continuingMatchFrom: cursor, resultsLimit: AppConfig.cloudKitPageLimit)
                } else {
                    page = try await database.records(matching: first, resultsLimit: AppConfig.cloudKitPageLimit)
                }
                for (_, result) in page.matchResults {
                    if case .success(let record) = result {
                        results.append(record)
                    }
                }
                cursor = page.queryCursor
            } while cursor != nil
            return results
        } catch let error as CKError where Self.isMissingRecordType(error) {
            // No rows of this type exist yet, so CloudKit has not created the record type.
            return []
        } catch {
            throw mapped(error)
        }
    }

    private func mapped(_ error: Error) -> BrickError {
        Self.mapError(error)
    }

    nonisolated static func mapError(_ error: Error) -> BrickError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .network
            case .notAuthenticated:
                return .iCloudUnavailable
            case .invalidArguments:
                return .cloudKit("iCloud indexes are missing. In CloudKit Console, mark teamId, startDate, and loggedAt as Queryable (BeerPhoto.loggedAt also Sortable), then pull to refresh.")
            default:
                return .cloudKit("We couldn't update the crew board. Pull to refresh and try again.")
            }
        }
        return .cloudKit(error.localizedDescription)
    }

    /// CloudKit only materializes a record type after the first save. A query before that
    /// should look like an empty list, not a failed board.
    nonisolated private static func isMissingRecordType(_ error: CKError) -> Bool {
        if error.code == .unknownItem {
            return true
        }
        if error.code == .invalidArguments {
            let text = error.localizedDescription.lowercased()
            return text.contains("did not find record type") || text.contains("unknown record type")
        }
        return false
    }

    nonisolated private static func isAlreadyDeleted(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        if ckError.code == .unknownItem {
            return true
        }
        guard ckError.code == .partialFailure, let partial = ckError.partialErrorsByItemID else {
            return false
        }
        return partial.values.allSatisfy { item in
            (item as? CKError)?.code == .unknownItem
        }
    }
}

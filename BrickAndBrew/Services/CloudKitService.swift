import CloudKit
import Foundation

@MainActor
final class CloudKitService {
    private let containerIdentifier: String
    private lazy var container: CKContainer = CKContainer(identifier: containerIdentifier)
    private var database: CKDatabase { container.publicCloudDatabase }

    init(containerIdentifier: String = AppConfig.cloudKitContainerID) {
        self.containerIdentifier = containerIdentifier
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
            return Profile(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            throw mapped(error)
        }
    }

    func saveProfile(_ profile: Profile) async throws -> Profile {
        try await save(profile.makeRecord())
        return profile
    }

    func fetchProfiles(teamId: String) async throws -> [Profile] {
        let predicate = NSPredicate(format: "%K == %@", CloudKitKey.Profile.teamId, teamId)
        let records = try await query(recordType: CloudKitKey.RecordType.profile, predicate: predicate)
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

    private func save(_ record: CKRecord) async throws {
        try await modify([record])
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

    private func query(recordType: String, predicate: NSPredicate) async throws -> [CKRecord] {
        var results: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        let first = CKQuery(recordType: recordType, predicate: predicate)
        first.sortDescriptors = nil

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
            default:
                return .cloudKit("We couldn't update the crew board. Pull to refresh and try again.")
            }
        }
        return .cloudKit(error.localizedDescription)
    }
}

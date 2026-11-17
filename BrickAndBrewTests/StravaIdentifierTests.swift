import CloudKit
import Foundation
import Testing
@testable import BrickAndBrew

struct StravaIdentifierTests {
    private let wideID = "9007199254740993"
    private let pastSignedInt64 = "9223372036854775808"

    @Test func keepsTheStringWhenTheIntegerWouldRound() throws {
        let dto = try decodeActivity(
            """
            {"id":1,"id_str":"9007199254740993","type":"Run","sport_type":"Run","start_date":"2024-01-02T03:04:05Z"}
            """
        )
        let activity = try #require(ActivityMapper.map(dto, userId: "user-1", teamId: "team-1"))
        #expect(activity.stravaId == wideID)
        #expect(activity.id == "activity-user-1-\(wideID)")
    }

    @Test func acceptsAnIdPastSignedInt64() throws {
        let dto = try decodeActivity(
            """
            {"id_str":"9223372036854775808","type":"Ride","start_date":"2024-01-02T03:04:05Z"}
            """
        )
        #expect(dto.id == pastSignedInt64)
    }

    @Test func readsIdStrWithoutTheSnakeCaseStrategy() throws {
        let json = Data(#"{"id_str":"77","type":"Swim"}"#.utf8)
        let dto = try JSONDecoder().decode(StravaActivityDTO.self, from: json)
        #expect(dto.id == "77")
    }

    @Test func refusesAJSONNumberThatMightHaveBeenRounded() {
        #expect(throws: DecodingError.self) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let json = Data(#"{"id":9007199254740993,"type":"Run"}"#.utf8)
            try decoder.decode(StravaActivityDTO.self, from: json)
        }
    }

    @Test func acceptsTheLargestExactJSONInteger() throws {
        let dto = try decodeActivity(#"{"id":9007199254740991,"type":"Run"}"#)
        #expect(dto.id == "9007199254740991")
    }

    @Test func fallsBackToASmallIntegerId() throws {
        let dto = try decodeActivity(
            """
            {"id":42,"type":"Run","start_date":"2024-01-02T03:04:05Z"}
            """
        )
        #expect(dto.id == "42")
    }

    @Test func stripsLeadingZerosSoRecordNamesStayStable() throws {
        let dto = try decodeActivity(
            """
            {"id":42,"id_str":"00042","type":"Run","start_date":"2024-01-02T03:04:05Z"}
            """
        )
        let activity = try #require(ActivityMapper.map(dto, userId: "user-1", teamId: "team-1"))
        #expect(activity.stravaId == "42")
        #expect(activity.id == "activity-user-1-42")
    }

    @Test func dropsAnActivityWhoseIdIsNotAStravaIdentifier() {
        let dto = StravaActivityDTO(
            id: "0",
            name: nil,
            type: "Run",
            sportType: "Run",
            distance: 1,
            movingTime: 1,
            elapsedTime: 1,
            totalElevationGain: 0,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            averageHeartrate: nil,
            maxHeartrate: nil
        )
        #expect(ActivityMapper.map(dto, userId: "user-1", teamId: "team-1") == nil)
    }

    @Test func rejectsAPayloadWithNoId() {
        #expect(throws: DecodingError.self) {
            try decodeActivity(#"{"type":"Run"}"#)
        }
    }

    @Test func readsTheAthleteIdStringFromTheToken() throws {
        let json = Data(
            """
            {"token_type":"Bearer","expires_at":1700000000,"expires_in":21600,"refresh_token":"refresh","access_token":"access","athlete":{"id":1,"id_str":"\(wideID)","firstname":"Ada","lastname":"Lovelace"}}
            """.utf8
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let token = try decoder.decode(StravaTokenResponse.self, from: json)
        #expect(token.athlete?.id == wideID)
        #expect(token.athlete?.displayName == "Ada Lovelace")
    }

    @Test func readsALegacyNumericAthleteIdFromTheKeychain() throws {
        let json = Data(
            #"{"accessToken":"a","refreshToken":"r","expiresAt":100,"athleteId":42,"athleteName":"Ada"}"#.utf8
        )
        let credentials = try JSONDecoder().decode(StravaCredentials.self, from: json)
        #expect(credentials.athleteId == "42")
        #expect(credentials.athleteName == "Ada")
    }

    @Test func treatsAStoredZeroAthleteIdAsMissing() throws {
        let json = Data(
            #"{"accessToken":"a","refreshToken":"r","expiresAt":100,"athleteId":0,"athleteName":""}"#.utf8
        )
        let credentials = try JSONDecoder().decode(StravaCredentials.self, from: json)
        #expect(credentials.athleteId == "")
    }

    @Test func roundTripsAthleteIdAsAString() throws {
        let original = StravaCredentials(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            athleteId: wideID,
            athleteName: "Ada"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StravaCredentials.self, from: data)
        #expect(decoded == original)
    }

    @Test func readsAnActivitySavedBeforeIdStrings() throws {
        let record = activityRecord(name: "activity-user-1-42")
        record[CloudKitKey.Activity.stravaId] = Int64(42) as CKRecordValue
        let activity = try #require(Activity(record: record))
        #expect(activity.stravaId == "42")
        #expect(activity.id == "activity-user-1-42")
    }

    @Test func prefersTheStringColumnOverAStaleInteger() throws {
        let record = activityRecord(name: "activity-user-1-\(wideID)")
        record[CloudKitKey.Activity.stravaId] = Int64(1) as CKRecordValue
        record[CloudKitKey.Activity.stravaIdString] = wideID as CKRecordValue
        let activity = try #require(Activity(record: record))
        #expect(activity.stravaId == wideID)
    }

    @Test func keepsInt64MaxOnTheIntegerColumn() {
        let record = sampleActivity(stravaId: "9223372036854775807").makeRecord()
        #expect(record[CloudKitKey.Activity.stravaId] as? Int64 == Int64.max)
        #expect(record[CloudKitKey.Activity.stravaIdString] == nil)
    }

    @Test func writesTheIntegerColumnWhenTheIdFitsInInt64() {
        let record = sampleActivity(stravaId: "42").makeRecord()
        #expect(record[CloudKitKey.Activity.stravaId] as? Int64 == 42)
        #expect(record[CloudKitKey.Activity.stravaIdString] == nil)
    }

    @Test func skipsTheIntegerColumnWhenTheIdDoesNotFit() {
        let record = sampleActivity(stravaId: pastSignedInt64).makeRecord()
        #expect(record[CloudKitKey.Activity.stravaId] == nil)
        #expect(record[CloudKitKey.Activity.stravaIdString] as? String == pastSignedInt64)
    }

    @Test func keepsALegacyAthleteIdOnTheIntegerColumn() throws {
        let record = profileRecord()
        record[CloudKitKey.Profile.stravaAthleteId] = Int64(99) as CKRecordValue
        var profile = try #require(Profile(record: record))
        #expect(profile.stravaAthleteId == "99")
        #expect(profile.isStravaConnected)

        profile.writeScalarFields(to: record)
        #expect(record[CloudKitKey.Profile.stravaAthleteId] as? Int64 == 99)
        #expect(record[CloudKitKey.Profile.stravaAthleteIdString] == nil)

        profile.stravaAthleteId = nil
        profile.writeScalarFields(to: record)
        #expect(record[CloudKitKey.Profile.stravaAthleteId] == nil)
        #expect(profile.isStravaConnected == false)
    }

    @Test func storesAnAthleteIdThatDoesNotFitInInt64() throws {
        let record = profileRecord()
        record[CloudKitKey.Profile.stravaAthleteId] = Int64(7) as CKRecordValue
        var profile = try #require(Profile(record: record))
        profile.stravaAthleteId = pastSignedInt64
        profile.writeScalarFields(to: record)
        #expect(record[CloudKitKey.Profile.stravaAthleteId] == nil)
        #expect(record[CloudKitKey.Profile.stravaAthleteIdString] as? String == pastSignedInt64)
        let saved = try #require(Profile(record: record))
        #expect(saved.stravaAthleteId == pastSignedInt64)
        #expect(saved.isStravaConnected)
    }

    private func decodeActivity(_ json: String) throws -> StravaActivityDTO {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StravaActivityDTO.self, from: Data(json.utf8))
    }

    private func activityRecord(name: String) -> CKRecord {
        let record = CKRecord(recordType: CloudKitKey.RecordType.activity, recordID: CKRecord.ID(recordName: name))
        record[CloudKitKey.Activity.userId] = "user-1" as CKRecordValue
        record[CloudKitKey.Activity.teamId] = "team-1" as CKRecordValue
        record[CloudKitKey.Activity.type] = "Run" as CKRecordValue
        record[CloudKitKey.Activity.startDate] = Date(timeIntervalSince1970: 1_700_000_000) as CKRecordValue
        return record
    }

    private func profileRecord() -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitKey.RecordType.profile,
            recordID: CKRecord.ID(recordName: "profile-1")
        )
        record[CloudKitKey.Profile.appleUserId] = "apple" as CKRecordValue
        record[CloudKitKey.Profile.displayName] = "Ada" as CKRecordValue
        record[CloudKitKey.Profile.teamId] = "team-1" as CKRecordValue
        return record
    }

    private func sampleActivity(stravaId: String) -> Activity {
        Activity(
            id: Activity.recordName(userId: "user-1", stravaId: stravaId),
            stravaId: stravaId,
            userId: "user-1",
            teamId: "team-1",
            type: "Run",
            sport: .run,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            distanceMeters: 1_000,
            movingTimeSeconds: 300,
            averageHeartrate: nil,
            maxHeartrate: nil,
            elevationGain: nil
        )
    }
}

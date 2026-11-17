import CloudKit
import Foundation

/// Strava activity and athlete ids.
///
/// After 1 June 2027 those ids are 64-bit. JSON numbers are only exact through
/// 2^53, so Strava also sends `id_str`. That string is the id we keep.
enum StravaObjectID {
    /// Decimal form of an unsigned 64-bit id. Zero, signs, and overflow are rejected.
    /// Leading zeros collapse so `00042` and `42` stay one CloudKit record.
    static func objectID(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let magnitude = UInt64(trimmed), magnitude > 0 else { return nil }
        return String(magnitude)
    }

    /// Reads `id_str` first, then `id`, from an activity or athlete payload.
    static func decode(from decoder: Decoder) throws -> String {
        let container = try decoder.container(keyedBy: Key.self)
        if let raw = string(in: container, keys: ["idStr", "id_str"]), let identifier = objectID(raw) {
            return identifier
        }
        // Payloads from before `id_str` only contain a small integer `id`.
        if let identifier = integerID(in: container, keys: ["id"]) {
            return identifier
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Strava id is missing or is not a 64-bit identifier."
            )
        )
    }

    /// Keychain JSON used to store `athleteId` as a number. Empty means the token had no athlete.
    static func decodeStored<CodingKeyType: CodingKey>(
        from container: KeyedDecodingContainer<CodingKeyType>,
        forKey key: CodingKeyType
    ) throws -> String {
        guard container.contains(key) else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Missing athlete id.")
            )
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            if raw.isEmpty { return "" }
            guard let identifier = objectID(raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: container,
                    debugDescription: "Athlete id must be a decimal string."
                )
            }
            return identifier
        }
        if let signed = try? container.decode(Int64.self, forKey: key) {
            if signed == 0 { return "" }
            if signed > 0 { return String(signed) }
        }
        if let unsigned = try? container.decode(UInt64.self, forKey: key), let identifier = objectID(String(unsigned)) {
            return identifier
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Athlete id must be a 64-bit identifier."
        )
    }

    /// Prefer the string column. Fall back to the original INT64 column for records saved before this change.
    static func read(from record: CKRecord, integerField: String, stringField: String) -> String? {
        if let stored = record[stringField] as? String, let identifier = objectID(stored) {
            return identifier
        }
        guard let signed = positiveInt64(record[integerField]) else { return nil }
        return String(signed)
    }

    /// Writes the id into the existing INT64 column when it fits.
    /// The string column is only used past `Int64.max`, so today's production
    /// schema keeps accepting saves. Add that column before Strava issues wider ids.
    static func write(
        _ identifier: String?,
        to record: CKRecord,
        integerField: String,
        stringField: String
    ) {
        guard let identifier, let canonical = objectID(identifier) else {
            clear(integerField, on: record)
            clear(stringField, on: record)
            return
        }
        if let signed = Int64(canonical) {
            assign(signed as CKRecordValue, to: integerField, on: record)
            clear(stringField, on: record)
        } else {
            assign(canonical as CKRecordValue, to: stringField, on: record)
            clear(integerField, on: record)
        }
    }

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        init?(intValue: Int) {
            nil
        }
    }

    private static func string(in container: KeyedDecodingContainer<Key>, keys: [String]) -> String? {
        for name in keys {
            guard let key = Key(stringValue: name), container.contains(key) else { continue }
            if let value = try? container.decode(String.self, forKey: key) {
                return value
            }
        }
        return nil
    }

    /// A JSON number is only exact through 2^53 - 1. Larger values have to come from `id_str`.
    private static let maxExactJSONInteger: UInt64 = 9_007_199_254_740_991

    private static func integerID(in container: KeyedDecodingContainer<Key>, keys: [String]) -> String? {
        for name in keys {
            guard let key = Key(stringValue: name), container.contains(key) else { continue }
            if let raw = try? container.decode(String.self, forKey: key), let identifier = objectID(raw) {
                return identifier
            }
            if let unsigned = try? container.decode(UInt64.self, forKey: key),
               unsigned > 0,
               unsigned <= maxExactJSONInteger {
                return String(unsigned)
            }
            if let signed = try? container.decode(Int64.self, forKey: key),
               signed > 0,
               UInt64(signed) <= maxExactJSONInteger {
                return String(signed)
            }
        }
        return nil
    }

    /// CloudKit INT64 values bridge as integers. Doubles are ignored so a rounded id is never stored.
    private static func positiveInt64(_ value: Any?) -> Int64? {
        if let number = value as? Int64, number > 0 { return number }
        if let number = value as? Int, number > 0 { return Int64(number) }
        return nil
    }

    private static func assign(_ value: any CKRecordValue, to field: String, on record: CKRecord) {
        record[field] = value
    }

    /// A brand-new record has no legacy column to delete. Clearing only an existing value avoids a tombstone.
    private static func clear(_ field: String, on record: CKRecord) {
        guard record[field] != nil else { return }
        record[field] = nil
    }
}

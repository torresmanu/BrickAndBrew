import Foundation
import Security

enum KeychainStore {
    private static let service = "com.brickandbrew.app"

    enum Account: String {
        case appleUserId
        case stravaCredentials
    }

    static func string(for account: Account) throws -> String? {
        guard let data = try data(for: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func set(_ value: String, for account: Account) throws {
        guard let data = value.data(using: .utf8) else {
            throw BrickError.keychain
        }
        try set(data, for: account)
    }

    static func set<T: Encodable>(_ value: T, for account: Account) throws {
        let data = try JSONEncoder().encode(value)
        try set(data, for: account)
    }

    static func decode<T: Decodable>(_ type: T.Type, for account: Account) throws -> T? {
        guard let data = try data(for: account) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    static func delete(_ account: Account) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BrickError.keychain
        }
    }

    static func clearSession() throws {
        try delete(.appleUserId)
        try delete(.stravaCredentials)
    }

    private static func data(for account: Account) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw BrickError.keychain
        }
        return item as? Data
    }

    private static func set(_ data: Data, for account: Account) throws {
        try delete(account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BrickError.keychain
        }
    }
}

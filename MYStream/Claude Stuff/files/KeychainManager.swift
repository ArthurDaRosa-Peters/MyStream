import Foundation
import Security

// MARK: - KeychainManager
final class KeychainManager {

    static let shared = KeychainManager()
    private init() {}

    private let service = "de.mystream.app"
    private let tokenKey = "session_token"
    private let usernameKey = "username"

    // MARK: - Token
    func saveToken(_ token: String) {
        save(key: tokenKey, value: token)
    }

    func readToken() -> String? {
        read(key: tokenKey)
    }

    func deleteToken() {
        delete(key: tokenKey)
    }

    // MARK: - Username
    func saveUsername(_ username: String) {
        save(key: usernameKey, value: username)
    }

    func readUsername() -> String? {
        read(key: usernameKey)
    }

    // MARK: - Clear All (Logout)
    func clearAll() {
        delete(key: tokenKey)
        delete(key: usernameKey)
    }

    // MARK: - Private Helpers
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Erst löschen, falls bereits vorhanden
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

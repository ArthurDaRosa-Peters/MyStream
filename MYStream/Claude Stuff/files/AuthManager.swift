import Foundation
import SwiftUI

// MARK: - AuthManager
@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()
    private init() {}

    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""

    /// Beim App-Start prüfen ob ein gespeicherter Token vorhanden ist
    func checkExistingSession() {
        if let token = KeychainManager.shared.readToken(), !token.isEmpty {
            isLoggedIn = true
            username = KeychainManager.shared.readUsername() ?? ""
        } else {
            isLoggedIn = false
        }
    }

    /// Login durchführen und Token speichern
    func login(username: String, password: String) async throws {
        let response = try await APIClient.shared.login(username: username, password: password)
        KeychainManager.shared.saveToken(response.token)
        KeychainManager.shared.saveUsername(response.username)
        self.username = response.username
        isLoggedIn = true
    }

    /// Logout: Token löschen und zur Login-View zurückkehren
    func logout() {
        KeychainManager.shared.clearAll()
        isLoggedIn = false
        username = ""
    }
}

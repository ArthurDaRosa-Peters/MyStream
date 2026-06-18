import Foundation
import SwiftUI
internal import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func login() async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Bitte Benutzername und Passwort eingeben."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await AuthManager.shared.login(username: username, password: password)
        } catch let apiError as APIError {
            errorMessage = apiError.errorDescription
        } catch {
            errorMessage = "Unbekannter Fehler."
        }
        isLoading = false
    }

    func loginAsGuest() async {
        // Test-Button: Kein echter Login, direkt weiterleiten
        // Wir setzen einen Dummy-Token damit ContentView den richtigen Screen zeigt
        KeychainManager.shared.saveToken("test_mode")
        KeychainManager.shared.saveUsername("Gast")
        await AuthManager.shared.checkExistingSession()
    }
}

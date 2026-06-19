import Foundation
import CoreData
import SwiftUI
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var animes: [CDAnime] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let cdManager = CoreDataManager.shared

    // MARK: - Load
    func loadFromServer() async {
        isLoading = true
        errorMessage = nil
        do {
            let homeResponse = try await APIClient.shared.fetchHome()
            // Alle vom Home-Endpunkt gelieferten Listen synchronisieren.
            cdManager.syncAnimes(homeResponse.allSyncedAnimes)
            animes = cdManager.fetchAllAnimes()
        } catch let apiError as APIError {
            errorMessage = apiError.errorDescription
            // Fallback: zeige was bereits in CoreData ist
            animes = cdManager.fetchAllAnimes()
        } catch {
            errorMessage = "Unbekannter Fehler."
            animes = cdManager.fetchAllAnimes()
        }
        isLoading = false
    }

    // MARK: - Watchlist Toggle
    func toggleWatchlist(anime: CDAnime) async {
        do {
            let response = try await APIClient.shared.toggleWatchlist(animeId: Int(anime.id))
            cdManager.updateWatchlist(animeId: anime.id, isOnWatchlist: response.onWatchlist)
            animes = cdManager.fetchAllAnimes()
        } catch {
            print("Watchlist Toggle Fehler: \(error)")
        }
    }
}

import Foundation
import CoreData

@MainActor
final class DownloadsViewModel: ObservableObject {

    @Published var downloadedAnimes: [CDAnime] = []

    private let cdManager = CoreDataManager.shared

    // MARK: - Load (nur CoreData, kein Netzwerk)
    func load() {
        downloadedAnimes = cdManager.fetchDownloadedAnimes()
    }

    // MARK: - Refresh after download completes
    func refresh() {
        load()
    }
}

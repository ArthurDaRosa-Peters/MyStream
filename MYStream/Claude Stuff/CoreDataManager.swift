import Foundation
import CoreData

// MARK: - CoreDataManager
final class CoreDataManager {

    static let shared = CoreDataManager()
    private init() {}

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MYStream")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData Store konnte nicht geladen werden: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Save
    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData Save Error: \(error)")
        }
    }

    // MARK: - Sync Animes from API
    /// Aktualisiert oder erstellt CDAnime-Objekte anhand der API-Antwort
    func syncAnimes(_ animes: [Anime]) {
        for anime in animes {
            let cdAnime = fetchOrCreateAnime(id: Int64(anime.id))
            cdAnime.id            = Int64(anime.id)
            cdAnime.title         = anime.title
            cdAnime.summary       = anime.summary
            cdAnime.coverURL      = anime.coverPath
            cdAnime.isNew         = anime.isNew
            cdAnime.isOnWatchlist = anime.isOnWatchlist
            cdAnime.isAvailable   = anime.isAvailable
            cdAnime.isFinished    = anime.isFinished
            cdAnime.hasSub        = anime.hasSub
            cdAnime.hasDub        = anime.hasDub
            cdAnime.genreList     = anime.genreList
            cdAnime.dateAdded     = anime.dateAdded
            cdAnime.episodeCount  = Int16(anime.episodeCount)

            // Episoden synchronisieren
            syncEpisodes(anime.decodedEpisodes(), for: cdAnime)
        }
        save()
    }

    // MARK: - Sync Episodes
    private func syncEpisodes(_ episodes: [Episode], for cdAnime: CDAnime) {
        for episode in episodes {
            let cdEpisode = fetchOrCreateEpisode(id: Int64(episode.id))
            cdEpisode.id            = Int64(episode.id)
            cdEpisode.episodeNumber = Int16(episode.episodeNumber)
            cdEpisode.seasonNumber  = Int16(episode.seasonNumber)
            cdEpisode.title         = nil // kein title-Feld im Backend
            cdEpisode.duration      = episode.duration
            cdEpisode.progress      = episode.progress
            cdEpisode.completed     = episode.completed
            cdEpisode.isAvailable   = episode.isAvailable
            cdEpisode.isNew         = episode.isNew
            // localFileURL und isDownloaded werden NICHT überschrieben
            cdEpisode.anime         = cdAnime
        }
    }

    // MARK: - Fetch Helpers
    private func fetchOrCreateAnime(id: Int64) -> CDAnime {
        let request: NSFetchRequest<CDAnime> = CDAnime.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        return (try? context.fetch(request).first) ?? CDAnime(context: context)
    }

    private func fetchOrCreateEpisode(id: Int64) -> CDEpisode {
        let request: NSFetchRequest<CDEpisode> = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        return (try? context.fetch(request).first) ?? CDEpisode(context: context)
    }

    // MARK: - Fetch Downloaded Animes
    /// Gibt alle Animes zurück, die mindestens eine heruntergeladene Episode haben
    func fetchDownloadedAnimes() -> [CDAnime] {
        let request: NSFetchRequest<CDAnime> = CDAnime.fetchRequest()
        request.predicate = NSPredicate(format: "ANY episodes.isDownloaded == true")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Fetch All Animes
    func fetchAllAnimes() -> [CDAnime] {
        let request: NSFetchRequest<CDAnime> = CDAnime.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Update Episode Download State
    func setEpisodeDownloaded(id: Int64, localURL: String) {
        let request: NSFetchRequest<CDEpisode> = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        guard let episode = try? context.fetch(request).first else { return }
        episode.isDownloaded  = true
        episode.localFileURL  = localURL
        save()
    }

    func setEpisodeDownloadFailed(id: Int64) {
        let request: NSFetchRequest<CDEpisode> = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        guard let episode = try? context.fetch(request).first else { return }
        episode.isDownloaded = false
        episode.localFileURL = nil
        save()
    }

    // MARK: - Update Progress
    func updateProgress(episodeId: Int64, progress: Double, completed: Bool) {
        let request: NSFetchRequest<CDEpisode> = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", episodeId)
        guard let episode = try? context.fetch(request).first else { return }
        episode.progress  = progress
        episode.completed = completed
        save()
    }

    // MARK: - Update Watchlist
    func updateWatchlist(animeId: Int64, isOnWatchlist: Bool) {
        let request: NSFetchRequest<CDAnime> = CDAnime.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", animeId)
        guard let anime = try? context.fetch(request).first else { return }
        anime.isOnWatchlist = isOnWatchlist
        save()
    }
}

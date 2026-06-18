import Foundation

// MARK: - Home Response
// recent und watchlist können null sein → Optional mit Fallback []
struct HomeResponse: Decodable {
    let recent: [Anime]?
    let watchlist: [Anime]?
    let all: [Anime]

    var recentAnimes: [Anime]   { recent   ?? [] }
    var watchlistAnimes: [Anime] { watchlist ?? [] }
}

// MARK: - Anime
struct Anime: Decodable, Identifiable {
    let id: Int
    let title: String
    let summary: String
    let coverPath: String
    let episodeCount: Int
    let isNew: Bool
    let isOnWatchlist: Bool
    let isAvailable: Bool
    let isFinished: Bool
    let hasSub: Bool
    let hasDub: Bool
    let genreList: String
    let dateAdded: String
    let episodesJson: String

    enum CodingKeys: String, CodingKey {
        case id            = "ID"
        case title         = "Title"
        case summary       = "Summary"
        case coverPath     = "CoverPath"
        case episodeCount  = "EpisodeCount"
        case isNew         = "IsNew"
        case isOnWatchlist = "IsOnWatchlist"
        case isAvailable   = "IsAvailable"
        case isFinished    = "IsFinished"
        case hasSub        = "HasSub"
        case hasDub        = "HasDub"
        case genreList     = "GenreList"
        case dateAdded     = "DateAdded"
        case episodesJson  = "EpisodesJson"
    }

    /// Parst das verschachtelte EpisodesJson-Feld in ein Array von Episode-Objekten
    func decodedEpisodes() -> [Episode] {
        guard !episodesJson.isEmpty,
              let data = episodesJson.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([Episode].self, from: data)) ?? []
    }
}

// MARK: - Login Response
struct LoginResponse: Decodable {
    let token: String
    let username: String
}

// MARK: - Watchlist Toggle Response
struct WatchlistResponse: Decodable {
    let onWatchlist: Bool

    enum CodingKeys: String, CodingKey {
        case onWatchlist = "on_watchlist"
    }
}

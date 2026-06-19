import Foundation

// MARK: - Home Response
struct HomeResponse: Decodable {
    let recent: [Anime]?
    let watchlist: [Anime]?
    let all: [Anime]

    var recentAnimes: [Anime]   { recent   ?? [] }
    var watchlistAnimes: [Anime] { watchlist ?? [] }
    var allSyncedAnimes: [Anime] {
        var seenIDs = Set<Int>()
        return (all + recentAnimes + watchlistAnimes).filter { anime in
            seenIDs.insert(anime.id).inserted
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)
        recent = try container.decodeArrayIfPresent([Anime].self, forKeys: "recent", "Recent")
        watchlist = try container.decodeArrayIfPresent([Anime].self, forKeys: "watchlist", "Watchlist")
        all = try container.decodeArrayIfPresent([Anime].self, forKeys: "all", "All") ?? []
    }
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
    private let episodes: [Episode]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)

        id = try container.decodeInt(forKeys: "ID", "id")
        title = try container.decodeString(forKeys: "Title", "title")
        summary = try container.decodeStringIfPresent(forKeys: "Summary", "summary") ?? ""
        coverPath = try container.decodeStringIfPresent(forKeys: "CoverPath", "coverPath", "cover_path") ?? ""
        episodeCount = try container.decodeIntIfPresent(forKeys: "EpisodeCount", "episodeCount", "episode_count") ?? 0
        isNew = try container.decodeBoolIfPresent(forKeys: "IsNew", "isNew", "is_new") ?? false
        isOnWatchlist = try container.decodeBoolIfPresent(forKeys: "IsOnWatchlist", "isOnWatchlist", "is_on_watchlist") ?? false
        isAvailable = try container.decodeBoolIfPresent(forKeys: "IsAvailable", "isAvailable", "is_available") ?? true
        isFinished = try container.decodeBoolIfPresent(forKeys: "IsFinished", "isFinished", "is_finished") ?? false
        hasSub = try container.decodeBoolIfPresent(forKeys: "HasSub", "hasSub", "has_sub") ?? false
        hasDub = try container.decodeBoolIfPresent(forKeys: "HasDub", "hasDub", "has_dub") ?? false
        genreList = try container.decodeStringIfPresent(forKeys: "GenreList", "genreList", "genre_list") ?? ""
        dateAdded = try container.decodeStringIfPresent(forKeys: "DateAdded", "dateAdded", "date_added") ?? ""
        episodesJson = try container.decodeStringIfPresent(forKeys: "EpisodesJson", "episodesJson", "episodes_json") ?? ""
        episodes = try container.decodeArrayIfPresent([Episode].self, forKeys: "Episodes", "episodes") ?? Self.decodeEpisodes(from: episodesJson)
    }

    /// Parst das verschachtelte EpisodesJson-Feld in ein Array von Episode-Objekten
    func decodedEpisodes() -> [Episode] {
        if !episodes.isEmpty { return episodes }
        return Self.decodeEpisodes(from: episodesJson)
    }

    private static func decodeEpisodes(from json: String) -> [Episode] {
        let trimmedJson = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedJson.isEmpty,
              let data = trimmedJson.data(using: .utf8) else { return [] }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)
        onWatchlist = try container.decodeBool(forKeys: "on_watchlist", "onWatchlist", "OnWatchlist")
    }
}

struct FlexibleCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == FlexibleCodingKey {
    func decodeArrayIfPresent<T: Decodable>(_ type: T.Type, forKeys keys: String...) throws -> T? {
        try decodeIfPresent(type, keyNames: keys)
    }

    func decodeString(forKeys keys: String...) throws -> String {
        guard let value = try decodeStringIfPresent(keyNames: keys) else {
            throw DecodingError.keyNotFound(
                FlexibleCodingKey(stringValue: keys.first ?? "")!,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Missing required string for keys: \(keys.joined(separator: ", "))")
            )
        }
        return value
    }

    func decodeStringIfPresent(forKeys keys: String...) throws -> String? {
        try decodeStringIfPresent(keyNames: keys)
    }

    private func decodeStringIfPresent(keyNames keys: [String]) throws -> String? {
        if let value = try decodeIfPresent(String.self, keyNames: keys) {
            return value
        }
        if let intValue = try decodeIfPresent(Int.self, keyNames: keys) {
            return String(intValue)
        }
        if let doubleValue = try decodeIfPresent(Double.self, keyNames: keys) {
            return String(doubleValue)
        }
        return nil
    }

    func decodeInt(forKeys keys: String...) throws -> Int {
        guard let value = try decodeIntIfPresent(keyNames: keys) else {
            throw DecodingError.keyNotFound(
                FlexibleCodingKey(stringValue: keys.first ?? "")!,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Missing required integer for keys: \(keys.joined(separator: ", "))")
            )
        }
        return value
    }

    func decodeIntIfPresent(forKeys keys: String...) throws -> Int? {
        try decodeIntIfPresent(keyNames: keys)
    }

    private func decodeIntIfPresent(keyNames keys: [String]) throws -> Int? {
        if let value = try decodeIfPresent(Int.self, keyNames: keys) {
            return value
        }
        if let stringValue = try decodeIfPresent(String.self, keyNames: keys), let value = Int(stringValue) {
            return value
        }
        return nil
    }

    func decodeDoubleIfPresent(forKeys keys: String...) throws -> Double? {
        if let value = try decodeIfPresent(Double.self, keyNames: keys) {
            return value
        }
        if let intValue = try decodeIfPresent(Int.self, keyNames: keys) {
            return Double(intValue)
        }
        if let stringValue = try decodeIfPresent(String.self, keyNames: keys), let value = Double(stringValue) {
            return value
        }
        return nil
    }

    func decodeBool(forKeys keys: String...) throws -> Bool {
        guard let value = try decodeBoolIfPresent(keyNames: keys) else {
            throw DecodingError.keyNotFound(
                FlexibleCodingKey(stringValue: keys.first ?? "")!,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Missing required boolean for keys: \(keys.joined(separator: ", "))")
            )
        }
        return value
    }

    func decodeBoolIfPresent(forKeys keys: String...) throws -> Bool? {
        try decodeBoolIfPresent(keyNames: keys)
    }

    private func decodeBoolIfPresent(keyNames keys: [String]) throws -> Bool? {
        if let value = try decodeIfPresent(Bool.self, keyNames: keys) {
            return value
        }
        if let intValue = try decodeIfPresent(Int.self, keyNames: keys) {
            return intValue != 0
        }
        if let stringValue = try decodeIfPresent(String.self, keyNames: keys) {
            switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes":
                return true
            case "false", "0", "no":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    private func decodeIfPresent<T: Decodable>(_ type: T.Type, keyNames keys: [String]) throws -> T? {
        for keyName in keys {
            guard let key = FlexibleCodingKey(stringValue: keyName), contains(key) else { continue }
            return try decodeIfPresent(type, forKey: key)
        }
        return nil
    }
}

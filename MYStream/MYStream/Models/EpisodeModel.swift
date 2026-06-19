import Foundation

// MARK: - Episode
struct Episode: Decodable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let duration: Double
    let progress: Double        // nullable im Backend → Optional mit Fallback 0
    let completed: Bool         // kommt als null oder 0/1 → custom decoding
    let isAvailable: Bool       // kommt als Integer 0/1 → custom decoding
    let isNew: Bool             // kommt als Integer 0/1 → custom decoding

    // Custom Decoder: behandelt null-Felder und Int-als-Bool
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)

        id = try container.decodeInt(forKeys: "id", "ID")
        episodeNumber = try container.decodeInt(forKeys: "episode_number", "episodeNumber", "EpisodeNumber")
        seasonNumber = try container.decodeIntIfPresent(forKeys: "season_number", "seasonNumber", "SeasonNumber") ?? 1
        duration = try container.decodeDoubleIfPresent(forKeys: "duration", "Duration") ?? 0.0
        progress = try container.decodeDoubleIfPresent(forKeys: "progress", "Progress") ?? 0.0
        completed = try container.decodeBoolIfPresent(forKeys: "completed", "Completed") ?? false
        isAvailable = try container.decodeBoolIfPresent(forKeys: "is_available", "isAvailable", "IsAvailable") ?? true
        isNew = try container.decodeBoolIfPresent(forKeys: "is_new", "isNew", "IsNew") ?? false
    }
}

// MARK: - Progress Update Request Body
struct ProgressUpdate: Encodable {
    let episodeId: Int
    let position: Double
    let duration: Double

    enum CodingKeys: String, CodingKey {
        case episodeId = "episode_id"
        case position  = "position"
        case duration  = "duration"
    }
}

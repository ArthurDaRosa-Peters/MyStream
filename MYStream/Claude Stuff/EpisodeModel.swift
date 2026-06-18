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

    enum CodingKeys: String, CodingKey {
        case id            = "id"
        case episodeNumber = "episode_number"
        case seasonNumber  = "season_number"
        case duration      = "duration"
        case progress      = "progress"
        case completed     = "completed"
        case isAvailable   = "is_available"
        case isNew         = "is_new"
    }

    // Custom Decoder: behandelt null-Felder und Int-als-Bool
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id            = try c.decode(Int.self, forKey: .id)
        episodeNumber = try c.decode(Int.self, forKey: .episodeNumber)
        seasonNumber  = try c.decode(Int.self, forKey: .seasonNumber)
        duration      = (try? c.decodeIfPresent(Double.self, forKey: .duration)) ?? 0.0

        // progress kommt als null → Fallback 0.0
        progress  = (try? c.decodeIfPresent(Double.self, forKey: .progress)) ?? 0.0

        // completed kommt als null oder Int (0/1)
        if let boolVal = try? c.decodeIfPresent(Bool.self, forKey: .completed) {
            completed = boolVal ?? false
        } else if let intVal = try? c.decodeIfPresent(Int.self, forKey: .completed) {
            completed = (intVal ?? 0) != 0
        } else {
            completed = false
        }

        // is_available kommt als Int (0/1)
        if let boolVal = try? c.decodeIfPresent(Bool.self, forKey: .isAvailable) {
            isAvailable = boolVal ?? false
        } else if let intVal = try? c.decodeIfPresent(Int.self, forKey: .isAvailable) {
            isAvailable = (intVal ?? 0) != 0
        } else {
            isAvailable = false
        }

        // is_new kommt als Int (0/1)
        if let boolVal = try? c.decodeIfPresent(Bool.self, forKey: .isNew) {
            isNew = boolVal ?? false
        } else if let intVal = try? c.decodeIfPresent(Int.self, forKey: .isNew) {
            isNew = (intVal ?? 0) != 0
        } else {
            isNew = false
        }
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

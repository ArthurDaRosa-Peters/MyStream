import Foundation

// MARK: - Episode
struct Episode: Decodable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let title: String
    let duration: Double
    let progress: Double
    let completed: Bool
    let isAvailable: Bool
    let isNew: Bool

    enum CodingKeys: String, CodingKey {
        case id            = "id"
        case episodeNumber = "episode_number"
        case seasonNumber  = "season_number"
        case title         = "title"
        case duration      = "duration"
        case progress      = "progress"
        case completed     = "completed"
        case isAvailable   = "is_available"
        case isNew         = "is_new"
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

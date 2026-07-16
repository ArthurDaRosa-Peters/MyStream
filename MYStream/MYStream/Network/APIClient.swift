import Foundation

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int)
    case decodingError(String)
    case noNetwork

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Ungültige URL."
        case .unauthorized:      return "Nicht autorisiert. Bitte erneut einloggen."
        case .serverError(let c): return "Serverfehler: \(c)"
        case .decodingError(let message): return "Antwort konnte nicht verarbeitet werden: \(message)"
        case .noNetwork:         return "Keine Netzwerkverbindung."
        }
    }
}

// MARK: - APIClient
final class APIClient {

    static let shared = APIClient()
    private init() {}

    private let baseURL = "http://172.18.7.244:8080"

    // MARK: - Generic Request
    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        contentType: String = "application/json",
        requiresAuth: Bool = true
    ) async throws -> T {

        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            if let token = KeychainManager.shared.readToken() {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = body {
            req.httpBody = body
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.noNetwork
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.noNetwork }

        switch http.statusCode {
        case 200...299: break
        case 401:       throw APIError.unauthorized
        default:        throw APIError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error for \(path): \(error)")
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Login
    /// Sendet username + password als Form-Data und erhält Token + Username zurück
    func login(username: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: baseURL + "/login") else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = "username=\(username)&password=\(password)"
        req.httpBody = body.data(using: .utf8)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.noNetwork
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.noNetwork }

        switch http.statusCode {
        case 200...299: break
        case 401:       throw APIError.unauthorized
        default:        throw APIError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(LoginResponse.self, from: data)
        } catch {
            print("Login decoding error: \(error)")
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Home
    /// Lädt alle Anime-Daten vom Server (recent, watchlist, all)
    func fetchHome() async throws -> HomeResponse {
        return try await request(path: "/api/app/home")
    }

    // MARK: - Watchlist Toggle
    /// Toggled den Watchlist-Status eines Animes
    func toggleWatchlist(animeId: Int) async throws -> WatchlistResponse {
        let body = try JSONEncoder().encode(["anime_id": animeId])
        return try await request(path: "/api/watchlist/toggle", method: "POST", body: body)
    }

    // MARK: - Progress Update
    /// Speichert den Wiedergabefortschritt einer Episode
    func updateProgress(episodeId: Int, position: Double, duration: Double) async throws {
        let update = ProgressUpdate(episodeId: episodeId, position: position, duration: duration)
        let body = try JSONEncoder().encode(update)
        let _: [Episode] = try await request(path: "/api/progress", method: "POST", body: body)
    }

    // MARK: - Video URL
    /// Gibt die Stream-URL für eine Episode zurück (für AVPlayer oder Download)
    func videoURL(episodeId: Int) -> URL? {
        guard let token = KeychainManager.shared.readToken() else { return nil }
        // Token als Query-Parameter, da AVPlayer keine Custom Headers unterstützt
        return URL(string: "\(baseURL)/video?id=\(episodeId)&token=\(token)")
    }

    // MARK: - Network Check
    /// Schneller Erreichbarkeitscheck gegen den Home-Endpunkt
    func isServerReachable() async -> Bool {
        guard let url = URL(string: baseURL + "/login") else { return false }
        var req = URLRequest(url: url, timeoutInterval: 3)
        req.httpMethod = "HEAD"
        return (try? await URLSession.shared.data(for: req)) != nil
    }
}

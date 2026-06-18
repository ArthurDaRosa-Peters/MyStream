import Foundation
internal import Combine

// MARK: - Download State
enum DownloadState: Equatable {
    case idle
    case downloading(progress: Double)
    case done
    case failed
}

// MARK: - DownloadManager
@MainActor
final class DownloadManager: NSObject, ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    

    static let shared = DownloadManager()

    // episodeId -> DownloadState
    @Published var states: [Int64: DownloadState] = [:]

    private var tasks: [Int64: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
    }

    // MARK: - Start Download
    func download(episode: CDEpisode) {
        let episodeId = episode.id
        guard states[episodeId] == nil || {
            if case .downloading = states[episodeId]! { return false }
            return true
        }() else { return }

        guard let url = APIClient.shared.videoURL(episodeId: Int(episodeId)) else { return }

        var request = URLRequest(url: url)
        if let token = KeychainManager.shared.readToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let task = session.downloadTask(with: request)
        task.taskDescription = "\(episodeId)"
        tasks[episodeId] = task
        states[episodeId] = .downloading(progress: 0)
        task.resume()
    }

    // MARK: - Cancel Download
    func cancel(episodeId: Int64) {
        tasks[episodeId]?.cancel()
        tasks[episodeId] = nil
        states[episodeId] = .idle
    }

    // MARK: - Local File URL helper
    nonisolated static func localURL(for episodeId: Int64) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("episode_\(episodeId).mp4")
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let idString = downloadTask.taskDescription,
              let episodeId = Int64(idString) else { return }

        let dest = DownloadManager.localURL(for: episodeId)

        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)

            CoreDataManager.shared.setEpisodeDownloaded(
                id: episodeId,
                localURL: dest.path
            )

            Task { @MainActor in
                self.states[episodeId] = .done
                self.tasks[episodeId] = nil
            }
        } catch {
            CoreDataManager.shared.setEpisodeDownloadFailed(id: episodeId)
            Task { @MainActor in
                self.states[episodeId] = .failed
                self.tasks[episodeId] = nil
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let idString = downloadTask.taskDescription,
              let episodeId = Int64(idString),
              totalBytesExpectedToWrite > 0 else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.states[episodeId] = .downloading(progress: progress)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error,
              let idString = task.taskDescription,
              let episodeId = Int64(idString) else { return }

        print("Download fehlgeschlagen für Episode \(episodeId): \(error)")
        CoreDataManager.shared.setEpisodeDownloadFailed(id: episodeId)
        Task { @MainActor in
            self.states[episodeId] = .failed
            self.tasks[episodeId] = nil
        }
    }
}

import SwiftUI
import CoreData
import AVKit
internal import Combine

struct VideoPlayerView: View {

    let episodeId: Int64  // ⭐ Nur die ID speichern
    @Environment(\.dismiss) private var dismiss

    @State private var episode: CDEpisode?  // ⭐ Fresh aus CoreData
    @State private var player: AVPlayer? = nil
    @State private var progressTimer: Timer? = nil
    @State private var updateTrigger: Int = 0  // ⭐ Trigger für Refresh
    
    @State private var errorSubscription: AnyCancellable? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.red)
                    Text("Lade Video...")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
            }
            .padding(.top, 10)
        }
        .onAppear {
            loadEpisodeAndSetup()
            // ⭐ Reagiere auf Download-Completion
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("EpisodeDownloadComplete"),
                object: nil,
                queue: .main
            ) { notification in
                if let completedId = notification.object as? Int64, completedId == episodeId {
                    print("📱 [Player] Download komplett! Refresh Episode...")
                    loadEpisodeAndSetup()
                }
            }
        }
        .onChange(of: updateTrigger) { _, _ in
            // ⭐ Wenn Trigger sich ändert, lade Episode neu
            print("📱 [Player] Refresh trigger aktiviert, lade Episode neu...")
            loadEpisodeAndSetup()
        }
        .onDisappear {
            stopTracking()
            errorSubscription?.cancel()
            player?.pause()
        }
    }

    // ⭐ NEU: Lade Episode fresh aus CoreData
    private func loadEpisodeAndSetup() {
        let request: NSFetchRequest<CDEpisode> = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", episodeId)
        
        if let freshEpisode = try? CoreDataManager.shared.context.fetch(request).first {
            self.episode = freshEpisode
            print("✅ [Player] Episode \(episodeId) fresh aus CoreData geladen: isDownloaded=\(freshEpisode.isDownloaded), localURL=\(freshEpisode.localFileURL ?? "nil")")
            setupPlayer(episode: freshEpisode)
        } else {
            print("❌ [Player] Episode \(episodeId) nicht in CoreData gefunden!")
        }
    }

    // MARK: - Setup Player
    private func setupPlayer(episode: CDEpisode) {
        let videoURL = playbackURL(for: episode)

        guard let url = videoURL else {
            print("❌ [Player] Fehler: videoURL ist nil!")
            return
        }

        let avPlayer = AVPlayer(url: url)
        self.player = avPlayer

        if let currentItem = avPlayer.currentItem {
            errorSubscription = currentItem.publisher(for: \.status)
                .receive(on: RunLoop.main)
                .sink { status in
                    switch status {
                    case .failed:
                        if let error = currentItem.error {
                            print("❌ [Player] AVPlayer-Fehler: \(error.localizedDescription)")
                            print("❌ [Player] AVPlayer-Fehlerdetails: \(error)")
                        }
                    case .readyToPlay:
                        print("✅ [Player] Stream erfolgreich geladen und bereit zum Abspielen!")
                    case .unknown:
                        print("⏳ [Player] Stream-Status noch unbekannt...")
                    @unknown default:
                        break
                    }
                }
        }

        if episode.progress > 5 {
            let seekTime = CMTime(seconds: episode.progress, preferredTimescale: 600)
            avPlayer.seek(to: seekTime)
        }

        avPlayer.play()
        startTracking(player: avPlayer, episodeId: episode.id)
    }

    private func playbackURL(for episode: CDEpisode) -> URL? {
        if episode.isDownloaded, let localURL = localPlaybackURL(for: episode) {
            print("📁 [Player] Versuche LOKALE Datei abzuspielen: \(localURL.path)")
            return localURL
        }

        let streamURL = APIClient.shared.videoURL(episodeId: Int(episode.id))
        print("🌐 [Player] Versuche ONLINE-Stream von URL: \(String(describing: streamURL))")
        return streamURL
    }

    private func localPlaybackURL(for episode: CDEpisode) -> URL? {
        let currentLocalURL = DownloadManager.localURL(for: episode.id)
        if FileManager.default.fileExists(atPath: currentLocalURL.path) {
            return currentLocalURL
        }

        if let storedPath = episode.localFileURL,
           FileManager.default.fileExists(atPath: storedPath) {
            return URL(fileURLWithPath: storedPath)
        }

        print("⚠️ [Player] Lokale Datei für Episode \(episode.id) nicht gefunden. Gespeicherter Pfad: \(episode.localFileURL ?? "nil")")
        return nil
    }

    // MARK: - Progress Tracking
    private func startTracking(player: AVPlayer, episodeId: Int64) {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard let currentItem = player.currentItem else { return }
            let position = player.currentTime().seconds
            let duration = currentItem.duration.seconds

            guard position.isFinite, duration.isFinite, duration > 0 else { return }

            let completed = (position / duration) > 0.9

            CoreDataManager.shared.updateProgress(
                episodeId: episodeId,
                progress: position,
                completed: completed
            )

            Task {
                try? await APIClient.shared.updateProgress(
                    episodeId: Int(episodeId),
                    position: position,
                    duration: duration
                )
            }
        }
    }

    private func stopTracking() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

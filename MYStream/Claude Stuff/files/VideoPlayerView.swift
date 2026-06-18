import SwiftUI
import AVKit

struct VideoPlayerView: View {

    let episode: CDEpisode
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVPlayer? = nil
    @State private var progressTimer: Timer? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView("Lade Video...")
                    .tint(.red)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            stopTracking()
            player?.pause()
        }
    }

    // MARK: - Setup Player
    private func setupPlayer() {
        let videoURL: URL?

        // Offline: lokale Datei bevorzugen
        if episode.isDownloaded, let localPath = episode.localFileURL {
            videoURL = URL(fileURLWithPath: localPath)
        } else {
            // Online: Stream vom Server
            videoURL = APIClient.shared.videoURL(episodeId: Int(episode.id))
        }

        guard let url = videoURL else { return }

        let avPlayer = AVPlayer(url: url)
        self.player = avPlayer

        // Zum gespeicherten Fortschritt springen
        if episode.progress > 5 {
            let seekTime = CMTime(seconds: episode.progress, preferredTimescale: 600)
            avPlayer.seek(to: seekTime)
        }

        avPlayer.play()
        startTracking(player: avPlayer)
    }

    // MARK: - Progress Tracking
    private func startTracking(player: AVPlayer) {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard let currentItem = player.currentItem else { return }
            let position = player.currentTime().seconds
            let duration = currentItem.duration.seconds

            guard position.isFinite, duration.isFinite, duration > 0 else { return }

            let completed = (position / duration) > 0.9

            // CoreData lokal aktualisieren
            CoreDataManager.shared.updateProgress(
                episodeId: episode.id,
                progress: position,
                completed: completed
            )

            // Server informieren (fire & forget)
            Task {
                try? await APIClient.shared.updateProgress(
                    episodeId: Int(episode.id),
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

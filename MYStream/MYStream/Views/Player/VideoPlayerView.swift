import SwiftUI
import AVKit
internal import Combine

struct VideoPlayerView: View {

    let episode: CDEpisode
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVPlayer? = nil
    @State private var progressTimer: Timer? = nil
    
    // Für die Fehlerüberwachung im SwiftUI-Style
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
            
            // Schließen-Button oben links, falls der Stream fehlschlägt
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
            setupPlayer()
        }
        .onDisappear {
            stopTracking()
            errorSubscription?.cancel()
            player?.pause()
        }
    }

    // MARK: - Setup Player
    private func setupPlayer() {
        let videoURL: URL?

        // Offline: lokale Datei bevorzugen
        if episode.isDownloaded, let localPath = episode.localFileURL {
            videoURL = URL(fileURLWithPath: localPath)
            print("📁 [Player] Versuche LOKALE Datei abzuspielen: \(localPath)")
        } else {
            // Online: Stream vom Server
            videoURL = APIClient.shared.videoURL(episodeId: Int(episode.id))
            print("🌐 [Player] Versuche ONLINE-Stream von URL: \(String(describing: videoURL))")
        }

        guard let url = videoURL else {
            print("❌ [Player] Fehler: videoURL ist nil!")
            return
        }

        let avPlayer = AVPlayer(url: url)
        self.player = avPlayer

        // --- FEHLER-BEACHTUNG PER COMBINE ---
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

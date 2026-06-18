import SwiftUI

struct SeriesOverlayView: View {

    let anime: CDAnime
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSeason: Int = 1
    @State private var selectedEpisode: CDEpisode? = nil

    // Episoden als Array aus dem Relationship
    private var allEpisodes: [CDEpisode] {
        let set = anime.episodes as? Set<CDEpisode> ?? []
        return set.sorted {
            if $0.seasonNumber != $1.seasonNumber {
                return $0.seasonNumber < $1.seasonNumber
            }
            return $0.episodeNumber < $1.episodeNumber
        }
    }

    private var availableSeasons: [Int] {
        Array(Set(allEpisodes.map { Int($0.seasonNumber) })).sorted()
    }

    private var episodesForSeason: [CDEpisode] {
        allEpisodes.filter { Int($0.seasonNumber) == selectedSeason }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Header Bild + Zurück-Button
                    ZStack(alignment: .topLeading) {
                        CoverImageView(
                            path: anime.coverURL ?? "",
                            width: UIScreen.main.bounds.width,
                            height: 220
                        )
                        .clipped()

                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 48)
                        .padding(.leading, 16)
                    }

                    VStack(alignment: .leading, spacing: 12) {

                        // MARK: Titel
                        Text(anime.title ?? "Unbekannt")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        // MARK: Beschreibung
                        if let summary = anime.summary, !summary.isEmpty {
                            Text(summary)
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }

                        Divider().background(Color.white.opacity(0.12))

                        // MARK: Staffel Dropdown
                        if !availableSeasons.isEmpty {
                            HStack {
                                Text("Staffel")
                                    .foregroundColor(.white)
                                    .font(.subheadline)

                                Spacer()

                                Menu {
                                    ForEach(availableSeasons, id: \.self) { season in
                                        Button("Staffel \(season)") {
                                            selectedSeason = season
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Staffel \(selectedSeason)")
                                            .foregroundColor(.white)
                                            .font(.subheadline)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            // MARK: Episodenliste
                            LazyVStack(spacing: 8) {
                                ForEach(episodesForSeason) { episode in
                                    EpisodeRow(episode: episode, anime: anime)
                                        .onTapGesture {
                                            selectedEpisode = episode
                                        }
                                }
                            }
                        } else {
                            Text("Keine Episoden verfügbar.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            // Erste verfügbare Staffel vorauswählen
            if let first = availableSeasons.first {
                selectedSeason = first
            }
        }
        .fullScreenCover(item: $selectedEpisode) { episode in
            VideoPlayerView(episode: episode)
        }
    }
}

// MARK: - EpisodeRow
struct EpisodeRow: View {

    let episode: CDEpisode
    let anime: CDAnime
    @StateObject private var downloadManager = DownloadManager.shared

    private var downloadState: DownloadState? {
        downloadManager.states[episode.id]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Episodennummer
            Text("EP \(episode.episodeNumber)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 44, height: 32)
                .background(Color.white.opacity(0.12))
                .cornerRadius(6)

            // Titel
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title?.isEmpty == false ? episode.title! : "Episode \(episode.episodeNumber)")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .lineLimit(1)

                if episode.progress > 0 && !episode.completed {
                    ProgressView(value: episode.progress, total: episode.duration > 0 ? episode.duration : 1)
                        .tint(.red)
                        .frame(maxWidth: 120)
                }
            }

            Spacer()

            // Download Button
            downloadButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var downloadButton: some View {
        if episode.isDownloaded {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        } else if case .downloading(let progress) = downloadState {
            ZStack {
                CircularProgressView(progress: progress)
                    .frame(width: 28, height: 28)
                Button { DownloadManager.shared.cancel(episodeId: episode.id) } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        } else if case .failed = downloadState {
            Button {
                DownloadManager.shared.download(episode: episode)
            } label: {
                Image(systemName: "exclamationmark.arrow.circlepath")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        } else {
            Button {
                DownloadManager.shared.download(episode: episode)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
}

// MARK: - CircularProgressView
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}

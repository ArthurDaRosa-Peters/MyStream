import SwiftUI

struct SeriesOverlayView: View {

    @ObservedObject var anime: CDAnime
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

    private let thumbnailWidth: CGFloat = 150
    private let thumbnailHeight: CGFloat = 180
    private let episodeColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 18) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .medium))
                                .frame(width: 32, height: 44)
                        }

                        Text("MYStream")
                            .font(.system(size: 34, weight: .regular))
                            .foregroundColor(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.top, 12)

                    HStack(alignment: .top, spacing: 18) {
                        Text(anime.title ?? "Unbekannt")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .textCase(.uppercase)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        CoverImageView(
                            path: anime.coverURL ?? "",
                            width: thumbnailWidth,
                            height: thumbnailHeight
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beschreibung")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        ScrollView {
                            Text(descriptionText)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )

                    if !availableSeasons.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableSeasons, id: \.self) { season in
                                    Button {
                                        selectedSeason = season
                                    } label: {
                                        Text("Season \(season)")
                                            .font(.subheadline)
                                            .foregroundColor(selectedSeason == season ? .white : .black)
                                            .frame(height: 34)
                                            .padding(.horizontal, 16)
                                            .background(selectedSeason == season ? Color.red : Color.gray)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }

                        LazyVGrid(columns: episodeColumns, spacing: 8) {
                            ForEach(episodesForSeason) { episode in
                                Button {
                                    selectedEpisode = episode
                                } label: {
                                    Text("EP \(episode.episodeNumber)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(Color.white.opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    } else {
                        Text("Keine Episoden verfügbar.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
                    // Erste verfügbare Staffel beim Erscheinen auswählen
                    selectFirstAvailableSeason()
                }
                // NEU: Reagiert asynchron, falls die Episoden erst Millisekunden später geladen werden
                .onChange(of: availableSeasons) { oldValue, newValue in
                    selectFirstAvailableSeason()
                }
                .fullScreenCover(item: $selectedEpisode) { episode in
                    VideoPlayerView(episode: episode)
                }
            }

            // NEU: Kleine Hilfsfunktion, um doppelten Code zu vermeiden
            private func selectFirstAvailableSeason() {
                if let first = availableSeasons.first {
                    selectedSeason = first
                }
            }

    private var descriptionText: String {
        guard let summary = anime.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
              !summary.isEmpty else {
            return "Keine Beschreibung verfügbar."
        }
        return summary
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

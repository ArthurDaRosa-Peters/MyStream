import SwiftUI

// MARK: - AnimeCard
/// Zeigt Cover + Titel eines Animes. Wird in Home und Downloads verwendet.
struct AnimeCard: View {

    let anime: CDAnime
    var cardWidth: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverImageView(
                path: anime.coverURL ?? "",
                width: cardWidth,
                height: cardWidth * 1.4
            )

            Text(anime.title ?? "Unbekannt")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: cardWidth, alignment: .leading)
        }
    }
}

// MARK: - CoverImageView
/// Lädt das Cover asynchron. Zeigt einen Platzhalter während des Ladens.
struct CoverImageView: View {

    let path: String
    let width: CGFloat
    let height: CGFloat

    private var fullURL: URL? {
        guard !path.isEmpty else { return nil }
        // Absolute URLs (https://cdn.anilist.co/...) direkt nutzen
        // Relative Pfade (/public/img/...) mit localhost prefixen
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        return URL(string: "http://localhost:8080\(path)")
    }

    var body: some View {
        Group {
            if let url = fullURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    case .empty:
                        placeholderView
                            .overlay(ProgressView().tint(.gray))
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.08))
            .overlay(
                Image(systemName: "play.tv")
                    .foregroundColor(.gray)
                    .font(.title2)
            )
    }
}

// MARK: - AnimeGridView
/// 2-spaltiges Grid für Anime-Karten. Wird in Home und Downloads verwendet.
struct AnimeGridView: View {

    let animes: [CDAnime]
    let onSelect: (CDAnime) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(animes, id: \.id) { anime in
                AnimeCard(anime: anime)
                    .onTapGesture { onSelect(anime) }
            }
        }
        .padding(.horizontal, 16)
    }
}

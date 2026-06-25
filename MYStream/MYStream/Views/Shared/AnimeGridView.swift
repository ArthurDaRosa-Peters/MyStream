import SwiftUI

// MARK: - AnimeCard
/// Zeigt Cover + Titel eines Animes. Wird in Home und Downloads verwendet.
struct AnimeCard: View {

    let anime: CDAnime
    var cardWidth: CGFloat = 160

    private let titleBarHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            CoverImageView(
                path: anime.coverURL ?? "",
                width: cardWidth,
                height: cardWidth * 1.4
            )

            Text(anime.title ?? "Unbekannt")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 10)
                .frame(width: cardWidth, height: titleBarHeight)
                .background(Color.white.opacity(0.14))
        }
        .frame(width: cardWidth)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
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
        .clipShape(TopRoundedRectangle(cornerRadius: 8))
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

private struct TopRoundedRectangle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, rect.width / 2, rect.height / 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
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

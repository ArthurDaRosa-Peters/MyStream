import SwiftUI

struct DownloadsView: View {

    @Binding var showSidebar: Bool
    @StateObject private var vm = DownloadsViewModel()
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var searchText: String = ""
    @State private var selectedAnime: CDAnime? = nil

    private var filteredAnimes: [CDAnime] {
        if searchText.isEmpty { return vm.downloadedAnimes }
        return vm.downloadedAnimes.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    Button { withAnimation { showSidebar.toggle() } } label: {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Text("MYStream")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: Suchleiste
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Anime suchen...", text: $searchText)
                        .foregroundColor(.white)
                        .tint(.red)
                }
                .padding(10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // MARK: Inhalt
                if vm.downloadedAnimes.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Meine Downloads")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Noch keine Downloads vorhanden.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meine Downloads")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            AnimeGridView(animes: filteredAnimes) { anime in
                                selectedAnime = anime
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear { vm.load() }
        .onChange(of: downloadManager.states) { _ in vm.refresh() }
        .sheet(item: $selectedAnime) { anime in
            SeriesOverlayView(anime: anime)
        }
    }
}

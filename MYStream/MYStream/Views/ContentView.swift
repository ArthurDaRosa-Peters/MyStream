import SwiftUI

struct ContentView: View {

    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Int = 0
    @State private var isOnline: Bool = true

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView(selectedTab: $selectedTab, isOnline: isOnline)
                    .task {
                        isOnline = await APIClient.shared.isServerReachable()
                        // Startet auf dem richtigen Tab je nach Netzwerk
                        selectedTab = isOnline ? 0 : 1
                    }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isLoggedIn)
    }
}

// MARK: - MainTabView
struct MainTabView: View {

    @Binding var selectedTab: Int
    let isOnline: Bool
    @State private var showSidebar: Bool = false

    private var guardedSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == 0 && !isOnline {
                    selectedTab = 1
                } else {
                    selectedTab = newTab
                }
            }
        )
    }

    var body: some View {
        ZStack(alignment: .leading) {
            TabView(selection: guardedSelection) {
                HomeView(showSidebar: $showSidebar)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                DownloadsView(showSidebar: $showSidebar)
                    .tabItem {
                        Label("Downloads", systemImage: "arrow.down.circle.fill")
                    }
                    .tag(1)
            }
            .accentColor(.red)

            // Sidebar Overlay
            if showSidebar {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showSidebar = false } }

                SidebarView(isShowing: $showSidebar, selectedTab: $selectedTab, isOnline: isOnline)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSidebar)
    }
}

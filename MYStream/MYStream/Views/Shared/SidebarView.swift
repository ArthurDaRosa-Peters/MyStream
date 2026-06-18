import SwiftUI

struct SidebarView: View {

    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header / Profil
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.username.isEmpty ? "Gast" : authManager.username)
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button { withAnimation { isShowing = false } } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 32)

                Divider().background(Color.white.opacity(0.1))

                // MARK: Navigation
                VStack(alignment: .leading, spacing: 4) {
                    sidebarButton(
                        title: "Alle Anime",
                        icon: "house.fill",
                        tab: 0
                    )
                    sidebarButton(
                        title: "Downloads",
                        icon: "arrow.down.circle.fill",
                        tab: 1
                    )
                }
                .padding(.top, 16)

                Spacer()

                Divider().background(Color.white.opacity(0.1))

                // MARK: Logout
                Button {
                    withAnimation { isShowing = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        authManager.logout()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Logout")
                            .foregroundColor(.red)
                            .font(.body)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .padding(.bottom, 32)
            }
        }
        .frame(width: 260)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 5, y: 0)
    }

    // MARK: - Sidebar Button
    @ViewBuilder
    private func sidebarButton(title: String, icon: String, tab: Int) -> some View {
        Button {
            selectedTab = tab
            withAnimation { isShowing = false }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(selectedTab == tab ? .red : .gray)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                selectedTab == tab
                    ? Color.red.opacity(0.12)
                    : Color.clear
            )
            .cornerRadius(8)
            .padding(.horizontal, 8)
        }
    }
}

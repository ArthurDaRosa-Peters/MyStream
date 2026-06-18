import SwiftUI

@main
struct MYStreamApp: App {

    @StateObject private var authManager = AuthManager.shared

    init() {
        AuthManager.shared.checkExistingSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
    }
}

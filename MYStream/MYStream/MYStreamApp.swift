//
//  MYStreamApp.swift
//  MYStream
//
//  Created by Arthur da Rosa-Peters / PBD2H24A on 28.05.26.
//

import SwiftUI

@main
struct MYStreamApp: App {
    @StateObject private var authManager = AuthManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

//
//  FocusPickApp.swift
//  FocusPick
//

import SwiftUI

@main
struct FocusPickApp: App {
    @StateObject private var appState = AppState()

    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(FPColor.bgDeep)
        nav.titleTextAttributes = [.foregroundColor: UIColor(FPColor.textPrimary)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(FPColor.textPrimary)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(FPColor.glow)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

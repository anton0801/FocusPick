//
//  RootView.swift
//  FocusPick
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView { showSplash = false }
                    .transition(.opacity)
            } else if !app.hasCompletedOnboarding {
                OnboardingView().transition(.opacity)
            } else if !app.isLoggedIn {
                WelcomeView().transition(.opacity)
            } else {
                MainTabView().transition(.opacity)
            }
        }
        .preferredColorScheme(app.themePref.colorScheme)
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: app.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: app.isLoggedIn)
    }
}

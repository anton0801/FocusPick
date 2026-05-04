import SwiftUI

struct RootView: View {
    @StateObject private var app = AppState()
    
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

    var body: some View {
        ZStack {
            if !app.hasCompletedOnboarding {
                OnboardingView().transition(.opacity)
            } else if !app.isLoggedIn {
                WelcomeView().transition(.opacity)
            } else {
                MainTabView().transition(.opacity)
            }
        }
        .preferredColorScheme(app.themePref.colorScheme)
        .animation(.easeInOut(duration: 0.4), value: app.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: app.isLoggedIn)
        .environmentObject(app)
    }
}

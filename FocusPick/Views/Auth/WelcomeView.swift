//
//  WelcomeView.swift
//  FocusPick
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var app: AppState
    @State private var goLogin = false

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                VStack(spacing: 22) {
                    Spacer()
                    ZStack {
                        Circle().fill(FPColor.accentLight.opacity(0.1)).frame(width: 220, height: 220)
                        Circle().stroke(FPColor.glow.opacity(0.7), lineWidth: 2).frame(width: 150, height: 150)
                        Image(systemName: "scope")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(FPColor.glow)
                            .shadow(color: FPColor.glow, radius: 18)
                    }
                    VStack(spacing: 6) {
                        Text("Focus Pick").font(FPFont.display(34)).foregroundColor(FPColor.textPrimary)
                        Text("Sharper attention, in minutes a day.").font(FPFont.body(14)).foregroundColor(FPColor.textMuted)
                    }
                    Spacer()

                    NavigationLink(destination: LoginView(), isActive: $goLogin) { EmptyView() }

                    PrimaryButton(title: "Continue", icon: "arrow.right") {
                        Haptics.tap(app.hapticsEnabled); goLogin = true
                    }
                    GhostButton(title: "Continue as Guest", icon: "person.fill") {
                        Haptics.tap(app.hapticsEnabled)
                        app.loginAsGuest()
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

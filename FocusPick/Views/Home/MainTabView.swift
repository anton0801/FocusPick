//
//  MainTabView.swift
//  FocusPick
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var app: AppState
    @State private var tab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if tab == 0 { HomeView() }
                else if tab == 1 { ProgressTabView() }
                else if tab == 2 { ChallengesTabView() }
                else if tab == 3 { ProfileView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            CustomTabBar(selected: $tab)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: Int
    @EnvironmentObject var app: AppState
    let items: [(String, String)] = [
        ("house.fill", "Home"),
        ("chart.bar.fill", "Progress"),
        ("flag.checkered", "Challenges"),
        ("person.fill", "Profile")
    ]
    var body: some View {
        HStack {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    Haptics.tap(app.hapticsEnabled)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = i }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[i].0)
                            .font(.system(size: 18, weight: .bold))
                        Text(items[i].1).font(FPFont.body(10, weight: .semibold))
                    }
                    .foregroundColor(selected == i ? FPColor.glow : FPColor.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8).padding(.top, 6)
        .background(
            ZStack {
                FPColor.bgDeep.opacity(0.95)
                LinearGradient(colors: [FPColor.bgPrimary, FPColor.bgDeep], startPoint: .top, endPoint: .bottom)
                    .opacity(0.9)
            }
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(FPColor.accentLight.opacity(0.18)),
                alignment: .top
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

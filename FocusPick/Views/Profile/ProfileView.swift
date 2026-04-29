//
//  ProfileView.swift
//  FocusPick
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 10) {
                            ZStack {
                                Circle().fill(FPColor.card).frame(width: 96, height: 96)
                                    .overlay(Circle().stroke(FPColor.glow, lineWidth: 2))
                                    .shadow(color: FPColor.glow.opacity(0.6), radius: 18)
                                Text(initials)
                                    .font(FPFont.display(28))
                                    .foregroundColor(FPColor.textPrimary)
                            }
                            Text(app.profile?.name ?? "Player").font(FPFont.display(22)).foregroundColor(FPColor.textPrimary)
                            if let e = app.profile?.email, !e.isEmpty {
                                Text(e).font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                            } else if app.profile?.isGuest == true {
                                Text("Guest mode").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                            }
                        }.padding(.top, 14)

                        // XP bar
                        GlowCard(glow: FPColor.warning) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Level \(level)")
                                        .font(FPFont.display(18)).foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                    Text("\(app.xp) XP").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                }
                                ProgressBar(value: Double(app.xp % 100), total: 100)
                                Text("\(100 - (app.xp % 100)) XP to next level")
                                    .font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
                            }
                        }

                        // Quick links
                        NavigationLink(destination: RewardsView()) {
                            row(icon: "trophy.fill", title: "Rewards", color: FPColor.warning)
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: HistoryView()) {
                            row(icon: "clock.arrow.circlepath", title: "History", color: FPColor.glow)
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: NotificationsView()) {
                            row(icon: "bell.fill", title: "Notifications", color: FPColor.accentLight)
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: FocusModeView()) {
                            row(icon: "moon.zzz.fill", title: "Focus Mode", color: FPColor.glow)
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: SettingsView()) {
                            row(icon: "gearshape.fill", title: "Settings", color: FPColor.textPrimary)
                        }.buttonStyle(PlainButtonStyle())

                        Spacer().frame(height: 80)
                    }.padding(20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    var initials: String {
        let n = app.profile?.name ?? "P"
        let parts = n.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? "P"
        let last  = parts.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
    var level: Int { 1 + app.xp / 100 }

    func row(icon: String, title: String, color: Color) -> some View {
        GlowCard {
            HStack {
                Image(systemName: icon).foregroundColor(color).frame(width: 26)
                Text(title).foregroundColor(FPColor.textPrimary).font(FPFont.body(15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
            }
        }
    }
}

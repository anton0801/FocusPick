//
//  HomeView.swift
//  FocusPick
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var quickStartActive = false

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello,").font(FPFont.body(13)).foregroundColor(FPColor.textMuted)
                                Text(app.profile?.name ?? "Player")
                                    .font(FPFont.display(24))
                                    .foregroundColor(FPColor.textPrimary)
                            }
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(FPColor.textPrimary)
                                    .padding(10).background(FPColor.card).clipShape(Circle())
                            }
                        }
                        // Today session
                        GlowCard(glow: FPColor.glow) {
                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Today").font(FPFont.body(12, weight: .semibold)).foregroundColor(FPColor.glow)
                                    Text("Daily Challenge")
                                        .font(FPFont.display(20))
                                        .foregroundColor(FPColor.textPrimary)
                                    if let dc = app.dailyChallenge {
                                        Text("\(dc.mode.title) • \(dc.difficulty.title) • \(dc.completedRounds)/\(dc.targetRounds)")
                                            .font(FPFont.body(12))
                                            .foregroundColor(FPColor.textMuted)
                                        ProgressBar(value: Double(dc.completedRounds), total: Double(dc.targetRounds))
                                    }
                                }
                                Spacer()
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 30))
                                    .foregroundColor(FPColor.glow)
                            }
                        }
                        .onTapGesture {
                            Haptics.tap(app.hapticsEnabled)
                        }

                        // Progress card
                        NavigationLink(destination: ProgressTabView()) {
                            GlowCard {
                                HStack {
                                    statCell(title: "Sessions", value: "\(app.totalSessions)", icon: "play.circle.fill")
                                    Divider().background(FPColor.cardElev)
                                    statCell(title: "Correct", value: "\(app.totalCorrect)", icon: "checkmark.seal.fill")
                                    Divider().background(FPColor.cardElev)
                                    statCell(title: "Streak", value: "\(app.bestStreak)", icon: "flame.fill")
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        // Quick start
                        SectionHeader(title: "Quick start", subtitle: "One tap into a session")

                        NavigationLink(destination: SessionView(mode: .focus, difficulty: .easy), isActive: $quickStartActive) { EmptyView() }

                        HStack(spacing: 12) {
                            quickStart(mode: .focus, color: FPColor.accentLight)
                            quickStart(mode: .memory, color: FPColor.glow)
                            quickStart(mode: .speed, color: FPColor.warning)
                        }

                        // Pick mode (full)
                        SectionHeader(title: "Train")
                        NavigationLink(destination: ModeSelectView()) {
                            GlowCard {
                                HStack {
                                    Image(systemName: "scope").font(.system(size: 30)).foregroundColor(FPColor.glow)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Choose a mode").font(FPFont.display(18)).foregroundColor(FPColor.textPrimary)
                                        Text("Focus • Memory • Speed").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: TrainingPlanView()) {
                            GlowCard(glow: FPColor.accentLight) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle.fill").font(.system(size: 26)).foregroundColor(FPColor.accentLight)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Training Plan").font(FPFont.display(17)).foregroundColor(FPColor.textPrimary)
                                        let done = app.plan.filter { $0.completed }.count
                                        Text("\(done)/\(app.plan.count) days complete").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: TimerView()) {
                            GlowCard(glow: FPColor.warning) {
                                HStack {
                                    Image(systemName: "timer").font(.system(size: 26)).foregroundColor(FPColor.warning)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pomodoro Timer").font(FPFont.display(17)).foregroundColor(FPColor.textPrimary)
                                        Text("Focus blocks with breaks").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        Spacer().frame(height: 80)
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    func statCell(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(FPColor.glow)
            Text(value).font(FPFont.display(20)).foregroundColor(FPColor.textPrimary)
            Text(title).font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
        }.frame(maxWidth: .infinity)
    }

    func quickStart(mode: TrainingMode, color: Color) -> some View {
        NavigationLink(destination: SessionView(mode: mode, difficulty: .easy)) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon).font(.system(size: 22, weight: .bold)).foregroundColor(color)
                Text(mode.title).font(FPFont.body(13, weight: .semibold)).foregroundColor(FPColor.textPrimary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(FPColor.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.5), lineWidth: 1))
                    .shadow(color: color.opacity(0.25), radius: 12)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

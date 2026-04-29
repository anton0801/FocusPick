//
//  ChallengesTabView.swift
//  FocusPick
//

import SwiftUI

struct ChallengesTabView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Daily challenge", subtitle: "Reset every day at midnight")
                        if let dc = app.dailyChallenge {
                            NavigationLink(destination: SessionView(mode: dc.mode, difficulty: dc.difficulty)) {
                                GlowCard(glow: dc.isComplete ? FPColor.success : FPColor.glow) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Image(systemName: dc.mode.icon).foregroundColor(FPColor.glow)
                                                Text("\(dc.mode.title) • \(dc.difficulty.title)")
                                                    .font(FPFont.display(18)).foregroundColor(FPColor.textPrimary)
                                            }
                                            Text("\(dc.completedRounds)/\(dc.targetRounds) rounds")
                                                .font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                            ProgressBar(value: Double(dc.completedRounds), total: Double(dc.targetRounds))
                                                .frame(maxWidth: 240)
                                        }
                                        Spacer()
                                        if dc.isComplete {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 30)).foregroundColor(FPColor.success)
                                        } else {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 30)).foregroundColor(FPColor.glow)
                                        }
                                    }
                                }
                            }.buttonStyle(PlainButtonStyle())
                        }

                        SectionHeader(title: "Training plan", subtitle: "A 7-day starter program")
                        ForEach(app.plan) { day in
                            NavigationLink(destination: SessionView(mode: day.mode, difficulty: day.difficulty)) {
                                GlowCard(glow: day.completed ? FPColor.success : FPColor.accentLight) {
                                    HStack {
                                        ZStack {
                                            Circle().fill(day.completed ? FPColor.success : FPColor.cardElev)
                                                .frame(width: 36, height: 36)
                                            Text("\(day.dayNumber)")
                                                .font(FPFont.display(15))
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Day \(day.dayNumber): \(day.mode.title)")
                                                .font(FPFont.body(15, weight: .semibold))
                                                .foregroundColor(FPColor.textPrimary)
                                            Text("\(day.difficulty.title) • \(day.rounds) rounds")
                                                .font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
                                        }
                                        Spacer()
                                        if day.completed {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(FPColor.success)
                                        }
                                    }
                                }
                            }.buttonStyle(PlainButtonStyle())
                        }

                        Button {
                            Haptics.tap(app.hapticsEnabled)
                            app.plan = AppState.defaultPlan()
                        } label: {
                            Text("Reset plan")
                                .foregroundColor(FPColor.warning)
                                .font(FPFont.body(13, weight: .semibold))
                        }.padding(.top, 4)

                        Spacer().frame(height: 80)
                    }.padding(20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TrainingPlanView: View {
    var body: some View {
        ChallengesTabView()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Training Plan")
    }
}

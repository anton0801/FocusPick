//
//  StatsView.swift
//  FocusPick
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 14) {
                    SectionHeader(title: "Detailed stats")
                    GlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            row("Total sessions", "\(app.totalSessions)")
                            row("Total correct", "\(app.totalCorrect)")
                            row("Total XP", "\(app.xp)")
                            row("Best streak", "\(app.bestStreak)")
                            row("Avg accuracy", "\(Int(globalAccuracy() * 100))%")
                            row("Avg reaction", "\(globalAvgMs())ms")
                        }
                    }
                    GlowCard(glow: FPColor.accentLight) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("By difficulty").font(FPFont.body(12, weight: .semibold)).foregroundColor(FPColor.textMuted)
                            ForEach(Difficulty.allCases) { d in
                                let acc = accuracy(for: d)
                                HStack {
                                    Text(d.title).foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                                    Spacer()
                                    ProgressBar(value: acc, total: 1).frame(width: 140)
                                    Text("\(Int(acc * 100))%").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                }
                            }
                        }
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(FPColor.textMuted).font(FPFont.body(13))
            Spacer()
            Text(value).foregroundColor(FPColor.textPrimary).font(FPFont.body(15, weight: .semibold))
        }
    }
    func globalAccuracy() -> Double {
        guard !app.history.isEmpty else { return 0 }
        return app.history.map { $0.accuracy }.reduce(0, +) / Double(app.history.count)
    }
    func globalAvgMs() -> Int {
        guard !app.history.isEmpty else { return 0 }
        return Int(app.history.map { Double($0.avgReactionMs) }.reduce(0, +) / Double(app.history.count))
    }
    func accuracy(for d: Difficulty) -> Double {
        let arr = app.history.filter { $0.difficulty == d }
        guard !arr.isEmpty else { return 0 }
        return arr.map { $0.accuracy }.reduce(0, +) / Double(arr.count)
    }
}

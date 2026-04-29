//
//  ProgressTabView.swift
//  FocusPick
//

import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Progress", subtitle: "Your training over time")

                        HStack(spacing: 12) {
                            statTile(title: "Sessions", value: "\(app.totalSessions)", icon: "play.circle.fill", color: FPColor.accentLight)
                            statTile(title: "XP", value: "\(app.xp)", icon: "star.circle.fill", color: FPColor.warning)
                            statTile(title: "Best streak", value: "\(app.bestStreak)", icon: "flame.fill", color: FPColor.danger)
                        }

                        GlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Accuracy over last 10").font(FPFont.body(12, weight: .semibold)).foregroundColor(FPColor.textMuted)
                                AccuracyChart(values: lastAccuracy())
                                    .frame(height: 120)
                            }
                        }

                        GlowCard(glow: FPColor.warning) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Reaction (ms) — lower is better").font(FPFont.body(12, weight: .semibold)).foregroundColor(FPColor.textMuted)
                                ReactionChart(values: lastReactions())
                                    .frame(height: 120)
                            }
                        }

                        GlowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Per-mode accuracy").font(FPFont.body(12, weight: .semibold)).foregroundColor(FPColor.textMuted)
                                ForEach(TrainingMode.allCases) { m in
                                    let acc = avgAccuracy(for: m)
                                    HStack {
                                        Image(systemName: m.icon).foregroundColor(FPColor.glow).frame(width: 22)
                                        Text(m.title).foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                                        Spacer()
                                        ProgressBar(value: acc, total: 1).frame(width: 130)
                                        Text("\(Int(acc * 100))%").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                    }
                                }
                            }
                        }

                        NavigationLink(destination: HistoryView()) {
                            GlowCard {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath").foregroundColor(FPColor.glow)
                                    Text("Session history").foregroundColor(FPColor.textPrimary).font(FPFont.body(15, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: StatsView()) {
                            GlowCard(glow: FPColor.accentLight) {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(FPColor.accentLight)
                                    Text("Detailed stats").foregroundColor(FPColor.textPrimary).font(FPFont.body(15, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: RewardsView()) {
                            GlowCard(glow: FPColor.warning) {
                                HStack {
                                    Image(systemName: "trophy.fill").foregroundColor(FPColor.warning)
                                    Text("Rewards & achievements").foregroundColor(FPColor.textPrimary).font(FPFont.body(15, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())

                        Spacer().frame(height: 80)
                    }.padding(20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(FPFont.display(20)).foregroundColor(FPColor.textPrimary)
            Text(title).font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(FPColor.card).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.4), lineWidth: 1))
    }

    func lastAccuracy() -> [Double] {
        Array(app.history.prefix(10).reversed()).map { $0.accuracy }
    }
    func lastReactions() -> [Double] {
        Array(app.history.prefix(10).reversed()).map { Double($0.avgReactionMs) }
    }
    func avgAccuracy(for mode: TrainingMode) -> Double {
        let h = app.history.filter { $0.mode == mode }
        guard !h.isEmpty else { return 0 }
        return h.map { $0.accuracy }.reduce(0, +) / Double(h.count)
    }
}

struct AccuracyChart: View {
    let values: [Double]
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                if values.isEmpty {
                    Text("No data yet").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(values.indices, id: \.self) { i in
                        let h = max(6, CGFloat(values[i]) * (g.size.height - 8))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [FPColor.accent, FPColor.glow],
                                                 startPoint: .bottom, endPoint: .top))
                            .frame(height: h)
                    }
                }
            }
        }
    }
}

struct ReactionChart: View {
    let values: [Double]
    var body: some View {
        GeometryReader { g in
            if values.isEmpty {
                Text("No data yet").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxV = max(values.max() ?? 1, 1)
                Path { p in
                    let stepX = g.size.width / CGFloat(max(values.count - 1, 1))
                    for i in values.indices {
                        let x = CGFloat(i) * stepX
                        let y = g.size.height - CGFloat(values[i] / maxV) * (g.size.height - 6) - 3
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(LinearGradient(colors: [FPColor.warning, FPColor.glow],
                                       startPoint: .leading, endPoint: .trailing), lineWidth: 2)
            }
        }
    }
}

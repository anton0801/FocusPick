//
//  HistoryView.swift
//  FocusPick
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var app: AppState
    @State private var filter: TrainingMode? = nil

    var filtered: [SessionResult] {
        guard let f = filter else { return app.history }
        return app.history.filter { $0.mode == f }
    }

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ChipView(title: "All", selected: filter == nil) { filter = nil }
                    ForEach(TrainingMode.allCases) { m in
                        ChipView(title: m.title, selected: filter == m) { filter = m }
                    }
                }.padding(.horizontal, 16).padding(.top, 12)

                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.system(size: 38)).foregroundColor(FPColor.textMuted)
                        Text("No sessions yet").foregroundColor(FPColor.textMuted)
                    }.frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filtered) { r in
                                GlowCard {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: r.mode.icon).foregroundColor(FPColor.glow)
                                            Text("\(r.mode.title) • \(r.difficulty.title)")
                                                .font(FPFont.body(14, weight: .semibold))
                                                .foregroundColor(FPColor.textPrimary)
                                            Spacer()
                                            Text(formatted(r.date)).font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
                                        }
                                        HStack {
                                            badge("Score", "\(r.correct)/\(r.total)", FPColor.success)
                                            badge("Accuracy", "\(Int(r.accuracy * 100))%", FPColor.glow)
                                            badge("React", "\(r.avgReactionMs)ms", FPColor.warning)
                                        }
                                    }
                                }
                            }
                            Button {
                                Haptics.tap(app.hapticsEnabled)
                                app.history = []
                            } label: {
                                Text("Clear history")
                                    .foregroundColor(FPColor.danger)
                                    .font(FPFont.body(13, weight: .semibold))
                            }.padding(.top, 6)
                        }.padding(20)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    func badge(_ t: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 2) {
            Text(t).font(FPFont.body(10)).foregroundColor(FPColor.textMuted)
            Text(v).font(FPFont.body(12, weight: .bold)).foregroundColor(c)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6).background(FPColor.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short; f.timeStyle = .short
        return f.string(from: d)
    }
}

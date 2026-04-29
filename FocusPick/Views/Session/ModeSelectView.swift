//
//  ModeSelectView.swift
//  FocusPick
//

import SwiftUI

struct ModeSelectView: View {
    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "Pick a mode", subtitle: "Three pillars of attention")
                    ForEach(TrainingMode.allCases) { m in
                        NavigationLink(destination: LevelSelectView(mode: m)) {
                            GlowCard(glow: glow(for: m)) {
                                HStack {
                                    Image(systemName: m.icon).font(.system(size: 30, weight: .bold)).foregroundColor(glow(for: m))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(m.title).font(FPFont.display(20)).foregroundColor(FPColor.textPrimary)
                                        Text(m.subtitle).font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(FPColor.textMuted)
                                }
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
    func glow(for m: TrainingMode) -> Color {
        switch m {
        case .focus: return FPColor.accentLight
        case .memory: return FPColor.glow
        case .speed: return FPColor.warning
        }
    }
}

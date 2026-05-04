//
//  LevelSelectView.swift
//  FocusPick
//

import SwiftUI

struct LevelSelectView: View {
    let mode: TrainingMode
    @State private var goSession = false
    @State private var picked: Difficulty = .easy

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 20) {
                SectionHeader(title: "Difficulty", subtitle: "How hard do you want it?")
                ForEach(Difficulty.allCases) { d in
                    Button {
                        picked = d
                    } label: {
                        GlowCard(glow: picked == d ? FPColor.glow : FPColor.accentLight.opacity(0.4)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(d.title).font(FPFont.display(20)).foregroundColor(FPColor.textPrimary)
                                    Text(detail(d)).font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                                }
                                Spacer()
                                Image(systemName: picked == d ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(picked == d ? FPColor.glow : FPColor.textMuted)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                NavigationLink(
                    destination: SessionView(mode: mode, difficulty: picked),
                    isActive: $goSession
                ) { EmptyView() }

                PrimaryButton(title: "Start session", icon: "play.fill") { goSession = true }
                Spacer()
            }.padding(20)
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    func detail(_ d: Difficulty) -> String {
        switch d {
        case .easy:   return "\(d.cardCount) cards • slow shuffle"
        case .medium: return "\(d.cardCount) cards • faster shuffle"
        case .hard:   return "\(d.cardCount) cards • lightning shuffle"
        }
    }
}


struct OfflineView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("main_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 10)
                    .opacity(0.6)
                
                Image("error")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

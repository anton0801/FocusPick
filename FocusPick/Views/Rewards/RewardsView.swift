//
//  RewardsView.swift
//  FocusPick
//

import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(app.achievements) { a in
                        VStack(spacing: 10) {
                            ZStack {
                                Circle().fill(a.unlocked ? FPColor.warning.opacity(0.2) : FPColor.cardElev)
                                    .frame(width: 64, height: 64)
                                Image(systemName: a.icon)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(a.unlocked ? FPColor.warning : FPColor.textMuted)
                            }
                            Text(a.title).font(FPFont.body(13, weight: .bold)).foregroundColor(FPColor.textPrimary)
                            Text(a.detail).font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(14)
                        .background(FPColor.card).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(a.unlocked ? FPColor.warning : FPColor.cardElev, lineWidth: 1)
                        )
                        .opacity(a.unlocked ? 1 : 0.6)
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

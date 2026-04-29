//
//  ResultView.swift
//  FocusPick
//

import SwiftUI

struct ResultView: View {
    let correct: Int
    let total: Int
    let avgMs: Int
    let mode: TrainingMode
    let difficulty: Difficulty
    let streak: Int
    let onDone: () -> Void

    @EnvironmentObject var app: AppState
    @Environment(\.presentationMode) var presentation
    @State private var didRecord = false

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 30)
                    ZStack {
                        Circle().stroke(FPColor.cardElev, lineWidth: 12).frame(width: 180, height: 180)
                        Circle()
                            .trim(from: 0, to: CGFloat(accuracy))
                            .stroke(LinearGradient(colors: [FPColor.accent, FPColor.glow], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(Int(accuracy * 100))%").font(FPFont.display(36)).foregroundColor(FPColor.textPrimary)
                            Text("accuracy").font(FPFont.body(12)).foregroundColor(FPColor.textMuted)
                        }
                    }

                    Text(headline).font(FPFont.display(22)).foregroundColor(FPColor.textPrimary)

                    HStack(spacing: 12) {
                        resultCell(icon: "checkmark.circle.fill", title: "Correct", value: "\(correct)/\(total)", color: FPColor.success)
                        resultCell(icon: "clock.fill", title: "Avg react", value: "\(avgMs)ms", color: FPColor.glow)
                        resultCell(icon: "flame.fill", title: "Streak", value: "\(streak)", color: FPColor.warning)
                    }
                    .padding(.horizontal, 16)

                    GlowCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Session").font(FPFont.body(11, weight: .semibold)).foregroundColor(FPColor.textMuted)
                            HStack {
                                Image(systemName: mode.icon).foregroundColor(FPColor.glow)
                                Text("\(mode.title) • \(difficulty.title)")
                                    .font(FPFont.display(17))
                                    .foregroundColor(FPColor.textPrimary)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.horizontal, 16)

                    PrimaryButton(title: "Done", icon: "checkmark") {
                        Haptics.tap(app.hapticsEnabled)
                        presentation.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)

                    NavigationLink(destination: SessionView(mode: mode, difficulty: difficulty)) {
                        Text("Play again")
                            .font(FPFont.body(15, weight: .semibold))
                            .foregroundColor(FPColor.glow)
                    }
                    Spacer().frame(height: 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !didRecord { onDone(); didRecord = true }
        }
    }

    var headline: String {
        if accuracy >= 0.9 { return "Excellent" }
        if accuracy >= 0.7 { return "Solid run" }
        if accuracy >= 0.4 { return "Keep training" }
        return "Tough round — try again"
    }

    func resultCell(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(FPFont.display(18)).foregroundColor(FPColor.textPrimary)
            Text(title).font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(FPColor.card).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

//
//  SplashView.swift
//  FocusPick
//

import SwiftUI

struct SplashView: View {
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0
    @State private var symbolScale: CGFloat = 0.6
    @State private var symbolOpacity: Double = 0
    @State private var particles: [Particle] = []
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var done = false
    let onFinish: () -> Void

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var s: CGFloat
        var o: Double
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ForEach(particles) { p in
                Circle()
                    .fill(FPColor.glow.opacity(p.o))
                    .frame(width: p.s, height: p.s)
                    .position(x: p.x, y: p.y)
                    .blur(radius: 1)
            }

            VStack(spacing: 20) {
                ZStack {
                    Circle().stroke(FPColor.accentLight.opacity(0.5), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale).opacity(ringOpacity)
                    Circle().stroke(FPColor.glow.opacity(0.6), lineWidth: 2)
                        .frame(width: 110, height: 110)
                        .scaleEffect(ringScale).opacity(ringOpacity)
                    Image(systemName: "scope")
                        .resizable().scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(FPColor.textPrimary)
                        .shadow(color: FPColor.glow, radius: 18)
                        .scaleEffect(symbolScale)
                        .opacity(symbolOpacity)
                }
                Text("Focus Pick")
                    .font(FPFont.display(34))
                    .foregroundColor(FPColor.textPrimary)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                Text("Train attention. Decide better.")
                    .font(FPFont.body(13))
                    .foregroundColor(FPColor.textMuted)
                    .opacity(titleOpacity)
            }
        }
        .onAppear { runIntro() }
    }

    private func runIntro() {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        for _ in 0..<26 {
            particles.append(Particle(
                x: .random(in: 0...w),
                y: .random(in: 0...h),
                s: .random(in: 2...5),
                o: .random(in: 0.2...0.7)
            ))
        }
        withAnimation(.easeOut(duration: 0.9)) {
            ringOpacity = 1; ringScale = 1
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.15)) {
            symbolScale = 1; symbolOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            titleOpacity = 1; titleOffset = 0
        }
        withAnimation(.linear(duration: 2.4)) {
            for i in particles.indices {
                particles[i].y -= CGFloat.random(in: 30...90)
                particles[i].o = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            if !done { done = true; onFinish() }
        }
    }
}

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppState
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            GradientBackground()
            VStack {
                TabView(selection: $page) {
                    OnboardPage(
                        index: 0, title: "Train your focus",
                        bodyText: "Cards appear. Lock in. The right one will reveal itself.",
                        scene: .stackedCards
                    ).tag(0)
                    OnboardPage(
                        index: 1, title: "Stay sharp",
                        bodyText: "Cards shuffle. Track the target. Don’t blink.",
                        scene: .shuffling
                    ).tag(1)
                    OnboardPage(
                        index: 2, title: "Make better decisions",
                        bodyText: "Pick the right card. Build your reaction and memory.",
                        scene: .pick
                    ).tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(page == i ? FPColor.glow : FPColor.cardElev)
                            .frame(width: page == i ? 22 : 8, height: 8)
                            .animation(.spring(), value: page)
                    }
                }
                .padding(.bottom, 14)

                HStack {
                    Button("Skip") {
                        Haptics.tap(app.hapticsEnabled)
                        app.hasCompletedOnboarding = true
                    }
                    .foregroundColor(FPColor.textMuted)
                    .font(FPFont.body(15, weight: .semibold))
                    Spacer()
                    PrimaryButton(title: page == 2 ? "Get Started" : "Next", icon: "arrow.right") {
                        Haptics.tap(app.hapticsEnabled)
                        if page < 2 { withAnimation { page += 1 } }
                        else { app.hasCompletedOnboarding = true }
                    }
                    .frame(width: 180)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
    }
}

struct OnboardPage: View {
    
    enum Scene { case stackedCards, shuffling, pick }
    let index: Int
    let title: String
    let bodyText: String
    let scene: Scene

    @State private var animateIn = false
    @State private var shuffleTick = 0

    var body: some View {
        VStack(spacing: 28) {
            sceneView
                .frame(height: 280)
                .padding(.top, 30)

            VStack(spacing: 10) {
                Text(title)
                    .font(FPFont.display(28))
                    .foregroundColor(FPColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(bodyText)
                    .font(FPFont.body(15))
                    .foregroundColor(FPColor.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 12)
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) { animateIn = true }
            if scene == .shuffling {
                Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in shuffleTick += 1 }
            }
        }
    }

    @ViewBuilder
    var sceneView: some View {
        switch scene {
        case .stackedCards:
            ZStack {
                ForEach(0..<3) { i in
                    onboardCard(symbol: ["scope", "sparkles", "bolt.fill"][i],
                                tint: [FPColor.accentLight, FPColor.glow, FPColor.accent][i])
                        .rotationEffect(.degrees(Double(i - 1) * 8))
                        .offset(x: CGFloat(i - 1) * 36, y: CGFloat(i - 1) * -10)
                        .scaleEffect(animateIn ? 1 : 0.7)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.1), value: animateIn)
                }
            }
        case .shuffling:
            HStack(spacing: 14) {
                ForEach(0..<4) { i in
                    onboardCard(symbol: ["circle.grid.2x2", "diamond.fill", "triangle.fill", "square.fill"][i],
                                tint: i == (shuffleTick % 4) ? FPColor.glow : FPColor.accentLight)
                        .rotationEffect(.degrees(Double((shuffleTick + i) % 4) * 4 - 8))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: shuffleTick)
                }
            }
        case .pick:
            HStack(spacing: 14) {
                ForEach(0..<3) { i in
                    onboardCard(symbol: ["scope", "scope", "scope"][i],
                                tint: i == 1 ? FPColor.glow : FPColor.accentLight,
                                glowing: i == 1)
                        .scaleEffect(i == 1 && animateIn ? 1.1 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true), value: animateIn)
                }
            }
        }
    }

    func onboardCard(symbol: String, tint: Color, glowing: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FPColor.card)
                .frame(width: 110, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(tint.opacity(0.7), lineWidth: 1.5)
                )
                .shadow(color: tint.opacity(glowing ? 0.7 : 0.3), radius: glowing ? 22 : 10)
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(tint)
        }
    }
}

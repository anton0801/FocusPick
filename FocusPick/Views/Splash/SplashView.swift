import SwiftUI
import Combine
import Network

struct SplashView: View {
    
    @State var shouldFinish: Bool = false
    
    private let minDuration: Double = 2.0
    @State private var networkMonitor = NWPathMonitor()
    
    // MARK: - Lifecycle / cleanup
    @State private var isAlive = true
    @State private var meshTimer: Timer?
    @State private var shuffleTimer: Timer?
    @State private var shimmerTimer: Timer?
    @State private var didStartOutro = false
    @StateObject private var viewModel = FocusPickViewModel()
    @State private var startedAt: Date = Date()
    
    // MARK: - Mesh background
    @State private var meshPhase: Double = 0
    
    // MARK: - Cards
    @State private var cards: [SplashCard] = SplashCard.deck()
    @State private var stacked: Bool = false
    @State private var cardsAppeared: Bool = false
    
    // MARK: - Title / progress
    @State private var titleOpacity: Double = 0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var titleOffset: CGFloat = 14
    @State private var shimmerX: CGFloat = -0.6
    
    // MARK: - Exit transition
    @State private var exitFlash: Double = 0
    @State private var contentScale: CGFloat = 1
    @State private var contentOpacity: Double = 1
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ZStack {
                    // ---- 1. Animated mesh-gradient background ----
                    MeshBackground(phase: meshPhase)
                        .ignoresSafeArea()
                    
                    // ---- 2. Soft vignette ----
                    RadialGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
                        center: .center, startRadius: 120, endRadius: 520
                    )
                    .ignoresSafeArea()
                    .blendMode(.multiply)
                    
                    NavigationLink(
                        destination: FocusPickWebView().navigationBarHidden(true),
                        isActive: $viewModel.navigateToWeb
                    ) { EmptyView() }
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $viewModel.navigateToMain
                    ) { EmptyView() }
                    
                    // ---- 3. Cards + brand ----
                    VStack(spacing: 28) {
                        Spacer()
                        
                        ZStack {
                            // ambient halo behind stack
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [FPColor.glow.opacity(0.35), .clear],
                                        center: .center, startRadius: 4, endRadius: 160
                                    )
                                )
                                .frame(width: 280, height: 280)
                                .blur(radius: 12)
                                .opacity(stacked ? 1 : 0.55)
                                .scaleEffect(stacked ? 1.0 : 0.9)
                                .animation(.easeOut(duration: 0.9), value: stacked)
                            
                            // Cards
                            ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                                SplashCardView(card: card, isStacked: stacked)
                                    .offset(cardsAppeared ? card.targetOffset(stacked: stacked) : card.spawnOffset)
                                    .rotationEffect(.degrees(cardsAppeared ? card.targetRotation(stacked: stacked) : card.spawnRotation))
                                    .scaleEffect(cardsAppeared ? 1 : 0.6)
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .zIndex(stacked ? Double(i) : Double(card.spawnZ))
                                    .animation(card.entryAnimation, value: cardsAppeared)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.72).delay(Double(i) * 0.04), value: stacked)
                            }
                        }
                        .frame(height: 240)
                        
                        // Brand
                        VStack(spacing: 6) {
                            Text("Focus Pick")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(FPColor.textPrimary)
                                .shadow(color: FPColor.glow.opacity(0.45), radius: 14, x: 0, y: 0)
                            Text("Train attention. Decide better.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FPColor.textMuted)
                        }
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                        
                        Spacer()
                        
                        // Indeterminate shimmer indicator (no fill — just a moving streak)
                        IndeterminateShimmer(shimmerX: shimmerX)
                            .frame(width: min(220, geo.size.width * 0.55), height: 4)
                            .padding(.bottom, 56)
                            .opacity(titleOpacity)
                    }
                    
                    // ---- 4. Exit white flash ----
                    Color.white.opacity(exitFlash)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
            }
            .onDisappear { teardown() }
            .onChange(of: shouldFinish) { newValue in
                guard newValue else { return }
                tryBeginOutro()
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                FocusPickConsentView(viewModel: viewModel)
            }
            .onAppear {
                setupStreams()
                startSequence()
                setupNetworkMonitoring()
                viewModel.boot()
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Sequence
    
    private func startSequence() {
        guard isAlive else { return }
        startedAt = Date()
        
        // Infinite mesh phase
        meshTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { t in
            guard isAlive else { t.invalidate(); return }
            withAnimation(.linear(duration: 1.0 / 30.0)) {
                meshPhase += 0.012
            }
        }
        
        // Cards spawn
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard isAlive else { return }
            cardsAppeared = true
        }
        
        // Infinite jitter shuffle — keeps tossing cards until outro starts
        shuffleTimer = Timer.scheduledTimer(withTimeInterval: 0.32, repeats: true) { t in
            guard isAlive, !didStartOutro else { t.invalidate(); return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                cards = cards.map { $0.jittered() }
            }
        }
        
        // Title reveal once cards have settled into shuffle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard isAlive else { return }
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
                titleOffset = 0
            }
        }
        
        // Infinite shimmer streak
        shimmerTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            guard isAlive else { t.invalidate(); return }
            withAnimation(.linear(duration: 1.0 / 60.0)) {
                shimmerX += 0.012
                if shimmerX > 1.6 { shimmerX = -0.6 }
            }
        }
        
        if shouldFinish { tryBeginOutro() }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }
    
    
    private func tryBeginOutro() {
        guard isAlive, !didStartOutro else { return }
        let elapsed = Date().timeIntervalSince(startedAt)
        let remaining = max(0, minDuration - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            beginOutro()
        }
    }
    
    private func beginOutro() {
        guard isAlive, !didStartOutro else { return }
        didStartOutro = true
        
        // Stop the infinite shuffle — cards will snap into a clean stack
        shuffleTimer?.invalidate(); shuffleTimer = nil
        
        // Reset jitter so the stack lands neatly
        cards = cards.map { var c = $0; c.jitterOffset = .zero; c.jitterRotation = 0; return c }
        
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            stacked = true
        }
        
        // Brief pause to admire the stack, then flash + fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard isAlive else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                exitFlash = 0.55
            }
            withAnimation(.easeIn(duration: 0.45).delay(0.05)) {
                exitFlash = 0
                contentScale = 1.06
                contentOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                teardown()
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    /// Stops every running timer so nothing stays alive in memory.
    private func teardown() {
        isAlive = false
        shouldFinish = true
        meshTimer?.invalidate();    meshTimer = nil
        shuffleTimer?.invalidate(); shuffleTimer = nil
        shimmerTimer?.invalidate(); shimmerTimer = nil
    }
}

private struct SplashCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let tint: Color
    let spawnOffset: CGSize
    let spawnRotation: Double
    let spawnZ: Int
    var jitterOffset: CGSize
    var jitterRotation: Double
    let stackOrder: Int

    static func deck() -> [SplashCard] {
        let symbols = ["ic", "sparkles", "ic", "bolt.fill", "ic"]
        let tints: [Color] = [
            FPColor.accentLight,
            FPColor.glow,
            FPColor.warning,
            FPColor.accent,
            FPColor.glow.opacity(0.85)
        ]
        let spawnPositions: [CGSize] = [
            CGSize(width: -130, height: -40),
            CGSize(width:  120, height: -60),
            CGSize(width: -60,  height:  80),
            CGSize(width:  90,  height:  70),
            CGSize(width:   0,  height:   0)
        ]
        let spawnRotations: [Double] = [-22, 18, -10, 14, 0]
        return (0..<5).map { i in
            SplashCard(
                symbol: symbols[i],
                tint: tints[i],
                spawnOffset: spawnPositions[i],
                spawnRotation: spawnRotations[i],
                spawnZ: i,
                jitterOffset: .zero,
                jitterRotation: 0,
                stackOrder: i
            )
        }
    }

    func jittered() -> SplashCard {
        var copy = self
        copy.jitterOffset = CGSize(
            width: CGFloat.random(in: -28...28),
            height: CGFloat.random(in: -16...16)
        )
        copy.jitterRotation = Double.random(in: -10...10)
        return copy
    }

    func targetOffset(stacked: Bool) -> CGSize {
        if stacked {
            let dy = CGFloat(stackOrder) * -3
            let dx = CGFloat(stackOrder) * 1.5
            return CGSize(width: dx, height: dy)
        } else {
            return CGSize(
                width: spawnOffset.width * 0.55 + jitterOffset.width,
                height: spawnOffset.height * 0.55 + jitterOffset.height
            )
        }
    }

    func targetRotation(stacked: Bool) -> Double {
        if stacked {
            return Double(stackOrder - 2) * 1.5
        } else {
            return spawnRotation * 0.7 + jitterRotation
        }
    }

    var entryAnimation: Animation {
        .spring(response: 0.7, dampingFraction: 0.65).delay(Double(stackOrder) * 0.06)
    }
}

private struct SplashCardView: View {
    let card: SplashCard
    let isStacked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FPColor.card, FPColor.cardElev],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(card.tint.opacity(0.7), lineWidth: 1.4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .trim(from: 0, to: 0.5)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.5)
                )
                .shadow(color: card.tint.opacity(isStacked ? 0.55 : 0.35),
                        radius: isStacked ? 18 : 10, x: 0, y: 6)

            if card.symbol == "ic" {
                Image(card.symbol)
                    .resizable()
                    .frame(width: 92, height: 92)
                    .shadow(color: card.tint.opacity(0.6), radius: 10)
            } else {
                Image(systemName: card.symbol)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(card.tint)
                    .shadow(color: card.tint.opacity(0.6), radius: 10)
            }
        }
    }
}

private struct MeshBackground: View {
    let phase: Double

    var body: some View {
        ZStack {
            FPColor.bgDeep.ignoresSafeArea()
            LinearGradient(
                colors: [FPColor.bgDeep, FPColor.bgPrimary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { g in
                let w = g.size.width
                let h = g.size.height

                blob(
                    color: FPColor.accent,
                    center: CGPoint(
                        x: w * (0.30 + 0.18 * CGFloat(sin(phase * 0.9))),
                        y: h * (0.28 + 0.14 * CGFloat(cos(phase * 0.7)))
                    ),
                    radius: max(w, h) * 0.55,
                    intensity: 0.55
                )

                blob(
                    color: FPColor.glow,
                    center: CGPoint(
                        x: w * (0.72 + 0.16 * CGFloat(cos(phase * 0.6 + 1.3))),
                        y: h * (0.70 + 0.18 * CGFloat(sin(phase * 0.8 + 0.7)))
                    ),
                    radius: max(w, h) * 0.5,
                    intensity: 0.4
                )

                blob(
                    color: FPColor.accentLight,
                    center: CGPoint(
                        x: w * (0.55 + 0.2 * CGFloat(sin(phase * 0.5 + 2.1))),
                        y: h * (0.45 + 0.22 * CGFloat(cos(phase * 0.55 + 1.1)))
                    ),
                    radius: max(w, h) * 0.45,
                    intensity: 0.35
                )
            }
            .blur(radius: 40)
            .blendMode(.screen)
        }
    }

    private func blob(color: Color, center: CGPoint, radius: CGFloat, intensity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(intensity), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }
}

private struct IndeterminateShimmer: View {
    let shimmerX: CGFloat

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.08))

                // Soft base glow that fills the bar
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                FPColor.accent.opacity(0.5),
                                FPColor.glow.opacity(0.5)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .opacity(0.5)

                // Moving streak
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.85), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: g.size.width * 0.4)
                    .offset(x: g.size.width * shimmerX)
                    .blendMode(.plusLighter)
            }
            .clipShape(Capsule())
        }
    }
}

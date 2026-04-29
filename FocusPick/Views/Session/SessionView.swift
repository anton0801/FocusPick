//
//  SessionView.swift
//  FocusPick
//

import SwiftUI

struct SessionView: View {
    let mode: TrainingMode
    let difficulty: Difficulty
    @StateObject private var vm: SessionVM
    @EnvironmentObject var app: AppState
    @Environment(\.presentationMode) var presentation

    init(mode: TrainingMode, difficulty: Difficulty) {
        self.mode = mode
        self.difficulty = difficulty
        _vm = StateObject(wrappedValue: SessionVM(mode: mode, difficulty: difficulty, totalRounds: 5))
    }

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 14) {
                // Top bar
                HStack {
                    Button {
                        Haptics.tap(app.hapticsEnabled)
                        vm.cancel(); presentation.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26)).foregroundColor(FPColor.textMuted)
                    }
                    Spacer()
                    Text("Round \(vm.round)/\(vm.totalRounds)")
                        .font(FPFont.body(13, weight: .semibold))
                        .foregroundColor(FPColor.textMuted)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(FPColor.warning)
                        Text("\(vm.streak)").font(FPFont.body(13, weight: .bold)).foregroundColor(FPColor.textPrimary)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 4)

                phaseTitle.padding(.top, 4)

                if mode == .speed && vm.phase == .selecting {
                    ProgressBar(value: vm.timeLeft, total: difficulty.speedTimeLimit)
                        .padding(.horizontal, 24)
                }

                if vm.phase == .intro {
                    VStack(spacing: 10) {
                        Text("Find this card").font(FPFont.body(13)).foregroundColor(FPColor.textMuted)
                        bigCard(symbol: vm.targetSymbol, tint: vm.targetTint, glowing: true)
                            .scaleEffect(1.0)
                    }
                }

                Spacer()

                cardsArena
                    .padding(.horizontal, 16)
                    .frame(maxHeight: 360)

                Spacer()

                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.startRound()
        }
        .onDisappear { vm.cancel() }
        .background(
            NavigationLink(
                destination: ResultView(
                    correct: vm.correct,
                    total: vm.totalRounds,
                    avgMs: vm.averageReactionMs(),
                    mode: mode,
                    difficulty: difficulty,
                    streak: vm.streak,
                    onDone: {
                        app.recordSession(mode: mode, difficulty: difficulty,
                                          correct: vm.correct, total: vm.totalRounds,
                                          avgReactionMs: vm.averageReactionMs())
                        app.updateBestStreak(vm.streak)
                    }
                ),
                isActive: Binding(
                    get: { vm.phase == .finished },
                    set: { _ in }
                )
            ) { EmptyView() }
        )
    }

    @ViewBuilder var phaseTitle: some View {
        switch vm.phase {
        case .intro:
            Text(mode == .memory ? "Memorize" : "Get ready")
                .font(FPFont.display(22))
                .foregroundColor(FPColor.textPrimary)
        case .shuffling:
            Text("Shuffling…")
                .font(FPFont.display(22))
                .foregroundColor(FPColor.glow)
        case .selecting:
            Text("Pick the right card")
                .font(FPFont.display(22))
                .foregroundColor(FPColor.textPrimary)
        case .revealed:
            HStack(spacing: 8) {
                Image(systemName: vm.lastWasCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(vm.lastWasCorrect == true ? FPColor.success : FPColor.danger)
                Text(vm.lastWasCorrect == true ? "Correct" : "Missed")
                    .font(FPFont.display(22))
                    .foregroundColor(vm.lastWasCorrect == true ? FPColor.success : FPColor.danger)
            }
        case .finished:
            Text("Session complete").font(FPFont.display(22)).foregroundColor(FPColor.textPrimary)
        }
    }

    var cardsArena: some View {
        let cols = vm.cards.count <= 3 ? vm.cards.count : (vm.cards.count <= 5 ? 3 : 4)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: max(1, cols))
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(vm.cards.enumerated()), id: \.element.id) { i, c in
                cardView(card: c, index: i)
            }
        }
    }

    func cardView(card: CardItem, index: Int) -> some View {
        let isSelected = vm.lastChosenIndex == index
        let revealed = vm.phase == .revealed
        let backShown = !(vm.isFlipped[safe: index] ?? false) ? false : true

        return Button {
            guard vm.phase == .selecting else { return }
            let ok = vm.choose(index: index)
            Haptics.tap(app.hapticsEnabled)
            if ok { Haptics.success(app.hapticsEnabled) } else { Haptics.error(app.hapticsEnabled) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring()) {
                    vm.nextRound()
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FPColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(borderColor(for: index, revealed: revealed, card: card), lineWidth: 1.4)
                    )
                    .shadow(color: glowColor(for: index, revealed: revealed, card: card).opacity(0.5),
                            radius: revealed && card.isTarget ? 22 : 12)
                    .frame(height: 110)

                if backShown {
                    Image(systemName: "questionmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(FPColor.textMuted)
                } else {
                    Image(systemName: card.symbol)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(card.tint)
                        .shadow(color: card.tint.opacity(0.5), radius: 10)
                }

                if revealed && card.isTarget {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(FPColor.success, lineWidth: 2)
                }
                if revealed && isSelected && !card.isTarget {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(FPColor.danger, lineWidth: 2)
                }
            }
            .scaleEffect(isSelected ? 1.06 : 1)
            .offset(vm.offsets[safe: index] ?? .zero)
            .rotationEffect(.degrees(vm.rotations[safe: index] ?? 0))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: vm.offsets)
            .animation(.spring(), value: vm.rotations)
            .animation(.spring(), value: vm.lastChosenIndex)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(vm.phase != .selecting)
    }

    func borderColor(for index: Int, revealed: Bool, card: CardItem) -> Color {
        if revealed && card.isTarget { return FPColor.success }
        if revealed && vm.lastChosenIndex == index && !card.isTarget { return FPColor.danger }
        return FPColor.accentLight.opacity(0.45)
    }
    func glowColor(for index: Int, revealed: Bool, card: CardItem) -> Color {
        if revealed && card.isTarget { return FPColor.success }
        return FPColor.accentLight
    }

    @ViewBuilder var bottomBar: some View {
        switch vm.phase {
        case .intro, .shuffling:
            Text(mode == .memory && vm.phase == .intro ? "Remember the position…" : "Track the cards")
                .font(FPFont.body(13)).foregroundColor(FPColor.textMuted)
        case .selecting:
            HStack {
                miniBadge(title: "Mode", value: mode.title)
                miniBadge(title: "Level", value: difficulty.title)
                miniBadge(title: "Correct", value: "\(vm.correct)")
            }
        case .revealed, .finished:
            Color.clear.frame(height: 1)
        }
    }

    func miniBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(FPFont.body(10)).foregroundColor(FPColor.textMuted)
            Text(value).font(FPFont.body(13, weight: .bold)).foregroundColor(FPColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(FPColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func bigCard(symbol: String, tint: Color, glowing: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(FPColor.card)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(tint.opacity(0.7), lineWidth: 2))
                .shadow(color: tint.opacity(glowing ? 0.7 : 0.3), radius: glowing ? 24 : 10)
                .frame(width: 130, height: 130)
            Image(systemName: symbol).font(.system(size: 50, weight: .bold)).foregroundColor(tint)
        }
    }
}

//
//  SessionVM.swift
//  FocusPick
//

import SwiftUI
import Combine

final class SessionVM: ObservableObject {
    enum Phase {
        case intro
        case shuffling
        case selecting
        case revealed
        case finished
    }

    @Published var phase: Phase = .intro
    @Published var cards: [CardItem] = []
    @Published var targetSymbol: String = ""
    @Published var targetTint: Color = .blue
    @Published var round: Int = 1
    @Published var correct: Int = 0
    @Published var streak: Int = 0
    @Published var lastChosenIndex: Int? = nil
    @Published var lastWasCorrect: Bool? = nil
    @Published var reactionTimes: [Double] = []
    @Published var offsets: [CGSize] = []
    @Published var rotations: [Double] = []
    @Published var isFlipped: [Bool] = []
    @Published var timeLeft: Double = 0
    @Published var totalRounds: Int = 5

    let mode: TrainingMode
    let difficulty: Difficulty
    private var selectionStart: Date?
    private var timer: Timer?

    private let symbols = [
        "scope", "sparkles", "diamond.fill", "triangle.fill", "square.fill",
        "circle.fill", "hexagon.fill", "octagon.fill", "moon.stars.fill",
        "flame.fill", "leaf.fill", "bolt.fill", "drop.fill", "snowflake"
    ]
    private let palette: [Color] = [
        FPColor.glow, FPColor.accentLight, FPColor.warning, FPColor.success, FPColor.danger
    ]

    init(mode: TrainingMode, difficulty: Difficulty, totalRounds: Int = 5) {
        self.mode = mode
        self.difficulty = difficulty
        self.totalRounds = totalRounds
    }

    func startRound() {
        timer?.invalidate()
        let count = difficulty.cardCount
        let chosenSymbols = Array(symbols.shuffled().prefix(count))
        let chosenColors  = (0..<count).map { _ in palette.randomElement() ?? FPColor.glow }
        let targetIdx = Int.random(in: 0..<count)
        targetSymbol = chosenSymbols[targetIdx]
        targetTint   = chosenColors[targetIdx]
        cards = (0..<count).map { i in
            CardItem(symbol: chosenSymbols[i], tint: chosenColors[i], isTarget: i == targetIdx)
        }
        offsets   = Array(repeating: .zero, count: count)
        rotations = Array(repeating: 0, count: count)
        isFlipped = Array(repeating: false, count: count)
        lastChosenIndex = nil
        lastWasCorrect = nil

        if mode == .memory {
            phase = .intro
            DispatchQueue.main.asyncAfter(deadline: .now() + difficulty.memoryShowSeconds) { [weak self] in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.isFlipped = Array(repeating: true, count: self.cards.count)
                }
                self.runShuffle()
            }
        } else {
            phase = .intro
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.runShuffle() }
        }
    }

    private func runShuffle() {
        phase = .shuffling
        let rounds = difficulty.shuffleRounds
        var step = 0
        let shuffleStep = { [weak self] in
            guard let self = self else { return }
            let count = self.cards.count
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                for i in 0..<count {
                    self.offsets[i] = CGSize(
                        width: CGFloat.random(in: -60...60),
                        height: CGFloat.random(in: -25...25)
                    )
                    self.rotations[i] = Double.random(in: -10...10)
                }
                if count >= 2 {
                    let a = Int.random(in: 0..<count)
                    var b = Int.random(in: 0..<count)
                    while b == a { b = Int.random(in: 0..<count) }
                    self.cards.swapAt(a, b)
                    self.isFlipped.swapAt(a, b)
                }
            }
        }
        let interval: TimeInterval
        switch difficulty {
        case .easy: interval = 0.55
        case .medium: interval = 0.38
        case .hard: interval = 0.25
        }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            shuffleStep()
            step += 1
            if step >= rounds {
                t.invalidate()
                withAnimation(.spring()) {
                    self.offsets = Array(repeating: .zero, count: self.cards.count)
                    self.rotations = Array(repeating: 0, count: self.cards.count)
                }
                self.beginSelection()
            }
        }
    }

    private func beginSelection() {
        phase = .selecting
        selectionStart = Date()
        if mode == .speed {
            timeLeft = difficulty.speedTimeLimit
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
                guard let self = self else { t.invalidate(); return }
                self.timeLeft -= 0.05
                if self.timeLeft <= 0 {
                    t.invalidate()
                    self.timeOut()
                }
            }
        }
    }

    func choose(index: Int) -> Bool {
        guard phase == .selecting else { return false }
        timer?.invalidate()
        let elapsed = Date().timeIntervalSince(selectionStart ?? Date())
        reactionTimes.append(elapsed)
        let chosen = cards[index]
        lastChosenIndex = index
        let isCorrect = chosen.isTarget
        lastWasCorrect = isCorrect
        if isCorrect { correct += 1; streak += 1 } else { streak = 0 }
        withAnimation(.easeInOut(duration: 0.4)) {
            isFlipped = Array(repeating: false, count: cards.count)
        }
        phase = .revealed
        return isCorrect
    }

    private func timeOut() {
        guard phase == .selecting else { return }
        reactionTimes.append(difficulty.speedTimeLimit)
        lastChosenIndex = nil
        lastWasCorrect = false
        streak = 0
        withAnimation { isFlipped = Array(repeating: false, count: cards.count) }
        phase = .revealed
    }

    func nextRound() {
        if round >= totalRounds {
            phase = .finished
            return
        }
        round += 1
        startRound()
    }

    func averageReactionMs() -> Int {
        guard !reactionTimes.isEmpty else { return 0 }
        let avg = reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        return Int(avg * 1000)
    }

    func cancel() { timer?.invalidate() }
}

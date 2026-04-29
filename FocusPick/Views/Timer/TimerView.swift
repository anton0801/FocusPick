//
//  TimerView.swift
//  FocusPick
//

import SwiftUI

final class TimerVM: ObservableObject {
    @Published var seconds: Int = 25 * 60
    @Published var running: Bool = false
    @Published var setMinutes: Int = 25
    private var t: Timer?

    func start() {
        running = true
        t?.invalidate()
        t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.seconds > 0 { self.seconds -= 1 }
            else { self.stop() }
        }
    }
    func stop() {
        running = false
        t?.invalidate()
    }
    func reset() {
        stop()
        seconds = setMinutes * 60
    }
    func setMinutes(_ m: Int) {
        setMinutes = m
        if !running { seconds = m * 60 }
    }
}

struct TimerView: View {
    @StateObject private var vm = TimerVM()
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 24) {
                SectionHeader(title: "Focus timer", subtitle: "Pure deep-work blocks")

                ZStack {
                    Circle().stroke(FPColor.cardElev, lineWidth: 14).frame(width: 240, height: 240)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(LinearGradient(colors: [FPColor.glow, FPColor.accentLight], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 240, height: 240).rotationEffect(.degrees(-90))
                    VStack {
                        Text(formatted)
                            .font(FPFont.mono(48, weight: .bold))
                            .foregroundColor(FPColor.textPrimary)
                        Text(vm.running ? "Focusing" : "Ready")
                            .font(FPFont.body(13)).foregroundColor(FPColor.textMuted)
                    }
                }

                HStack(spacing: 10) {
                    ForEach([15, 25, 45, 60], id: \.self) { m in
                        ChipView(title: "\(m) min", selected: vm.setMinutes == m) {
                            Haptics.tap(app.hapticsEnabled)
                            vm.setMinutes(m)
                        }
                    }
                }

                HStack(spacing: 10) {
                    if vm.running {
                        GhostButton(title: "Pause", icon: "pause.fill") { Haptics.tap(app.hapticsEnabled); vm.stop() }
                    } else {
                        PrimaryButton(title: "Start", icon: "play.fill") { Haptics.tap(app.hapticsEnabled); vm.start() }
                    }
                    GhostButton(title: "Reset", icon: "arrow.counterclockwise") { Haptics.tap(app.hapticsEnabled); vm.reset() }
                }
                .padding(.horizontal, 24)

                Spacer()
            }.padding(20)
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
    }

    var progress: CGFloat {
        let total = max(1, vm.setMinutes * 60)
        return CGFloat(vm.seconds) / CGFloat(total)
    }
    var formatted: String {
        let m = vm.seconds / 60
        let s = vm.seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

//
//  FocusModeView.swift
//  FocusPick
//

import SwiftUI

struct FocusModeView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack {
            FPColor.bgDeep.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FPColor.glow)
                    .shadow(color: FPColor.glow, radius: 22)
                Text(app.focusModeEnabled ? "Focus Mode On" : "Focus Mode Off")
                    .font(FPFont.display(24)).foregroundColor(FPColor.textPrimary)
                Text(app.focusModeEnabled ? "Distractions hidden in sessions." : "Tap to enable a distraction-free experience.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(FPColor.textMuted)
                    .font(FPFont.body(13))
                Toggle("Enable Focus Mode", isOn: $app.focusModeEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                    .padding(.horizontal, 40)
                    .foregroundColor(FPColor.textPrimary)
            }
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

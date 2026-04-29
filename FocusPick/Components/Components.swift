//
//  Components.swift
//  FocusPick
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            FPColor.bgDeep.ignoresSafeArea()
            LinearGradient(
                colors: [FPColor.bgDeep, FPColor.bgPrimary, FPColor.bgDeep],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()
            RadialGradient(
                colors: [FPColor.accent.opacity(0.18), .clear],
                center: .topLeading, startRadius: 20, endRadius: 380
            ).ignoresSafeArea()
            RadialGradient(
                colors: [FPColor.glow.opacity(0.10), .clear],
                center: .bottomTrailing, startRadius: 20, endRadius: 420
            ).ignoresSafeArea()
        }
    }
}

struct GlowCard<Content: View>: View {
    var glow: Color = FPColor.accentLight
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FPColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(glow.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: glow.opacity(0.25), radius: 16, x: 0, y: 6)
            )
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var disabled: Bool = false
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(FPFont.display(17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(
                LinearGradient(colors: [FPColor.accent, FPColor.accentLight],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: FPColor.accentLight.opacity(0.5), radius: 14, x: 0, y: 6)
            .scaleEffect(pressed ? 0.97 : 1)
            .opacity(disabled ? 0.5 : 1)
        }
        .disabled(disabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in pressed = true }.onEnded { _ in pressed = false })
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let i = icon { Image(systemName: i) }
                Text(title).font(FPFont.body(15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(FPColor.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FPColor.accentLight.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChipView: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FPFont.body(13, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .foregroundColor(selected ? .white : FPColor.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? FPColor.accent : FPColor.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(FPColor.accentLight.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(FPFont.display(22)).foregroundColor(FPColor.textPrimary)
            if let s = subtitle { Text(s).font(FPFont.body(13)).foregroundColor(FPColor.textMuted) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(FPColor.bgPrimary).frame(height: 8)
                Capsule().fill(LinearGradient(colors: [FPColor.accent, FPColor.glow], startPoint: .leading, endPoint: .trailing))
                    .frame(width: g.size.width * CGFloat(min(1, total == 0 ? 0 : value / total)), height: 8)
            }
        }
        .frame(height: 8)
    }
}

struct FPInput: View {
    let title: String
    @Binding var text: String
    var icon: String = "circle"
    var keyboard: UIKeyboardType = .default
    var secure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(FPFont.body(11, weight: .semibold)).foregroundColor(FPColor.textMuted)
            HStack {
                Image(systemName: icon).foregroundColor(FPColor.accentLight)
                if secure { SecureField("", text: $text) } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(keyboard == .emailAddress ? .none : .words)
                        .disableAutocorrection(true)
                }
            }
            .padding(12)
            .background(FPColor.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FPColor.cardElev, lineWidth: 1))
            .foregroundColor(FPColor.textPrimary)
        }
    }
}

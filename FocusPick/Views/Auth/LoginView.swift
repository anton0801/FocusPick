//
//  LoginView.swift
//  FocusPick
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var error: String?
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 24)
                    Text("Sign in")
                        .font(FPFont.display(28))
                        .foregroundColor(FPColor.textPrimary)
                    Text("Welcome back to Focus Pick")
                        .font(FPFont.body(13))
                        .foregroundColor(FPColor.textMuted)

                    GlowCard {
                        VStack(spacing: 14) {
                            FPInput(title: "Name", text: $name, icon: "person")
                            FPInput(title: "Email", text: $email, icon: "envelope", keyboard: .emailAddress)
                            if let e = error { Text(e).foregroundColor(FPColor.danger).font(FPFont.body(12)) }
                            PrimaryButton(title: "Login", icon: "arrow.right.circle.fill") {
                                let n = name.trimmingCharacters(in: .whitespaces)
                                let e = email.trimmingCharacters(in: .whitespaces)
                                guard !n.isEmpty else { error = "Name is required"; Haptics.error(app.hapticsEnabled); return }
                                guard e.contains("@"), e.contains(".") else { error = "Enter a valid email"; Haptics.error(app.hapticsEnabled); return }
                                Haptics.success(app.hapticsEnabled)
                                app.login(name: n, email: e)
                            }
                            // ★ DEMO ACCOUNT (clearly visible)
                            Button {
                                Haptics.success(app.hapticsEnabled)
                                app.loginDemo()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Try Demo Account").font(FPFont.body(15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(FPColor.glow)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(FPColor.glow, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            GhostButton(title: "Continue as Guest", icon: "person.crop.circle") {
                                Haptics.tap(app.hapticsEnabled)
                                app.loginAsGuest()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

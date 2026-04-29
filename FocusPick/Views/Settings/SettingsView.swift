//
//  SettingsView.swift
//  FocusPick
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 14) {
                    // Appearance
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            HStack {
                                Image(systemName: "paintpalette.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                Text("Theme").foregroundColor(FPColor.textPrimary)
                                Spacer()
                                Picker("Theme", selection: $app.themePref) {
                                    ForEach(ThemePref.allCases) { t in
                                        Text(t.title).tag(t)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                        }
                    }

                    // Sound & haptics
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feedback").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Toggle(isOn: $app.soundEnabled) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Sound").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            Toggle(isOn: $app.hapticsEnabled) {
                                HStack {
                                    Image(systemName: "waveform.path").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Haptics").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            Toggle(isOn: $app.focusModeEnabled) {
                                HStack {
                                    Image(systemName: "moon.zzz.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Focus Mode").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                        }
                    }

                    // Notifications
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Toggle(isOn: Binding(
                                get: { app.notificationsEnabled },
                                set: { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization { granted in
                                            app.notificationsEnabled = granted
                                        }
                                    } else { app.notificationsEnabled = false }
                                })
                            ) {
                                HStack {
                                    Image(systemName: "bell.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Daily reminder").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            if app.notificationsEnabled {
                                HStack {
                                    Image(systemName: "clock.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Time").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: Binding(
                                        get: {
                                            var c = DateComponents(); c.hour = app.reminderHour; c.minute = app.reminderMin
                                            return Calendar.current.date(from: c) ?? Date()
                                        },
                                        set: { d in
                                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                            app.reminderHour = c.hour ?? 19
                                            app.reminderMin  = c.minute ?? 0
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                }
                            }
                        }
                    }

                    // Data
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Button {
                                Haptics.tap(app.hapticsEnabled)
                                app.history = []
                            } label: {
                                HStack {
                                    Image(systemName: "trash").foregroundColor(FPColor.warning).frame(width: 22)
                                    Text("Clear session history").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                }
                            }.buttonStyle(PlainButtonStyle())
                            Button {
                                Haptics.tap(app.hapticsEnabled)
                                app.plan = AppState.defaultPlan()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise").foregroundColor(FPColor.warning).frame(width: 22)
                                    Text("Reset training plan").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                }
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }

                    // About
                    GlowCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            HStack {
                                Text("Version").foregroundColor(FPColor.textMuted)
                                Spacer()
                                Text("1.0.0").foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                            }
                            HStack {
                                Text("Build").foregroundColor(FPColor.textMuted)
                                Spacer()
                                Text("100").foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                            }
                        }
                    }

                    // Account actions
                    if app.isLoggedIn {
                        Button {
                            Haptics.tap(app.hapticsEnabled)
                            showLogoutConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(FPColor.warning)
                                Text("Log out").foregroundColor(FPColor.warning)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(FPColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FPColor.warning.opacity(0.6), lineWidth: 1))
                        }.buttonStyle(PlainButtonStyle())

                        Button {
                            Haptics.tap(app.hapticsEnabled)
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill").foregroundColor(FPColor.danger)
                                Text("Delete account").foregroundColor(FPColor.danger)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(FPColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FPColor.danger.opacity(0.6), lineWidth: 1))
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Spacer().frame(height: 60)
                }.padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showLogoutConfirm) {
            Alert(
                title: Text("Log out?"),
                message: Text("Your data stays on this device."),
                primaryButton: .destructive(Text("Log out"), action: {
                    Haptics.success(app.hapticsEnabled)
                    app.logout()
                }),
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Delete account?"),
                message: Text("This will permanently erase your profile, history, achievements and settings on this device."),
                primaryButton: .destructive(Text("Continue"), action: {
                    showDeleteFinalConfirm = true
                }),
                secondaryButton: .cancel()
            )
        }
        .background(
            EmptyView()
                .alert(isPresented: $showDeleteFinalConfirm) {
                    Alert(
                        title: Text("Are you absolutely sure?"),
                        message: Text("This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete forever"), action: {
                            Haptics.error(app.hapticsEnabled)
                            app.deleteAccount()
                        }),
                        secondaryButton: .cancel()
                    )
                }
        )
    }
}

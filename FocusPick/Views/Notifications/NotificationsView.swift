//
//  NotificationsView.swift
//  FocusPick
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject var app: AppState
    @State private var pendingSummary: String = ""

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 14) {
                    GlowCard {
                        VStack(spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { app.notificationsEnabled },
                                set: { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization { granted in
                                            app.notificationsEnabled = granted
                                            refreshPending()
                                        }
                                    } else {
                                        app.notificationsEnabled = false
                                        refreshPending()
                                    }
                                })
                            ) {
                                HStack {
                                    Image(systemName: "bell.fill").foregroundColor(FPColor.glow)
                                    Text("Daily reminder").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))

                            if app.notificationsEnabled {
                                HStack {
                                    Text("Time").foregroundColor(FPColor.textMuted)
                                    Spacer()
                                    DatePicker("", selection: Binding(
                                        get: {
                                            var c = DateComponents()
                                            c.hour = app.reminderHour; c.minute = app.reminderMin
                                            return Calendar.current.date(from: c) ?? Date()
                                        }, set: { date in
                                            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                                            app.reminderHour = c.hour ?? 19
                                            app.reminderMin  = c.minute ?? 0
                                            refreshPending()
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                }
                            }
                            Text(pendingSummary)
                                .font(FPFont.body(11)).foregroundColor(FPColor.textMuted)
                        }
                    }

                    GhostButton(title: "Send a test in 5s", icon: "paperplane.fill") {
                        let content = UNMutableNotificationContent()
                        content.title = "Focus Pick"
                        content.body  = "This is a test reminder."
                        content.sound = .default
                        let trig = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        let req = UNNotificationRequest(identifier: "fp.test", content: content, trigger: trig)
                        UNUserNotificationCenter.current().add(req)
                        refreshPending()
                    }
                }.padding(20)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshPending() }
    }

    func refreshPending() {
        NotificationManager.shared.pendingPreviewSummary { s in pendingSummary = s }
    }
}

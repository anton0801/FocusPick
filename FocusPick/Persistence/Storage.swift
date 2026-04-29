//
//  Storage.swift
//  FocusPick
//

import Foundation

enum StorageKeys {
    static let onboarding   = "fp.hasCompletedOnboarding"
    static let isLoggedIn   = "fp.isLoggedIn"
    static let userProfile  = "fp.userProfile"
    static let history      = "fp.sessionHistory"
    static let achievements = "fp.achievements"
    static let dailyChallenge = "fp.dailyChallenge"
    static let plan         = "fp.trainingPlan"
    static let theme        = "fp.themePref"
    static let soundEnabled = "fp.soundEnabled"
    static let hapticsEnabled = "fp.hapticsEnabled"
    static let notifEnabled = "fp.notifEnabled"
    static let reminderHour = "fp.reminderHour"
    static let reminderMin  = "fp.reminderMin"
    static let focusMode    = "fp.focusMode"
    static let totalSessions = "fp.totalSessions"
    static let totalCorrect  = "fp.totalCorrect"
    static let bestStreak    = "fp.bestStreak"
    static let xp            = "fp.xp"
}

enum JSONStore {
    static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

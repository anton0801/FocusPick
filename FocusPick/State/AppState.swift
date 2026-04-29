//
//  AppState.swift
//  FocusPick
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    // MARK: - Auth / onboarding
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: StorageKeys.onboarding) }
    }
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: StorageKeys.isLoggedIn) }
    }
    @Published var profile: UserProfile? {
        didSet { JSONStore.save(profile, key: StorageKeys.userProfile) }
    }

    // MARK: - Settings
    @Published var themePref: ThemePref {
        didSet { UserDefaults.standard.set(themePref.rawValue, forKey: StorageKeys.theme) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: StorageKeys.soundEnabled) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: StorageKeys.hapticsEnabled) }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: StorageKeys.notifEnabled)
            if notificationsEnabled { NotificationManager.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMin) }
            else { NotificationManager.shared.cancelDailyReminder() }
        }
    }
    @Published var reminderHour: Int {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: StorageKeys.reminderHour)
            if notificationsEnabled { NotificationManager.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMin) }
        }
    }
    @Published var reminderMin: Int {
        didSet {
            UserDefaults.standard.set(reminderMin, forKey: StorageKeys.reminderMin)
            if notificationsEnabled { NotificationManager.shared.scheduleDailyReminder(hour: reminderHour, minute: reminderMin) }
        }
    }
    @Published var focusModeEnabled: Bool {
        didSet { UserDefaults.standard.set(focusModeEnabled, forKey: StorageKeys.focusMode) }
    }

    // MARK: - Stats
    @Published var totalSessions: Int {
        didSet { UserDefaults.standard.set(totalSessions, forKey: StorageKeys.totalSessions) }
    }
    @Published var totalCorrect: Int {
        didSet { UserDefaults.standard.set(totalCorrect, forKey: StorageKeys.totalCorrect) }
    }
    @Published var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: StorageKeys.bestStreak) }
    }
    @Published var xp: Int {
        didSet { UserDefaults.standard.set(xp, forKey: StorageKeys.xp) }
    }

    // MARK: - History & content
    @Published var history: [SessionResult] {
        didSet { JSONStore.save(history, key: StorageKeys.history) }
    }
    @Published var achievements: [Achievement] {
        didSet { JSONStore.save(achievements, key: StorageKeys.achievements) }
    }
    @Published var dailyChallenge: DailyChallenge? {
        didSet { JSONStore.save(dailyChallenge, key: StorageKeys.dailyChallenge) }
    }
    @Published var plan: [TrainingPlanDay] {
        didSet { JSONStore.save(plan, key: StorageKeys.plan) }
    }

    init() {
        let d = UserDefaults.standard
        hasCompletedOnboarding = d.bool(forKey: StorageKeys.onboarding)
        isLoggedIn  = d.bool(forKey: StorageKeys.isLoggedIn)
        profile     = JSONStore.load(UserProfile.self, key: StorageKeys.userProfile)

        themePref = ThemePref(rawValue: d.string(forKey: StorageKeys.theme) ?? "dark") ?? .dark
        soundEnabled    = d.object(forKey: StorageKeys.soundEnabled)    as? Bool ?? true
        hapticsEnabled  = d.object(forKey: StorageKeys.hapticsEnabled)  as? Bool ?? true
        notificationsEnabled = d.object(forKey: StorageKeys.notifEnabled) as? Bool ?? false
        reminderHour    = d.object(forKey: StorageKeys.reminderHour)    as? Int  ?? 19
        reminderMin     = d.object(forKey: StorageKeys.reminderMin)     as? Int  ?? 0
        focusModeEnabled = d.object(forKey: StorageKeys.focusMode)      as? Bool ?? false

        totalSessions = d.integer(forKey: StorageKeys.totalSessions)
        totalCorrect  = d.integer(forKey: StorageKeys.totalCorrect)
        bestStreak    = d.integer(forKey: StorageKeys.bestStreak)
        xp            = d.integer(forKey: StorageKeys.xp)

        history       = JSONStore.load([SessionResult].self, key: StorageKeys.history) ?? []
        achievements  = JSONStore.load([Achievement].self, key: StorageKeys.achievements) ?? AppState.defaultAchievements()
        dailyChallenge = JSONStore.load(DailyChallenge.self, key: StorageKeys.dailyChallenge)
        plan          = JSONStore.load([TrainingPlanDay].self, key: StorageKeys.plan) ?? AppState.defaultPlan()

        ensureDailyChallengeForToday()
    }

    // MARK: - Defaults
    static func defaultAchievements() -> [Achievement] {
        [
            Achievement(key: "first_session", title: "First Pick",    detail: "Complete your first session",         icon: "star.fill",        unlocked: false),
            Achievement(key: "streak_5",       title: "Hot Streak",    detail: "Get 5 correct in a row",              icon: "flame.fill",       unlocked: false),
            Achievement(key: "speed_demon",    title: "Speed Demon",   detail: "Hit Hard in Speed mode",              icon: "bolt.fill",        unlocked: false),
            Achievement(key: "memory_master",  title: "Memory Master", detail: "Win Memory mode on Hard",             icon: "brain.head.profile", unlocked: false),
            Achievement(key: "daily_done",     title: "Daily Done",    detail: "Finish a daily challenge",            icon: "checkmark.seal.fill", unlocked: false),
            Achievement(key: "ten_sessions",   title: "Ten Up",        detail: "Complete 10 sessions",                icon: "10.circle.fill",   unlocked: false),
            Achievement(key: "century",        title: "Century Club",  detail: "Earn 100 correct answers total",      icon: "rosette",          unlocked: false),
            Achievement(key: "plan_starter",   title: "Plan Starter",  detail: "Complete day 1 of training plan",     icon: "flag.fill",        unlocked: false)
        ]
    }

    static func defaultPlan() -> [TrainingPlanDay] {
        [
            TrainingPlanDay(dayNumber: 1, mode: .focus,  difficulty: .easy,   rounds: 5, completed: false),
            TrainingPlanDay(dayNumber: 2, mode: .memory, difficulty: .easy,   rounds: 5, completed: false),
            TrainingPlanDay(dayNumber: 3, mode: .speed,  difficulty: .easy,   rounds: 5, completed: false),
            TrainingPlanDay(dayNumber: 4, mode: .focus,  difficulty: .medium, rounds: 6, completed: false),
            TrainingPlanDay(dayNumber: 5, mode: .memory, difficulty: .medium, rounds: 6, completed: false),
            TrainingPlanDay(dayNumber: 6, mode: .speed,  difficulty: .medium, rounds: 6, completed: false),
            TrainingPlanDay(dayNumber: 7, mode: .focus,  difficulty: .hard,   rounds: 7, completed: false)
        ]
    }

    // MARK: - Daily Challenge logic
    func ensureDailyChallengeForToday() {
        let key = AppState.todayKey()
        if dailyChallenge?.dateKey != key {
            let modes: [TrainingMode] = TrainingMode.allCases
            let diffs: [Difficulty] = Difficulty.allCases
            let m = modes.randomElement() ?? .focus
            let d = diffs.randomElement() ?? .easy
            dailyChallenge = DailyChallenge(mode: m, difficulty: d, targetRounds: 5, completedRounds: 0, dateKey: key)
        }
    }

    static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - Session bookkeeping
    func recordSession(mode: TrainingMode, difficulty: Difficulty, correct: Int, total: Int, avgReactionMs: Int) {
        let r = SessionResult(date: Date(), mode: mode, difficulty: difficulty, correct: correct, total: total, avgReactionMs: avgReactionMs)
        history.insert(r, at: 0)
        totalSessions += 1
        totalCorrect  += correct
        xp            += correct * 10 + (difficulty == .hard ? 15 : difficulty == .medium ? 8 : 4)

        if var dc = dailyChallenge, dc.mode == mode, dc.difficulty == difficulty, !dc.isComplete {
            dc.completedRounds = min(dc.targetRounds, dc.completedRounds + total)
            dailyChallenge = dc
            if dc.isComplete { unlock(key: "daily_done") }
        }

        if let idx = plan.firstIndex(where: { !$0.completed && $0.mode == mode && $0.difficulty == difficulty }) {
            plan[idx].completed = true
            if plan[idx].dayNumber == 1 { unlock(key: "plan_starter") }
        }

        evaluateAchievements(lastResult: r)
    }

    func updateBestStreak(_ s: Int) {
        if s > bestStreak { bestStreak = s }
        if s >= 5 { unlock(key: "streak_5") }
    }

    private func evaluateAchievements(lastResult r: SessionResult) {
        if totalSessions >= 1 { unlock(key: "first_session") }
        if totalSessions >= 10 { unlock(key: "ten_sessions") }
        if totalCorrect  >= 100 { unlock(key: "century") }
        if r.mode == .speed  && r.difficulty == .hard && r.correct >= 1 { unlock(key: "speed_demon") }
        if r.mode == .memory && r.difficulty == .hard && r.correct >= 1 { unlock(key: "memory_master") }
    }

    private func unlock(key: String) {
        if let i = achievements.firstIndex(where: { $0.key == key }), !achievements[i].unlocked {
            achievements[i].unlocked = true
        }
    }

    // MARK: - Auth
    func loginAsGuest() {
        profile = UserProfile(name: "Guest", email: "", isGuest: true, createdAt: Date())
        isLoggedIn = true
    }
    func login(name: String, email: String) {
        profile = UserProfile(name: name, email: email, isGuest: false, createdAt: Date())
        isLoggedIn = true
    }
    func loginDemo() {
        profile = UserProfile(name: "Demo Account", email: "demo@focuspick.app", isGuest: false, createdAt: Date())
        isLoggedIn = true
    }
    func logout() {
        isLoggedIn = false
        profile = nil
    }

    func deleteAccount() {
        let keys: [String] = [
            StorageKeys.onboarding, StorageKeys.isLoggedIn, StorageKeys.userProfile,
            StorageKeys.history, StorageKeys.achievements, StorageKeys.dailyChallenge,
            StorageKeys.plan, StorageKeys.theme, StorageKeys.soundEnabled,
            StorageKeys.hapticsEnabled, StorageKeys.notifEnabled, StorageKeys.reminderHour,
            StorageKeys.reminderMin, StorageKeys.focusMode, StorageKeys.totalSessions,
            StorageKeys.totalCorrect, StorageKeys.bestStreak, StorageKeys.xp
        ]
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
        NotificationManager.shared.cancelDailyReminder()

        hasCompletedOnboarding = false
        isLoggedIn = false
        profile = nil
        themePref = .dark
        soundEnabled = true
        hapticsEnabled = true
        notificationsEnabled = false
        reminderHour = 19
        reminderMin = 0
        focusModeEnabled = false
        totalSessions = 0
        totalCorrect = 0
        bestStreak = 0
        xp = 0
        history = []
        achievements = AppState.defaultAchievements()
        plan = AppState.defaultPlan()
        dailyChallenge = nil
        ensureDailyChallengeForToday()
    }
}

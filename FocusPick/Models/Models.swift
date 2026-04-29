//
//  Models.swift
//  FocusPick
//

import SwiftUI

enum TrainingMode: String, CaseIterable, Codable, Identifiable {
    case focus, memory, speed
    var id: String { rawValue }
    var title: String {
        switch self {
        case .focus:  return "Focus"
        case .memory: return "Memory"
        case .speed:  return "Speed"
        }
    }
    var subtitle: String {
        switch self {
        case .focus:  return "Spot the target among distractors"
        case .memory: return "Remember and recall the right card"
        case .speed:  return "Pick fast — beat the clock"
        }
    }
    var icon: String {
        switch self {
        case .focus:  return "scope"
        case .memory: return "brain.head.profile"
        case .speed:  return "bolt.fill"
        }
    }
}

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var cardCount: Int {
        switch self {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 7
        }
    }
    var shuffleRounds: Int {
        switch self {
        case .easy: return 4
        case .medium: return 7
        case .hard: return 11
        }
    }
    var memoryShowSeconds: Double {
        switch self {
        case .easy: return 2.0
        case .medium: return 1.4
        case .hard: return 0.9
        }
    }
    var speedTimeLimit: Double {
        switch self {
        case .easy: return 4.0
        case .medium: return 2.5
        case .hard: return 1.5
        }
    }
}

struct CardItem: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let tint: Color
    var isTarget: Bool
}

struct SessionResult: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let mode: TrainingMode
    let difficulty: Difficulty
    let correct: Int
    let total: Int
    let avgReactionMs: Int
    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let key: String
    let title: String
    let detail: String
    let icon: String
    var unlocked: Bool
}

struct DailyChallenge: Codable {
    let mode: TrainingMode
    let difficulty: Difficulty
    let targetRounds: Int
    var completedRounds: Int
    let dateKey: String   // yyyy-MM-dd
    var isComplete: Bool { completedRounds >= targetRounds }
}

struct TrainingPlanDay: Identifiable, Codable {
    var id = UUID()
    let dayNumber: Int
    let mode: TrainingMode
    let difficulty: Difficulty
    let rounds: Int
    var completed: Bool
}

struct UserProfile: Codable {
    var name: String
    var email: String
    var isGuest: Bool
    var createdAt: Date
}

enum ThemePref: String, CaseIterable, Identifiable {
    case system, dark, light
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

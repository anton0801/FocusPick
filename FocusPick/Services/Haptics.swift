//
//  Haptics.swift
//  FocusPick
//

import UIKit

enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    static func error(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}

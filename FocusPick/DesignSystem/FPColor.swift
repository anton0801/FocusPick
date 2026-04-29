//
//  FPColor.swift
//  FocusPick
//

import SwiftUI

enum FPColor {
    static let bgDeep      = Color(hex: "#020617")
    static let bgPrimary   = Color(hex: "#0B1220")
    static let card        = Color(hex: "#1E293B")
    static let cardElev    = Color(hex: "#243049")
    static let accent      = Color(hex: "#1D4ED8")
    static let accentLight = Color(hex: "#3B82F6")
    static let glow        = Color(hex: "#22D3EE")
    static let textPrimary = Color(hex: "#E2E8F0")
    static let textMuted   = Color(hex: "#94A3B8")
    static let success     = Color(hex: "#10B981")
    static let danger      = Color(hex: "#EF4444")
    static let warning     = Color(hex: "#F59E0B")
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let a, r, g, b: UInt64
        switch s.count {
        case 3:  (a, r, g, b) = (255, (v >> 8) * 17, (v >> 4 & 0xF) * 17, (v & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, v >> 16, v >> 8 & 0xFF, v & 0xFF)
        case 8:  (a, r, g, b) = (v >> 24, v >> 16 & 0xFF, v >> 8 & 0xFF, v & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}

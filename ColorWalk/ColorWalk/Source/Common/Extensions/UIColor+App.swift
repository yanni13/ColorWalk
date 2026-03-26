//
//  UIColor+App.swift
//  ColorWalk
//

import UIKit

// MARK: - Hex Init

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255,
            blue:  CGFloat( rgb & 0x0000FF)         / 255,
            alpha: 1
        )
    }
}

// MARK: - Hex String

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Design System Palette

extension UIColor {
    enum App {
        // Accent
        static let accentBlue   = UIColor(hex: "#5B8DEF")
        static let accentPink   = UIColor(hex: "#FF7EB3")
        static let accentGreen  = UIColor(hex: "#34D399")
        static let accentOrange = UIColor(hex: "#FFB347")
        static let accentPurple = UIColor(hex: "#9B7DFF")
        static let accentGray   = UIColor(hex: "#94A3B8")

        // Text
        static let textPrimary   = UIColor(hex: "#191F28")
        static let textSecondary = UIColor(hex: "#6B7684")
        static let textTertiary  = UIColor(hex: "#B0B8C1")

        // Background
        static let bgCard      = UIColor.white
        static let bgPrimary   = UIColor.white
        static let bgSecondary = UIColor(hex: "#F7F8FA")

        // Border / Divider
        static let border   = UIColor(hex: "#ECEEF2")
        static let divider  = UIColor(hex: "#E5E8EB")

        // Semantic (사용 빈도 높은 기존 값)
        static let ink       = UIColor(hex: "#1A1A1A")   // 버튼, 진한 텍스트
        static let paginationActive   = UIColor(hex: "#191F28")
        static let paginationInactive = UIColor(hex: "#B0B8C1")
        static let progressStart = UIColor(hex: "#3182F6")
        static let progressEnd   = UIColor(hex: "#5B9CF6")
    }
}

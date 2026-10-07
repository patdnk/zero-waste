//
//  Constants.swift
//  ZeroWaste
//
//  Colour tokens: a warm, slightly darkened red / orange / yellow palette with light and
//  dark pairs so the app reads correctly in both appearances.
//

import SwiftUI

enum Constants {

    // MARK: - Surfaces

    static let BackgroundPrimary = dyn(light: 0xFFFBF7, dark: 0x201816)
    static let BackgroundSecondary = dyn(light: 0xF6EEE6, dark: 0x140F0D)
    static let CardTint = dyn(light: 0xF3E1D2, dark: 0x2C201A)
    /// Card and input fill.
    static let Surface = dyn(light: 0xFFFFFF, dark: 0x2A201C)
    /// 1pt card, input and tab bar borders.
    static let Hairline = dyn(light: 0xEEE1D5, dark: 0x3A2C25)
    /// Unselected chips, secondary buttons, empty progress tracks.
    static let ChipFill = dyn(light: 0xF6EEE6, dark: 0x352821)

    // MARK: - Text

    static let TextPrimary = dyn(light: 0x2B1A12, dark: 0xF7F0EA)
    static let TextSecondary = dyn(light: 0x7A5C4E, dark: 0xC3B2A8)
    static let TextMuted = dyn(light: 0xA08779, dark: 0x8F7D73)
    /// Text on an `Ink` fill (selected chips, primary buttons).
    static let OnInk = dyn(light: 0xFFFBF7, dark: 0x201816)

    // MARK: - Brand ramp (dark red → burnt orange → mustard)

    static let Brand = dyn(light: 0xB23A22, dark: 0xD9573B)
    static let BrandOrange = dyn(light: 0xC2611A, dark: 0xE07B2E)
    static let BrandYellow = dyn(light: 0xC2941A, dark: 0xE0B33A)

    // MARK: - Status

    static let StatusExpired = dyn(light: 0x9B1C1C, dark: 0xE24B4B)
    static let StatusToday = dyn(light: 0xC2611A, dark: 0xE07B2E)
    static let StatusSoon = dyn(light: 0xC2941A, dark: 0xE0B33A)
    /// Kept as a muted olive so "fine" is still distinguishable from the warning ramp.
    static let StatusFresh = dyn(light: 0x6E7F1E, dark: 0x9DB33A)

    private static func dyn(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension ExpiryStatus {
    var tint: Color {
        switch self {
        case .expired: Constants.StatusExpired
        case .today: Constants.StatusToday
        case .soon: Constants.StatusSoon
        case .fresh: Constants.StatusFresh
        }
    }

    var symbol: String {
        switch self {
        case .expired: "xmark.octagon.fill"
        case .today: "exclamationmark.triangle.fill"
        case .soon: "clock.badge.exclamationmark"
        case .fresh: "checkmark.circle.fill"
        }
    }
}

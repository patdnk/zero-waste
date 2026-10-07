//
//  Theme.swift
//  ZeroWaste
//
//  Shape and spacing tokens plus the small set of surface modifiers every screen is built from.
//  Corners are deliberately tight (3–4pt) so the app reads as bespoke rather than stock iOS.
//

import SwiftUI

enum Radius {
    /// Cards, panels, image placeholders.
    static let card: CGFloat = 4
    /// Buttons, chips, inputs, icon tiles.
    static let control: CGFloat = 3
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    /// Horizontal page gutter.
    static let gutter: CGFloat = 16
}

// MARK: - Surfaces

extension View {
    /// White card with a hairline border. `accent` draws a status edge down the leading side.
    func cardStyle(accent: Color? = nil, padding: CGFloat = Spacing.md) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.Surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Constants.Hairline)
            }
            .overlay(alignment: .leading) {
                if let accent {
                    UnevenRoundedRectangle(topLeadingRadius: Radius.card, bottomLeadingRadius: Radius.card)
                        .fill(accent)
                        .frame(width: 3)
                }
            }
    }

    /// Full-screen page background used by every screen.
    func pageBackground() -> some View {
        background(Constants.BackgroundPrimary.ignoresSafeArea())
    }
}

/// Square-ish tinted tile holding an SF Symbol (category icons, header buttons).
struct IconTile: View {
    let symbol: String
    var tint: Color = Constants.TextPrimary
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.48, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control))
    }
}

/// Bordered square button used in screen headers (add, edit, more).
struct HeaderIconButtonLabel: View {
    let symbol: String
    /// Bordered white tile on page backgrounds; borderless tonal tile for closing sheets.
    var bordered = true

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Constants.TextPrimary)
            .frame(width: 38, height: 38)
            .background(bordered ? Constants.Surface : Constants.ChipFill, in: RoundedRectangle(cornerRadius: Radius.control))
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: Radius.control).strokeBorder(Constants.Hairline)
                }
            }
            .contentShape(Rectangle())
    }
}

/// Thin horizontal progress bar with square ends.
struct ShelfLifeBar: View {
    /// 0 = just bought, 1 = at (or past) the date.
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Constants.ChipFill)
                Rectangle().fill(tint).frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

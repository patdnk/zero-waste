//
//  AppFont.swift
//  ZeroWaste
//
//  Typography. Uses Mona Sans when the variable TTF is bundled (see scripts/fetch-fonts.sh)
//  and falls back to the system font otherwise, so the app always builds and runs.
//

import CoreText
import SwiftUI
import UIKit

enum AppFont {

    /// Registered family name for Mona Sans, or nil when the font isn't bundled.
    /// Call `registerBundledFonts()` before first use.
    static let familyName: String? = UIFont.familyNames.first { $0.lowercased().contains("mona sans") }

    /// Registers any font files shipped in the bundle. Done at runtime rather than via
    /// `UIAppFonts` so a missing file (font not fetched yet) is silent instead of an error.
    static func registerBundledFonts(bundle: Bundle = .main) {
        for url in bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static var isBundled: Bool { familyName != nil }

    static func uiFont(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let size = UIFont.preferredFont(forTextStyle: style).pointSize
        guard let family = familyName else {
            return .systemFont(ofSize: size, weight: weight)
        }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: weight.rawValue],
        ])
        return UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: size))
    }

    /// Applies the font to UIKit-drawn chrome (navigation and tab bars).
    @MainActor
    static func configureAppearance() {
        guard isBundled else { return }
        let navigationBar = UINavigationBar.appearance()
        navigationBar.largeTitleTextAttributes = [.font: uiFont(.largeTitle, weight: .bold)]
        navigationBar.titleTextAttributes = [.font: uiFont(.headline, weight: .semibold)]
        UITabBarItem.appearance().setTitleTextAttributes([.font: uiFont(.caption2, weight: .medium)], for: .normal)
    }
}

extension Font {
    /// App typeface at a Dynamic Type style: `.font(.app(.headline, weight: .semibold))`.
    static func app(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        guard let family = AppFont.familyName else {
            return .system(style, weight: weight)
        }
        return .custom(family, size: style.uiTextStyle.pointSize, relativeTo: style).weight(weight)
    }
}

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}

private extension UIFont.TextStyle {
    var pointSize: CGFloat { UIFont.preferredFont(forTextStyle: self).pointSize }
}

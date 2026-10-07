//
//  Marketing.swift
//  App Store screenshot composition: a headline, a framed device capture and, on some panels,
//  an enlarged "pop-out" of one card from that capture. Raw captures live in appstore/raw
//  (iPhone 17 Pro Max simulator, 1320 × 2868); see appstore/README.md.
//

import AppKit
import CoreText
import SwiftUI

@MainActor
enum Marketing {

    /// Output sizes App Store Connect accepts for iPhone: 6.9" (required) and 6.5".
    static let sizes: [(name: String, width: CGFloat, height: CGFloat)] = [
        ("6.9in", 1320, 2868),
        ("6.5in", 1284, 2778),
    ]

    static func render(rawDirectory: URL, outDirectory: URL) throws {
        registerFont()
        for size in sizes {
            let folder = outDirectory.appendingPathComponent(size.name)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for (index, panel) in panels.enumerated() {
                guard let screen = NSImage(contentsOf: rawDirectory.appendingPathComponent(panel.capture + ".png")) else {
                    print("missing capture \(panel.capture).png")
                    continue
                }
                let popOutSource = panel.popOutCapture.flatMap { NSImage(contentsOf: rawDirectory.appendingPathComponent($0 + ".png")) }
                let view = PanelView(panel: panel, screen: screen, popOutSource: popOutSource, scale: size.width / 1320)
                let url = folder.appendingPathComponent(String(format: "%02d-%@.png", index + 1, panel.id))
                try RenderAssets.write(view, width: size.width, height: size.height, opaque: true, to: url)
            }
        }
        try renderOverview(rawDirectory: rawDirectory, outDirectory: outDirectory)
    }

    // MARK: - Content

    struct Panel {
        enum Background { case ink, terracotta, cream, red, peach, deep }

        let id: String
        let headline: String
        let subhead: String
        let capture: String
        let background: Background
        /// Region of the capture (in capture pixels) to lift out and enlarge over the phone.
        var popOut: CGRect?
        /// Take the pop-out from a different capture, floated at a fixed height instead of in place.
        var popOutCapture: String?
        var showsLockup = false
        var showsNotification = false
    }

    static let panels: [Panel] = [
        Panel(id: "waste-less", headline: "Waste less.\nCook more.", subhead: "Your fridge, sorted by what to use first",
              capture: "fridge", background: .ink, showsLockup: true),
        Panel(id: "use-first", headline: "Know what\nto use first", subhead: "The most urgent food sits on top, with one-tap Used it and Freeze",
              capture: "fridge", background: .terracotta, popOut: CGRect(x: 49, y: 473, width: 1222, height: 480)),
        Panel(id: "scan", headline: "Scan the label,\nskip the typing", subhead: "Dates and barcodes are read on your phone",
              capture: "add-food", background: .peach,
              popOut: CGRect(x: 160, y: 590, width: 1000, height: 840), popOutCapture: "onboarding-scan"),
        Panel(id: "cook", headline: "Cook what's\nabout to expire", subhead: "Recipes ranked by what's already in your fridge",
              capture: "recipes", background: .red, popOut: CGRect(x: 49, y: 967, width: 1222, height: 631)),
        Panel(id: "ingredients", headline: "Every ingredient,\nchecked for you", subhead: "See what you have, what's going off, and what's missing",
              capture: "recipe-detail", background: .cream),
        Panel(id: "reminders", headline: "A nudge before\nit goes off", subhead: "Reminders before the date, on the day, and after",
              capture: "item-detail", background: .deep, showsNotification: true),
    ]

    // MARK: - Font

    static var family = "Mona Sans"

    static func registerFont() {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let font = root.appendingPathComponent("ZeroBite/Resources/Fonts/Mona-Sans.ttf")
        CTFontManagerRegisterFontsForURL(font as CFURL, .process, nil)
        if let match = NSFontManager.shared.availableFontFamilies.first(where: { $0.lowercased().contains("mona sans") }) {
            family = match
        } else {
            print("warning: Mona Sans not found (run scripts/fetch-fonts.sh); falling back to the system font")
            family = ""
        }
    }

    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        family.isEmpty ? .system(size: size, weight: weight) : .custom(family, size: size).weight(weight)
    }

    // MARK: - Overview sheet (all 6.9" panels side by side, for review)

    static func renderOverview(rawDirectory: URL, outDirectory: URL) throws {
        let thumbs = panels.compactMap { panel -> AnyView? in
            guard let screen = NSImage(contentsOf: rawDirectory.appendingPathComponent(panel.capture + ".png")) else { return nil }
            let popOutSource = panel.popOutCapture.flatMap { NSImage(contentsOf: rawDirectory.appendingPathComponent($0 + ".png")) }
            return AnyView(PanelView(panel: panel, screen: screen, popOutSource: popOutSource, scale: 1)
                .frame(width: 1320, height: 2868)
                .scaleEffect(0.25, anchor: .topLeading)
                .frame(width: 330, height: 717, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: 12)))
        }
        let sheet = HStack(spacing: 24) {
            ForEach(thumbs.indices, id: \.self) { thumbs[$0] }
        }
        .padding(40)
        .background(Color(red: 0.11, green: 0.08, blue: 0.07))
        let width = CGFloat(thumbs.count) * 330 + CGFloat(thumbs.count - 1) * 24 + 80
        try RenderAssets.write(sheet, width: width, height: 717 + 80, opaque: true, to: outDirectory.appendingPathComponent("overview.png"))
    }
}

// MARK: - Panel

private struct PanelView: View {
    let panel: Marketing.Panel
    let screen: NSImage
    var popOutSource: NSImage?
    /// Output width ÷ 1320, so 6.5" panels keep the same proportions.
    let scale: CGFloat

    private var palette: (top: Color, bottom: Color, text: Color, subtext: Color) {
        switch panel.background {
        case .ink: (rgb(0x3A2419), rgb(0x1E120D), rgb(0xFFFBF7), rgb(0xE9D6C6))
        case .terracotta: (rgb(0xD9783A), rgb(0xA8471F), rgb(0xFFFBF7), rgb(0xFBE3D2))
        case .peach: (rgb(0xFBE7D6), rgb(0xF2C9A7), rgb(0x2B1A12), rgb(0x7A4A30))
        case .red: (rgb(0xC9472B), rgb(0x8E2A17), rgb(0xFFFBF7), rgb(0xF8D8CC))
        case .cream: (rgb(0xFFFBF7), rgb(0xF1E3D6), rgb(0x2B1A12), rgb(0x7A5C4E))
        case .deep: (rgb(0x2B1A12), rgb(0x4A2A1B), rgb(0xFFFBF7), rgb(0xE9D6C6))
        }
    }

    var body: some View {
        let s = scale
        ZStack(alignment: .top) {
            LinearGradient(colors: [palette.top, palette.bottom], startPoint: .top, endPoint: .bottom)

            // Soft glow behind the phone so it lifts off the background.
            Circle()
                .fill(Color.white.opacity(panel.background == .cream || panel.background == .peach ? 0.55 : 0.08))
                .frame(width: 1100 * s, height: 1100 * s)
                .blur(radius: 160 * s)
                .offset(y: 1500 * s)

            VStack(spacing: 0) {
                if panel.showsLockup {
                    HStack(spacing: 22 * s) {
                        BrandMark().frame(width: 92 * s, height: 92 * s)
                        Text("Zero Bite")
                            .font(Marketing.font(58 * s, .semibold))
                            .tracking(-1 * s)
                            .foregroundStyle(palette.text)
                    }
                    .padding(.bottom, 56 * s)
                }

                Text(panel.headline)
                    .font(Marketing.font(124 * s, .bold))
                    .tracking(-4.5 * s)
                    .lineSpacing(-8 * s)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(panel.subhead)
                    .font(Marketing.font(50 * s, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.subtext)
                    .padding(.top, 34 * s)
                    .padding(.horizontal, 120 * s)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, (panel.showsLockup ? 170 : 210) * s)

            // Phone, bleeding off the bottom edge.
            DeviceFrame(screen: screen, scale: s)
                .frame(width: 1000 * s)
                .offset(y: (panel.showsLockup ? 1050 : 960) * s)

            if let crop = panel.popOut, let image = (popOutSource ?? screen).cropped(to: crop) {
                // Lift one card out of the capture, enlarged and centred on where it sits on the phone.
                let screenScale: CGFloat = 940 / 1320   // phone width minus bezels, over capture width
                let onPhoneTop = popOutSource == nil ? 960 + 30 + crop.minY * screenScale : 1820
                let onPhoneHeight = crop.height * screenScale
                let liftedWidth: CGFloat = popOutSource == nil ? 1180 : 1000
                let liftedHeight = crop.height * liftedWidth / crop.width
                Image(nsImage: image)
                    .resizable()
                    .frame(width: liftedWidth * s, height: liftedHeight * s)
                    .clipShape(RoundedRectangle(cornerRadius: 22 * s))
                    .shadow(color: .black.opacity(0.35), radius: 60 * s, y: 30 * s)
                    .offset(y: (onPhoneTop + onPhoneHeight / 2 - liftedHeight / 2) * s)
            }

            if panel.showsNotification {
                NotificationBanner(scale: s)
                    .frame(width: 1160 * s)
                    .offset(y: 900 * s)
            }
        }
        .frame(width: 1320 * s, height: 2868 * s)
        .clipped()
    }

    private func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A plain iPhone silhouette: black bezel around the capture, with continuous corners.
private struct DeviceFrame: View {
    let screen: NSImage
    let scale: CGFloat

    var body: some View {
        let bezel = 30 * scale
        Image(nsImage: screen)
            .resizable()
            .aspectRatio(1320.0 / 2868.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 128 * scale, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: 128 * scale + bezel, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.06, blue: 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 128 * scale + bezel, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 4 * scale)
            )
            .shadow(color: .black.opacity(0.35), radius: 70 * scale, y: 40 * scale)
    }
}

/// An iOS-style notification, drawn rather than captured (the simulator can't screenshot banners).
private struct NotificationBanner: View {
    let scale: CGFloat

    var body: some View {
        let s = scale
        HStack(alignment: .top, spacing: 32 * s) {
            BrandMark()
                .padding(10 * s)
                .frame(width: 112 * s, height: 112 * s)
                .background(BrandMark.ink, in: RoundedRectangle(cornerRadius: 26 * s, style: .continuous))
            VStack(alignment: .leading, spacing: 8 * s) {
                HStack {
                    Text("ZERO BITE").font(Marketing.font(34 * s, .semibold)).tracking(1 * s)
                    Spacer()
                    Text("now").font(Marketing.font(34 * s, .regular))
                }
                .foregroundStyle(Color.black.opacity(0.5))
                Text("Spinach expires today")
                    .font(Marketing.font(46 * s, .semibold))
                    .foregroundStyle(.black)
                Text("It's in 4 recipes you can make tonight.")
                    .font(Marketing.font(42 * s, .regular))
                    .foregroundStyle(Color.black.opacity(0.75))
            }
        }
        .padding(40 * s)
        .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 56 * s, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 50 * s, y: 24 * s)
    }
}

private extension NSImage {
    /// Crops using top-left pixel coordinates.
    func cropped(to rect: CGRect) -> NSImage? {
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let flipped = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
        guard let piece = cg.cropping(to: flipped) else { return nil }
        return NSImage(cgImage: piece, size: NSSize(width: piece.width, height: piece.height))
    }
}

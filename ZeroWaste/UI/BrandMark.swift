//
//  BrandMark.swift
//  ZeroWaste
//
//  The Zero Waste mark: a red disc with a white ring, a white Z whose diagonal runs on as a
//  crossing band (like the national speed limit sign), and an apple-style bite on the east side.
//
//  Pure SwiftUI with no app dependencies, so design/render-assets.swift compiles this same
//  file on macOS to produce the app icons and App Store art.
//

import SwiftUI

struct BrandMark: View {

    enum Style {
        /// Red disc, white ring, band and Z.
        case color
        /// Greyscale for the iOS tinted app icon; the system applies the tint.
        case tinted
    }

    var style: Style = .color

    static let red = Color(red: 0xB2 / 255, green: 0x3A / 255, blue: 0x22 / 255)
    static let cream = Color(red: 0xFF / 255, green: 0xFB / 255, blue: 0xF7 / 255)
    static let ink = Color(red: 0x2B / 255, green: 0x1A / 255, blue: 0x12 / 255)

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            context.scaleBy(x: side / 1024, y: side / 1024)
            Self.draw(in: &context, disc: discColor, ink: inkColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Zero Waste")
    }

    private var discColor: Color {
        style == .color ? Self.red : Color(white: 0.42)
    }

    private var inkColor: Color {
        style == .color ? Self.cream : .white
    }

    // MARK: - Geometry (1024 × 1024 design space; see design/BrandMark.svg)

    private static let center = CGPoint(x: 512, y: 512)
    private static let ringOuterRadius: CGFloat = 376
    private static let discRadius: CGFloat = 300
    /// The Z is drawn in its own 1024 space and scaled to sit inside the ring.
    private static let letterScale: CGFloat = 0.909
    private static let bandAngle = Angle.degrees(-40)
    private static let bite = (center: CGPoint(x: 885, y: 464), radius: CGFloat(175))

    static func draw(in context: inout GraphicsContext, disc: Color, ink: Color) {
        context.drawLayer { layer in
            layer.fill(circle(center, ringOuterRadius), with: .color(ink))
            layer.fill(circle(center, discRadius), with: .color(disc))

            var letter = layer
            letter.translateBy(x: center.x, y: center.y)
            letter.scaleBy(x: letterScale, y: letterScale)
            letter.translateBy(x: -center.x, y: -center.y)
            letter.fill(Path(CGRect(x: 372, y: 352, width: 280, height: 84)), with: .color(ink))
            letter.fill(Path(CGRect(x: 372, y: 588, width: 280, height: 84)), with: .color(ink))

            // The diagonal runs right through to the outer edge so it fuses with the ring.
            var band = letter
            band.clip(to: circle(center, ringOuterRadius / letterScale))
            let rotation = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: bandAngle.radians)
                .translatedBy(x: -center.x, y: -center.y)
            band.fill(Path(CGRect(x: -100, y: 470, width: 1224, height: 84)).applying(rotation), with: .color(ink))

            layer.blendMode = .destinationOut
            layer.fill(circle(bite.center, bite.radius), with: .color(.black))
        }
    }

    private static func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandMark().frame(width: 200, height: 200)
        BrandMark(style: .tinted).frame(width: 120, height: 120).background(.black)
    }
    .padding()
}

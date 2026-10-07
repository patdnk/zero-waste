//
//  render-assets.swift
//  Renders the app icons (and App Store art) from the same BrandMark the app draws.
//
//  Build and run from the repo root with scripts/render-assets.sh.
//

import AppKit
import SwiftUI

@main
@MainActor
struct RenderAssets {
    static func main() throws {
        let args = CommandLine.arguments.dropFirst()
        guard let command = args.first else {
            print("usage: render-assets icons <appiconset-dir> | marketing <raw-screens-dir> <out-dir>")
            exit(1)
        }
        switch command {
        case "icons":
            try renderIcons(into: URL(fileURLWithPath: args.dropFirst().first ?? "."))
        case "marketing":
            let rest = Array(args.dropFirst())
            try Marketing.render(rawDirectory: URL(fileURLWithPath: rest[0]), outDirectory: URL(fileURLWithPath: rest[1]))
        default:
            print("unknown command \(command)")
            exit(1)
        }
    }

    // MARK: - App icons

    static func renderIcons(into directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Default (light) icon: must be fully opaque for the App Store.
        let light = ZStack {
            BrandMark.ink
            BrandMark()
        }
        try write(light, size: 1024, opaque: true, to: directory.appendingPathComponent("AppIcon.png"))

        // Dark appearance: transparent so iOS supplies its own dark backdrop.
        try write(BrandMark(), size: 1024, opaque: false, to: directory.appendingPathComponent("AppIcon-Dark.png"))

        // Tinted appearance: greyscale on transparent; iOS applies the user's tint.
        try write(BrandMark(style: .tinted), size: 1024, opaque: false, to: directory.appendingPathComponent("AppIcon-Tinted.png"))
    }

    // MARK: - Rendering helpers

    static func write<V: View>(_ view: V, size: CGFloat, opaque: Bool, to url: URL) throws {
        try write(view, width: size, height: size, opaque: opaque, to: url)
    }

    static func write<V: View>(_ view: V, width: CGFloat, height: CGFloat, opaque: Bool, to url: URL) throws {
        let renderer = ImageRenderer(content: view.frame(width: width, height: height))
        renderer.scale = 1
        guard var image = renderer.cgImage else { throw RenderError.render(url.lastPathComponent) }
        if opaque { image = try flatten(image) }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { throw RenderError.encode(url.lastPathComponent) }
        try data.write(to: url)
        print("wrote \(url.path) (\(image.width)×\(image.height))")
    }

    /// Redraws into an RGB context with no alpha channel (App Store icons and screenshots must not have one).
    static func flatten(_ image: CGImage) throws -> CGImage {
        guard let context = CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw RenderError.render("flatten") }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let flat = context.makeImage() else { throw RenderError.render("flatten") }
        return flat
    }

    enum RenderError: Error {
        case render(String)
        case encode(String)
    }
}

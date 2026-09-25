import AppKit
let args = CommandLine.arguments
let image = NSImage(contentsOf: URL(fileURLWithPath: args[1]))!
let size = Int(args[3]) ?? 1024
// Draw with alpha (the only mode NSGraphicsContext renders reliably), then flatten to opaque RGB.
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(red: 1, green: 0.984, blue: 0.969, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
ctx.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: size, height: size))
let flat = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! flat.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))

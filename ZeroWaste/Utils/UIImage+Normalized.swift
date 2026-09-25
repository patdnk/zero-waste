//
//  UIImage+Normalized.swift
//  ZeroWaste
//

import UIKit

extension UIImage {

    /// Re-renders the image upright and capped at `maxDimension`, returning JPEG bytes ready
    /// for Vision. Bakes in EXIF orientation so recognised text comes out the right way up.
    func normalizedJPEGData(maxDimension: CGFloat = 2000, quality: CGFloat = 0.9) -> Data? {
        let longest = max(size.width, size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let upright = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return upright.jpegData(compressionQuality: quality)
    }
}

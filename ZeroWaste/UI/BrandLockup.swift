//
//  BrandLockup.swift
//  ZeroWaste
//

import SwiftUI

/// The mark next to the "Zero Waste" name, in the app typeface.
struct BrandLockup: View {
    var size: CGFloat = 28
    var textColor: Color = Constants.TextPrimary

    var body: some View {
        HStack(spacing: size * 0.32) {
            BrandMark().frame(width: size, height: size)
            Text("Zero Waste")
                .font(.app(.title3, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(textColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zero Waste")
    }
}

#Preview {
    BrandLockup().padding()
}

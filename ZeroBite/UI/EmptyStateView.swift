//
//  EmptyStateView.swift
//  ZeroBite
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "refrigerator"
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var primarySymbol: String?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IconTile(symbol: systemImage, tint: Constants.BrandOrange, size: 56)
            Text(title)
                .font(.app(.title2, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(Constants.TextPrimary)
                .padding(.top, Spacing.sm)
            Text(message)
                .font(.app(.body))
                .foregroundStyle(Constants.TextSecondary)
            if let primaryTitle, let primaryAction {
                PrimaryButton(primaryTitle, systemImage: primarySymbol, kind: .brand, action: primaryAction)
                    .padding(.top, Spacing.md)
            }
            if let secondaryTitle, let secondaryAction {
                PrimaryButton(secondaryTitle, kind: .tonal, action: secondaryAction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

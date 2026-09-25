//
//  EmptyStateView.swift
//  ZeroWaste
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "refrigerator"
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(Constants.Brand)
            Text(title)
                .font(.app(.title2, weight: .bold))
                .foregroundStyle(Constants.TextPrimary)
            Text(message)
                .font(.app(.body))
                .foregroundStyle(Constants.TextSecondary)
                .multilineTextAlignment(.center)
            if let primaryTitle, let primaryAction {
                PrimaryButton(primaryTitle, action: primaryAction)
                    .padding(.top, 8)
            }
            if let secondaryTitle, let secondaryAction {
                SecondaryButton(secondaryTitle, action: secondaryAction)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

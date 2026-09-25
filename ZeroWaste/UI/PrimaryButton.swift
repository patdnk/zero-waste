//
//  PrimaryButton.swift
//  ZeroWaste
//

import SwiftUI

/// Full-width primary action button with loading and disabled states.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, isLoading: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.app(.headline, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .disabled(isLoading || !isEnabled)
        .background(Constants.Brand.opacity(isEnabled ? 1 : 0.45), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Secondary, low-emphasis full-width button.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(Constants.TextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Turn on reminders", systemImage: "bell.badge") {}
        PrimaryButton("Loading", isLoading: true) {}
        PrimaryButton("Disabled", isEnabled: false) {}
        SecondaryButton("Not now") {}
    }
    .padding()
}

//
//  PrimaryButton.swift
//  ZeroWaste
//

import SwiftUI

/// Flat, tight-cornered button style shared by every action in the app.
struct AppButtonStyle: ButtonStyle {
    enum Kind {
        /// Dark ink fill: the main action on a screen.
        case ink
        /// Burnt orange fill: scanning and other "do it now" actions.
        case brand
        /// Light chip fill: secondary actions that sit next to a primary one.
        case tonal
        /// Text only.
        case plain
    }

    var kind: Kind = .ink
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(compact ? .subheadline : .headline, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 8 : 14)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.control))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .ink: Constants.OnInk
        case .brand: .white
        case .tonal: Constants.TextPrimary
        case .plain: Constants.TextSecondary
        }
    }

    private var background: Color {
        switch kind {
        case .ink: Constants.TextPrimary
        case .brand: Constants.BrandOrange
        case .tonal: Constants.ChipFill
        case .plain: .clear
        }
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static func app(_ kind: AppButtonStyle.Kind = .ink, compact: Bool = false) -> AppButtonStyle {
        AppButtonStyle(kind: kind, compact: compact)
    }
}

/// Full-width primary action button with loading and disabled states.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    var isEnabled = true
    var kind: AppButtonStyle.Kind = .ink
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        kind: AppButtonStyle.Kind = .ink,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.kind = kind
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView().tint(Constants.OnInk)
            } else if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.app(kind))
        .disabled(isLoading || !isEnabled)
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
        Button(title, action: action)
            .buttonStyle(.app(.plain))
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Turn on reminders", systemImage: "bell.badge") {}
        PrimaryButton("Scan a label", systemImage: "barcode.viewfinder", kind: .brand) {}
        PrimaryButton("Loading", isLoading: true) {}
        PrimaryButton("Disabled", isEnabled: false) {}
        SecondaryButton("Not now") {}
    }
    .padding()
}

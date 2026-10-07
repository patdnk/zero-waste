//
//  FormComponents.swift
//  ZeroBite
//
//  Building blocks that replace `Form`/`List` sections with tight-cornered cards: a titled card
//  section, divided rows, and a bordered text input.
//

import SwiftUI

/// A titled group of rows inside a card, with optional footer text.
struct CardSection<Content: View>: View {
    var title: String?
    var footer: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title {
                Overline(title)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                Group(subviews: content()) { subviews in
                    ForEach(Array(subviews.enumerated()), id: \.offset) { index, subview in
                        if index > 0 {
                            Rectangle().fill(Constants.Hairline).frame(height: 1)
                        }
                        subview
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .background(Constants.Surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay { RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Constants.Hairline) }
            if let footer {
                Text(footer)
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                    .padding(.horizontal, 2)
            }
        }
    }
}

/// Label on the left, value or control on the right.
struct InfoRow<Trailing: View>: View {
    let label: String
    var symbol: String?
    @ViewBuilder var trailing: () -> Trailing

    init(_ label: String, symbol: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.label = label
        self.symbol = symbol
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Constants.TextSecondary)
                    .frame(width: 20)
            }
            Text(label)
                .font(.app(.subheadline))
                .foregroundStyle(Constants.TextSecondary)
            Spacer(minLength: Spacing.md)
            trailing()
                .font(.app(.subheadline, weight: .medium))
                .foregroundStyle(Constants.TextPrimary)
        }
        .frame(minHeight: 24)
    }
}

extension InfoRow where Trailing == Text {
    init(_ label: String, symbol: String? = nil, value: String) {
        self.init(label, symbol: symbol) { Text(value) }
    }
}

/// Row-shaped button inside a `CardSection` (e.g. "Send a test notification").
struct ActionRow: View {
    let title: String
    var symbol: String?
    var tint: Color = Constants.TextPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 20)
                }
                Text(title).font(.app(.subheadline, weight: .medium))
                Spacer()
            }
            .foregroundStyle(tint)
            .frame(minHeight: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Bordered single-line text input with a small label above it.
struct LabeledInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var accessibilityID: String?
    var autoFocus = false

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.app(.caption, weight: .medium))
                .foregroundStyle(Constants.TextSecondary)
            TextField(placeholder, text: $text, axis: axis)
                .font(.app(.body))
                .foregroundStyle(Constants.TextPrimary)
                .lineLimit(axis == .vertical ? 2...4 : 1...1)
                .accessibilityIdentifier(accessibilityID ?? label)
                .focused($focused)
                .inputChrome(isFocused: focused)
        }
        .onAppear { if autoFocus { focused = true } }
    }
}

extension View {
    /// Border and fill shared by every text input.
    func inputChrome(isFocused: Bool) -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
            .background(Constants.Surface, in: RoundedRectangle(cornerRadius: Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control)
                    .strokeBorder(isFocused ? Constants.TextSecondary : Constants.Hairline)
            }
    }
}

/// Inline header used on pushed screens and sheets: overline plus a title.
struct DetailTitle: View {
    var overline: String?
    let title: String
    var overlineTint: Color = Constants.BrandOrange

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let overline {
                Overline(overline, tint: overlineTint)
            }
            Text(title)
                .font(.app(.title, weight: .semibold))
                .tracking(-0.8)
                .foregroundStyle(Constants.TextPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

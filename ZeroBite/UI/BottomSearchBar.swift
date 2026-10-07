//
//  BottomSearchBar.swift
//  ZeroBite
//
//  Search field pinned to the bottom of a root screen, just above the tab bar (iOS 26 pattern),
//  with an optional trailing action such as Scan.
//

import SwiftUI

struct BottomSearchBar: View {
    @Binding var text: String
    let prompt: String
    var accessoryAction: (symbol: String, label: String, action: () -> Void)?
    var accessibilityID = "search.field"

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Constants.TextMuted)
                TextField(prompt, text: $text)
                    .font(.app(.subheadline))
                    .foregroundStyle(Constants.TextPrimary)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(accessibilityID)
                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Constants.TextMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(Constants.Surface, in: RoundedRectangle(cornerRadius: Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control)
                    .strokeBorder(isFocused ? Constants.TextSecondary : Constants.Hairline)
            }

            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                }
                .font(.app(.subheadline, weight: .medium))
                .foregroundStyle(Constants.TextPrimary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let accessoryAction {
                Button(action: accessoryAction.action) {
                    Image(systemName: accessoryAction.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Constants.BrandOrange, in: RoundedRectangle(cornerRadius: Radius.control))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessoryAction.label)
                .accessibilityIdentifier("search.accessory")
            }
        }
        .animation(.snappy(duration: 0.2), value: isFocused)
        .padding(.horizontal, Spacing.gutter)
        .padding(.vertical, 10)
        .background(Constants.BackgroundPrimary)
    }
}

#Preview {
    @Previewable @State var text = ""
    VStack {
        Spacer()
        BottomSearchBar(text: $text, prompt: "Search your food",
                        accessoryAction: ("barcode.viewfinder", "Scan", {}))
    }
    .pageBackground()
}

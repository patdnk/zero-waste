//
//  RecallViews.swift
//  ZeroWaste
//
//  Recall warnings: the Fridge banner, the item detail card, and alert rows/detail used by
//  the Food alerts screen. Copy never claims a definite match: the user checks the pack.
//

import SwiftUI

extension RecallMatch {
    var headline: String {
        confidence == .likely ? "Your \(itemName.lowercased()) may be recalled" : "Possible recall: \(itemName)"
    }

    /// Why we think it matches, in plain words.
    var explanation: String {
        var parts: [String] = []
        if reasons.contains(.barcode) { parts.append("the barcode is on the notice") }
        if reasons.contains(.brand) { parts.append("the brand matches") }
        if reasons.contains(.name) && !reasons.contains(.barcode) { parts.append("the product name matches") }
        if reasons.contains(.date) { parts.append("your date matches a recalled batch") }
        if reasons.contains(.allBatches) { parts.append("every batch is affected") }
        guard let first = parts.first else { return "" }
        let sentence = ([first.prefix(1).uppercased() + first.dropFirst()] + parts.dropFirst()).joined(separator: ", ")
        return sentence + "."
    }
}

extension FoodAlert.Kind {
    var tint: Color {
        switch self {
        case .allergy: Constants.BrandOrange
        case .recall, .actionRequired: Constants.StatusExpired
        }
    }

    var symbol: String {
        switch self {
        case .allergy: "allergens"
        case .recall, .actionRequired: "exclamationmark.triangle.fill"
        }
    }
}

/// Top-of-Fridge warning when any item may be recalled.
struct RecallBanner: View {
    let matches: [RecallMatch]
    let onOpen: (RecallMatch) -> Void

    var body: some View {
        if let first = matches.first {
            Button { onOpen(first) } label: {
                HStack(alignment: .top, spacing: Spacing.md) {
                    IconTile(symbol: "exclamationmark.triangle.fill", tint: Constants.StatusExpired, size: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Overline(matches.count == 1 ? "Food recall" : "\(matches.count) possible recalls", tint: Constants.StatusExpired)
                        Text(first.headline)
                            .font(.app(.subheadline, weight: .semibold))
                            .foregroundStyle(Constants.TextPrimary)
                            .multilineTextAlignment(.leading)
                        Text(first.alert.displayTitle)
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text("Check the pack")
                            .font(.app(.caption, weight: .semibold))
                            .foregroundStyle(Constants.StatusExpired)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Constants.TextMuted)
                        .padding(.top, 10)
                }
                .cardStyle(accent: Constants.StatusExpired)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("inventory.recallBanner")
        }
    }
}

/// Full recall details on the item's page, with what to check and what to do.
struct RecallCard: View {
    let match: RecallMatch
    let onNotMine: () -> Void
    let onThrowAway: () -> Void

    var body: some View {
        let alert = match.alert
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                IconTile(symbol: alert.kind.symbol, tint: alert.kind.tint, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Overline("\(alert.kind.label) · \(alert.created.formatted(date: .abbreviated, time: .omitted))", tint: alert.kind.tint)
                    Text(alert.displayTitle)
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundStyle(Constants.TextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(match.explanation + " Compare the details below with your pack.")
                .font(.app(.caption))
                .foregroundStyle(Constants.TextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            AlertProductDetails(product: match.product)

            if let advice = alert.consumerAdvice {
                VStack(alignment: .leading, spacing: 4) {
                    Overline("What to do")
                    Text(advice)
                        .font(.app(.subheadline))
                        .foregroundStyle(Constants.TextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 6) {
                Button(action: onThrowAway) {
                    Label("It's affected: remove it", systemImage: "trash")
                }
                .buttonStyle(.app(.ink, compact: true))
                HStack(spacing: 6) {
                    Button("Not my batch", action: onNotMine)
                        .buttonStyle(.app(.tonal, compact: true))
                        .accessibilityIdentifier("recall.notMine")
                    if let url = alert.url {
                        Link(destination: url) {
                            Label("FSA notice", systemImage: "arrow.up.right")
                        }
                        .buttonStyle(.app(.tonal, compact: true))
                    }
                }
            }
        }
        .cardStyle(accent: alert.kind.tint, padding: Spacing.lg)
        .accessibilityIdentifier("item.recallCard")
    }
}

/// Product, pack size and batch lines from a notice.
struct AlertProductDetails: View {
    let product: FoodAlert.Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.name)
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(Constants.TextPrimary)
            if let packSize = product.packSize {
                detail("scalemass", packSize)
            }
            ForEach(Array(product.batches.enumerated()), id: \.offset) { _, batch in
                if !batch.summary.isEmpty {
                    detail("barcode", batch.summary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.ChipFill, in: RoundedRectangle(cornerRadius: Radius.control))
    }

    private func detail(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Constants.TextSecondary)
                .frame(width: 16)
            Text(text)
                .font(.app(.caption))
                .foregroundStyle(Constants.TextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One alert in the Food alerts list.
struct FoodAlertRow: View {
    let alert: FoodAlert
    var highlight: String?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            IconTile(symbol: alert.kind.symbol, tint: alert.kind.tint, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.displayTitle)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text([alert.kind.label, alert.business, alert.created.formatted(.dateTime.day().month(.abbreviated))].compactMap { $0 }.joined(separator: " · "))
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                if let highlight {
                    Tag(text: highlight, tint: alert.kind.tint)
                        .padding(.top, 3)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Constants.TextMuted)
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }
}

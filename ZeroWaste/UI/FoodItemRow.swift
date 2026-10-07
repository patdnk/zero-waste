//
//  FoodItemRow.swift
//  ZeroWaste
//
//  Item presentations: the compact grid card, the full-width row, and the "use first" hero.
//

import SwiftUI

extension FoodItem {
    /// Fraction of the shelf life already used, from when it was added to its date.
    func shelfLifeProgress(now: Date = .now) -> Double {
        let total = expiresAt.timeIntervalSince(addedAt)
        guard total > 0 else { return 1 }
        return now.timeIntervalSince(addedAt) / total
    }
}

/// Two-up grid card for the Fridge screen.
struct FoodItemCard: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now
    /// A current FSA alert may concern this item.
    var isRecallFlagged = false

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                IconTile(symbol: item.category.symbol, tint: status.tint)
                Spacer()
                if isRecallFlagged {
                    Label("Recall?", systemImage: "exclamationmark.triangle.fill")
                        .font(.app(.caption2, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Constants.StatusExpired, in: RoundedRectangle(cornerRadius: Radius.control))
                }
            }
            Text(item.name)
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(Constants.TextPrimary)
                .lineLimit(1)
                .padding(.top, 10)
            HStack(alignment: .firstTextBaseline) {
                Text(item.quantityText)
                    .foregroundStyle(Constants.TextSecondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(item.shortExpiryLabel(now: now))
                    .fontWeight(.semibold)
                    .foregroundStyle(status.tint)
                    .lineLimit(1)
            }
            .font(.app(.caption))
            .padding(.top, 2)
        }
        .cardStyle(accent: isRecallFlagged ? Constants.StatusExpired : (status.needsAttention ? status.tint : nil))
        .accessibilityElement(children: .combine)
    }
}

/// Full-width row, used where a list reads better than a grid (item pickers, search results).
struct FoodItemRow: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        HStack(spacing: Spacing.md) {
            IconTile(symbol: item.category.symbol, tint: status.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("\(item.quantityText) · \(item.storage.label)")
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
            }
            Spacer()
            ExpiryBadge(item: item, soonThresholdDays: soonThresholdDays, now: now)
        }
    }
}

/// Hero card for the single most urgent item, with quick actions.
struct UseFirstCard: View {
    let item: FoodItem
    var othersNeedingAttention = 0
    var soonThresholdDays = 3
    var now: Date = .now
    let onOpen: () -> Void
    let onUsed: () -> Void
    let onFreeze: (() -> Void)?
    let onRecipes: () -> Void

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        let days = item.daysUntilExpiry(from: now)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Overline("Use first")
                Spacer()
                if othersNeedingAttention > 0 {
                    Text("\(othersNeedingAttention) more need attention")
                        .font(.app(.caption))
                        .foregroundStyle(Constants.TextSecondary)
                }
            }

            Button(action: onOpen) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.app(.title3, weight: .semibold))
                            .foregroundStyle(Constants.TextPrimary)
                            .multilineTextAlignment(.leading)
                        Text("\(item.quantityText) · \(item.storage.label)")
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
                    }
                    Spacer()
                    countdown(days: days, status: status)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.bottom, 10)

            ShelfLifeBar(progress: item.shelfLifeProgress(now: now), tint: status.tint)

            HStack(spacing: 6) {
                Button("Used it", action: onUsed).buttonStyle(.app(.ink, compact: true))
                if let onFreeze {
                    Button("Freeze", action: onFreeze).buttonStyle(.app(.tonal, compact: true))
                }
                Button("Recipes", action: onRecipes).buttonStyle(.app(.tonal, compact: true))
            }
            .padding(.top, Spacing.md)
        }
        .cardStyle()
        .accessibilityIdentifier("inventory.useFirst")
    }

    @ViewBuilder
    private func countdown(days: Int, status: ExpiryStatus) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if days < 0 {
                Text("\(-days)").font(.system(size: 40, weight: .semibold)).tracking(-1.5)
                Text(-days == 1 ? "day over" : "days over").font(.app(.subheadline))
            } else if days == 0 {
                Text("Today").font(.app(.title, weight: .semibold)).tracking(-1)
            } else {
                Text("\(days)").font(.system(size: 40, weight: .semibold)).tracking(-1.5)
                Text(days == 1 ? "day" : "days").font(.app(.subheadline))
            }
        }
        .foregroundStyle(status.tint)
        .accessibilityElement(children: .combine)
    }
}

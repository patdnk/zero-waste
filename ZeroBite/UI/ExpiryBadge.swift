//
//  ExpiryBadge.swift
//  ZeroBite
//

import SwiftUI

/// Compact tag showing how long an item has left, tinted by urgency.
struct ExpiryBadge: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        Text(item.shortExpiryLabel(now: now))
            .font(.app(.caption, weight: .semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(status.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control))
    }
}

/// Tappable chip for an expiring item, used in the "use these first" strip.
struct ExpiringChip: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        HStack(spacing: 6) {
            Image(systemName: item.category.symbol)
                .foregroundStyle(status.tint)
            Text(item.name)
                .foregroundStyle(Constants.TextPrimary)
                .lineLimit(1)
            Text(item.shortExpiryLabel(now: now))
                .foregroundStyle(status.tint)
                .fontWeight(.semibold)
        }
        .font(.app(.caption))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Constants.Surface, in: RoundedRectangle(cornerRadius: Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.control).strokeBorder(status.tint.opacity(0.4))
        }
    }
}

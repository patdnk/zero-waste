//
//  ExpiryBadge.swift
//  ZeroWaste
//

import SwiftUI

/// Compact capsule showing how long an item has left, tinted by urgency.
struct ExpiryBadge: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        Text(item.shortExpiryLabel(now: now))
            .font(.app(.caption, weight: .semibold))
            .foregroundStyle(status == .soon ? Constants.TextPrimary : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.tint, in: Capsule())
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
            Text(item.name).lineLimit(1)
            Text("·").foregroundStyle(.secondary)
            Text(item.shortExpiryLabel(now: now)).foregroundStyle(status.tint).fontWeight(.semibold)
        }
        .font(.app(.subheadline))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Constants.BackgroundPrimary, in: Capsule())
        .overlay(Capsule().strokeBorder(status.tint.opacity(0.5)))
    }
}

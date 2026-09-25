//
//  FoodItemRow.swift
//  ZeroWaste
//

import SwiftUI

struct FoodItemRow: View {
    let item: FoodItem
    var soonThresholdDays = 3
    var now: Date = .now

    var body: some View {
        let status = item.status(soonThresholdDays: soonThresholdDays, now: now)
        HStack(spacing: 12) {
            Image(systemName: item.category.symbol)
                .font(.app(.title3))
                .foregroundStyle(status.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.app(.headline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("\(item.quantityText) · \(item.storage.label)")
                    .font(.app(.subheadline))
                    .foregroundStyle(Constants.TextSecondary)
            }
            Spacer()
            ExpiryBadge(item: item, soonThresholdDays: soonThresholdDays, now: now)
        }
        .padding(.vertical, 2)
    }
}

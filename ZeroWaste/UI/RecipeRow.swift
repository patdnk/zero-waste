//
//  RecipeRow.swift
//  ZeroWaste
//

import SwiftUI

struct RecipeRow: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(match.recipe.title)
                .font(.app(.headline, weight: .semibold))
                .foregroundStyle(Constants.TextPrimary)
            Text("\(match.recipe.prepMinutes) min · serves \(match.recipe.servings)")
                .font(.app(.caption))
                .foregroundStyle(Constants.TextSecondary)
            HStack(spacing: 12) {
                if match.canMake {
                    Label("Ready to cook", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Constants.StatusFresh)
                } else {
                    Label(missingText, systemImage: "cart")
                        .foregroundStyle(Constants.TextSecondary)
                        .lineLimit(1)
                }
                if !match.expiringItems.isEmpty {
                    Label("Uses \(match.expiringItems.count) expiring", systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(Constants.StatusToday)
                }
            }
            .font(.app(.caption, weight: .medium))
        }
        .padding(.vertical, 4)
    }

    private var missingText: String {
        let names = match.missing.prefix(2).map(\.name).joined(separator: ", ")
        let more = match.missing.count > 2 ? " +\(match.missing.count - 2)" : ""
        return "Missing \(names)\(more)"
    }
}

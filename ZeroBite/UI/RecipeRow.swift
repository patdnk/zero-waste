//
//  RecipeRow.swift
//  ZeroBite
//
//  Recipe presentations: featured card, compact grid card, and a list row.
//

import SwiftUI

extension Recipe {
    /// Placeholder artwork until recipes carry real images.
    var symbol: String {
        // Title only: tags such as "vegetarian" or "quick" say nothing about what the dish looks like.
        let haystack = title.lowercased()
        let rules: [(String, [String])] = [
            ("mug.fill", ["smoothie", "parfait", "oats", "porridge", "granola", "shake"]),
            ("cup.and.saucer.fill", ["soup", "broth", "stew", "chowder"]),
            ("leaf.fill", ["salad", "slaw"]),
            ("fish.fill", ["fish", "salmon", "tuna", "prawn", "cod"]),
            ("birthday.cake.fill", ["cake", "bake", "muffin", "pudding", "dessert", "crumble", "bread"]),
            ("frying.pan.fill", ["omelette", "frittata", "fried", "fry", "scrambled", "egg", "pancake", "hash"]),
            ("takeoutbag.and.cup.and.straw.fill", ["wrap", "sandwich", "toastie", "burger", "quesadilla"]),
            ("fork.knife", ["pasta", "spaghetti", "carbonara", "risotto", "rice", "noodle"]),
            ("carrot.fill", ["vegetable", "curry", "roast", "potato", "carrot"]),
        ]
        return rules.first { _, needles in needles.contains { haystack.contains($0) } }?.0 ?? "fork.knife"
    }
}

extension RecipeMatch {
    /// Share of required ingredients already in the fridge, 0–100.
    var matchPercent: Int {
        guard requiredCount > 0 else { return 100 }
        return Int((Double(requiredMatchedCount) / Double(requiredCount) * 100).rounded())
    }

    var statusText: String {
        if canMake { return "Ready to cook" }
        let names = missing.prefix(2).map(\.name).joined(separator: ", ")
        let more = missing.count > 2 ? " +\(missing.count - 2)" : ""
        return "Missing \(names)\(more)"
    }

    var accent: Color {
        if !expiringItems.isEmpty { return Constants.BrandOrange }
        return canMake ? Constants.StatusFresh : Constants.BrandYellow
    }
}

/// Tinted panel standing in for a recipe photo.
struct RecipeArtwork: View {
    let recipe: Recipe
    let tint: Color
    var height: CGFloat = 96

    var body: some View {
        Rectangle()
            .fill(tint.opacity(0.14))
            .frame(height: height)
            .overlay {
                Image(systemName: recipe.symbol)
                    .font(.system(size: height * 0.4, weight: .medium))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)
    }
}

/// Large card for the best match at the top of the Recipes screen.
struct FeaturedRecipeCard: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeArtwork(recipe: match.recipe, tint: match.accent, height: 110)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(match.recipe.title)
                        .font(.app(.headline, weight: .semibold))
                        .foregroundStyle(Constants.TextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text("\(match.matchPercent)%")
                        .font(.app(.headline, weight: .semibold))
                        .foregroundStyle(match.accent)
                        .accessibilityLabel("\(match.matchPercent) percent of ingredients in your fridge")
                }
                Text(metaText)
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                if !match.expiringItems.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(match.expiringItems.prefix(3)) { item in
                            Tag(text: item.name, tint: Constants.BrandOrange)
                        }
                        if match.expiringItems.count > 3 {
                            Tag(text: "+\(match.expiringItems.count - 3)")
                        }
                    }
                    .padding(.top, 6)
                } else {
                    Text(match.statusText)
                        .font(.app(.caption, weight: .semibold))
                        .foregroundStyle(match.canMake ? Constants.StatusFresh : Constants.TextSecondary)
                        .padding(.top, 2)
                }
            }
            .padding(Spacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .cardStyle(padding: 0)
        .accessibilityElement(children: .combine)
    }

    private var metaText: String {
        var parts = ["\(match.recipe.prepMinutes) min", "serves \(match.recipe.servings)"]
        if !match.expiringItems.isEmpty {
            parts.append("uses \(match.expiringItems.count) expiring")
        }
        return parts.joined(separator: " · ")
    }
}

/// Half-width grid card.
struct RecipeCard: View {
    let match: RecipeMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeArtwork(recipe: match.recipe, tint: match.accent, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Radius.control))
            Text(match.recipe.title)
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(Constants.TextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
                .padding(.top, 10)
            Text(match.statusText)
                .font(.app(.caption))
                .foregroundStyle(match.canMake ? Constants.StatusFresh : Constants.TextSecondary)
                .lineLimit(1)
                .padding(.top, 2)
            Text("\(match.recipe.prepMinutes) min · \(match.matchPercent)% in fridge")
                .font(.app(.caption2))
                .foregroundStyle(Constants.TextMuted)
                .padding(.top, 2)
        }
        .cardStyle(padding: 10)
        .accessibilityElement(children: .combine)
    }
}

/// Full-width row for lists inside cards (item detail "recipes using this").
struct RecipeRow: View {
    let match: RecipeMatch

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconTile(symbol: match.recipe.symbol, tint: match.accent, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(match.recipe.title)
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("\(match.recipe.prepMinutes) min · \(match.statusText)")
                    .font(.app(.caption))
                    .foregroundStyle(match.canMake ? Constants.StatusFresh : Constants.TextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Constants.TextMuted)
        }
        .contentShape(Rectangle())
    }
}

//
//  RecipeDetailView.swift
//  ZeroWaste
//

import SwiftUI

struct RecipeDetailView: View {
    @Bindable var viewModel: RecipeDetailViewModel

    var body: some View {
        Group {
            if let recipe = viewModel.recipe, let match = viewModel.match {
                content(recipe: recipe, match: match)
            } else {
                EmptyStateView(title: "Recipe not found", message: "It may have been removed from the catalogue.", systemImage: "questionmark")
                    .padding(Spacing.gutter)
            }
        }
        .pageBackground()
        .topBar(.back)
    }

    private func content(recipe: Recipe, match: RecipeMatch) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RecipeArtwork(recipe: recipe, tint: match.accent, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    DetailTitle(overline: "\(match.matchPercent)% in your fridge", title: recipe.title, overlineTint: match.accent)
                    Text(recipe.summary)
                        .font(.app(.body))
                        .foregroundStyle(Constants.TextSecondary)
                }

                HStack(spacing: Spacing.sm) {
                    stat("\(recipe.prepMinutes)", unit: "min", symbol: "clock")
                    stat("\(recipe.servings)", unit: recipe.servings == 1 ? "serving" : "servings", symbol: "person.2")
                    stat("\(match.expiringItems.count)", unit: "expiring", symbol: "clock.badge.exclamationmark",
                         tint: match.expiringItems.isEmpty ? nil : Constants.BrandOrange)
                }

                statusBanner(match: match)

                if !recipe.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(recipe.tags, id: \.self) { Tag(text: $0) }
                        }
                        .padding(.horizontal, Spacing.gutter)
                    }
                    .scrollClipDisabled()
                    .padding(.horizontal, -Spacing.gutter)
                }

                CardSection("Ingredients") {
                    ForEach(recipe.ingredients) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            matched: viewModel.matched(for: ingredient),
                            soonThresholdDays: viewModel.soonThresholdDays,
                            onTapItem: { viewModel.showItem($0) }
                        )
                    }
                }

                CardSection("Method") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Text(String(format: "%02d", index + 1))
                                .font(.app(.subheadline, weight: .semibold))
                                .foregroundStyle(Constants.BrandOrange)
                                .frame(width: 24, alignment: .leading)
                            Text(step)
                                .font(.app(.subheadline))
                                .foregroundStyle(Constants.TextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                PrimaryButton("I cooked this — update my fridge", systemImage: "checkmark.seal", isEnabled: viewModel.canMarkCooked) {
                    viewModel.cooked()
                }
                .accessibilityIdentifier("recipe.cooked")
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func stat(_ value: String, unit: String, symbol: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint ?? Constants.TextSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.app(.title3, weight: .semibold))
                Text(unit).font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
            }
            .foregroundStyle(tint ?? Constants.TextPrimary)
        }
        .cardStyle(padding: 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statusBanner(match: RecipeMatch) -> some View {
        let tint = match.canMake ? Constants.StatusFresh : Constants.BrandYellow
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: match.canMake ? "checkmark.circle.fill" : "cart.fill")
            Text(match.canMake
                 ? "You have everything you need."
                 : "Missing \(match.missing.map(\.name).joined(separator: ", ")).")
        }
        .font(.app(.subheadline, weight: .medium))
        .foregroundStyle(tint)
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

struct IngredientRow: View {
    let ingredient: Recipe.Ingredient
    let matched: MatchedIngredient?
    var soonThresholdDays = 3
    let onTapItem: (FoodItem) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 20)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.amount.isEmpty ? ingredient.name : "\(ingredient.amount) \(ingredient.name)")
                    .font(.app(.subheadline, weight: .medium))
                    .foregroundStyle(Constants.TextPrimary)
                subtitle
                    .font(.app(.caption))
            }
            Spacer()
        }
    }

    private var item: FoodItem? { matched?.item }

    private var status: ExpiryStatus? {
        item?.status(soonThresholdDays: soonThresholdDays)
    }

    private var symbol: String {
        if let status { return status.needsAttention ? "exclamationmark.circle.fill" : "checkmark.circle.fill" }
        if matched?.isStaple == true { return "cabinet" }
        return ingredient.optional ? "circle.dotted" : "circle"
    }

    private var tint: Color {
        if let status { return status.needsAttention ? status.tint : Constants.StatusFresh }
        return Constants.TextSecondary
    }

    @ViewBuilder
    private var subtitle: some View {
        if let item {
            Button { onTapItem(item) } label: {
                Text("You have \(item.name) · \(item.shortExpiryLabel())")
                    .foregroundStyle(tint)
            }
            .buttonStyle(.plain)
        } else if matched?.isStaple == true {
            Text("Store cupboard").foregroundStyle(Constants.TextSecondary)
        } else if ingredient.optional {
            Text("Optional — skip it").foregroundStyle(Constants.TextSecondary)
        } else {
            Text("Not in your fridge").foregroundStyle(Constants.TextSecondary)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        RecipesFactory.makeDetail(
            recipeID: dependencies.recipes.first?.id ?? "",
            dependencies: dependencies,
            onShowItem: { _ in },
            onCooked: { _ in }
        )
    }
}

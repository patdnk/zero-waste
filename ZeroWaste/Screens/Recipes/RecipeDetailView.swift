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
                ContentUnavailableView("Recipe not found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle(viewModel.recipe?.title ?? "")
        .navigationBarTitleDisplayMode(.large)
    }

    private func content(recipe: Recipe, match: RecipeMatch) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(recipe.summary)
                        .foregroundStyle(Constants.TextPrimary)
                    HStack(spacing: 16) {
                        Label("\(recipe.prepMinutes) min", systemImage: "clock")
                        Label("Serves \(recipe.servings)", systemImage: "person.2")
                    }
                    .font(.app(.subheadline))
                    .foregroundStyle(Constants.TextSecondary)

                    if match.canMake {
                        Label("You have everything", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Constants.StatusFresh)
                            .font(.app(.subheadline, weight: .semibold))
                    } else {
                        Label("Missing: \(match.missing.map(\.name).joined(separator: ", "))", systemImage: "cart")
                            .foregroundStyle(Constants.StatusToday)
                            .font(.app(.subheadline, weight: .semibold))
                    }
                    if !match.expiringItems.isEmpty {
                        Label("Uses up \(match.expiringItems.map(\.name).joined(separator: ", "))", systemImage: "clock.badge.exclamationmark")
                            .foregroundStyle(Constants.BrandOrange)
                            .font(.app(.subheadline, weight: .semibold))
                    }

                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.app(.caption2, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Constants.CardTint, in: Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Ingredients") {
                ForEach(recipe.ingredients) { ingredient in
                    IngredientRow(
                        ingredient: ingredient,
                        matched: viewModel.matched(for: ingredient),
                        soonThresholdDays: viewModel.soonThresholdDays,
                        onTapItem: { viewModel.showItem($0) }
                    )
                }
            }

            Section("Method") {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.app(.headline, weight: .bold))
                            .foregroundStyle(Constants.Brand)
                            .frame(width: 24, alignment: .leading)
                        Text(step).foregroundStyle(Constants.TextPrimary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button { viewModel.cooked() } label: {
                    Label("I cooked this — update my fridge", systemImage: "checkmark.seal")
                }
                .disabled(!viewModel.canMarkCooked)
                .accessibilityIdentifier("recipe.cooked")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Constants.BackgroundSecondary)
    }
}

struct IngredientRow: View {
    let ingredient: Recipe.Ingredient
    let matched: MatchedIngredient?
    var soonThresholdDays = 3
    let onTapItem: (FoodItem) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.amount.isEmpty ? ingredient.name : "\(ingredient.amount) \(ingredient.name)")
                    .foregroundStyle(Constants.TextPrimary)
                subtitle
                    .font(.app(.caption))
            }
            Spacer()
        }
        .padding(.vertical, 2)
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

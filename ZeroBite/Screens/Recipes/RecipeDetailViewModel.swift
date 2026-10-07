//
//  RecipeDetailViewModel.swift
//  ZeroBite
//

import Foundation
import Observation

@MainActor
@Observable
final class RecipeDetailViewModel {

    let recipeID: String

    private let store: InventoryStore
    private let settings: AppSettings
    private let recipes: [Recipe]
    private let onShowItem: (UUID) -> Void
    private let onCooked: (String) -> Void
    private let now: () -> Date

    init(
        recipeID: String,
        store: InventoryStore,
        settings: AppSettings,
        recipes: [Recipe],
        onShowItem: @escaping (UUID) -> Void,
        onCooked: @escaping (String) -> Void,
        now: @escaping () -> Date = { .now }
    ) {
        self.recipeID = recipeID
        self.store = store
        self.settings = settings
        self.recipes = recipes
        self.onShowItem = onShowItem
        self.onCooked = onCooked
        self.now = now
    }

    var recipe: Recipe? { recipes.first { $0.id == recipeID } }
    var soonThresholdDays: Int { settings.soonThresholdDays }

    var match: RecipeMatch? {
        recipe.map {
            RecipeMatcher(soonThresholdDays: soonThresholdDays, now: now()).match(recipe: $0, inventory: store.activeItems)
        }
    }

    func matched(for ingredient: Recipe.Ingredient) -> MatchedIngredient? {
        match?.matched.first { $0.ingredient == ingredient }
    }

    /// The button is only useful when at least one fridge item would be consumed.
    var canMarkCooked: Bool { !(match?.usedItems.isEmpty ?? true) }

    func showItem(_ item: FoodItem) {
        onShowItem(item.id)
    }

    func cooked() {
        onCooked(recipeID)
    }
}

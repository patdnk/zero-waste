//
//  ItemDetailViewModel.swift
//  ZeroWaste
//

import Foundation
import Observation

@MainActor
@Observable
final class ItemDetailViewModel {

    enum State: Equatable {
        case active
        case used
        case missing
    }

    let itemID: UUID

    private let store: InventoryStore
    private let settings: AppSettings
    private let recipes: [Recipe]
    private let onEdit: (UUID) -> Void
    private let onShowRecipe: (String) -> Void
    private let onDeleted: () -> Void
    private let now: () -> Date

    init(
        itemID: UUID,
        store: InventoryStore,
        settings: AppSettings,
        recipes: [Recipe],
        onEdit: @escaping (UUID) -> Void,
        onShowRecipe: @escaping (String) -> Void,
        onDeleted: @escaping () -> Void,
        now: @escaping () -> Date = { .now }
    ) {
        self.itemID = itemID
        self.store = store
        self.settings = settings
        self.recipes = recipes
        self.onEdit = onEdit
        self.onShowRecipe = onShowRecipe
        self.onDeleted = onDeleted
        self.now = now
    }

    var item: FoodItem? { store.item(id: itemID) }

    var state: State {
        guard let item else { return .missing }
        return item.isConsumed ? .used : .active
    }

    var soonThresholdDays: Int { settings.soonThresholdDays }

    var status: ExpiryStatus? {
        item?.status(soonThresholdDays: soonThresholdDays, now: now())
    }

    /// Recipes that would use this item, best first.
    var recipeMatches: [RecipeMatch] {
        let matcher = RecipeMatcher(soonThresholdDays: soonThresholdDays, now: now())
        return matcher
            .match(recipes: recipes, inventory: store.activeItems)
            .filter { $0.uses(itemID: itemID) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Actions

    func markUsed() {
        guard let item else { return }
        store.markConsumed(item, at: now())
    }

    func restore() {
        guard let item else { return }
        store.restore(item)
    }

    func delete() {
        guard let item else { return }
        store.delete(item)
        onDeleted()
    }

    func edit() {
        onEdit(itemID)
    }

    func showRecipe(_ match: RecipeMatch) {
        onShowRecipe(match.recipe.id)
    }
}

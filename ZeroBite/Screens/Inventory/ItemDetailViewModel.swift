//
//  ItemDetailViewModel.swift
//  ZeroBite
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
    private let recalls: RecallStore?
    private let onEdit: (UUID) -> Void
    private let onShowRecipe: (String) -> Void
    private let onDeleted: () -> Void
    private let now: () -> Date

    init(
        itemID: UUID,
        store: InventoryStore,
        settings: AppSettings,
        recipes: [Recipe],
        recalls: RecallStore? = nil,
        onEdit: @escaping (UUID) -> Void,
        onShowRecipe: @escaping (String) -> Void,
        onDeleted: @escaping () -> Void,
        now: @escaping () -> Date = { .now }
    ) {
        self.itemID = itemID
        self.store = store
        self.settings = settings
        self.recipes = recipes
        self.recalls = recalls
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

    /// FSA alerts that may concern this item.
    var recallMatches: [RecallMatch] {
        guard let item, !item.isConsumed, let recalls, settings.recallChecksEnabled else { return [] }
        return recalls.matches(for: [item], now: now())
    }

    /// "Not my batch": hides this alert for this item.
    func dismissRecall(_ match: RecallMatch) {
        recalls?.dismiss(match)
    }

    /// The user is throwing it away: record it as gone (it won't count as eaten in future stats).
    func discardRecalled() {
        guard let item else { return }
        store.delete(item)
        onDeleted()
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

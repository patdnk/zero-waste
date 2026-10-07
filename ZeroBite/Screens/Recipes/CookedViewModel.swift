//
//  CookedViewModel.swift
//  ZeroBite
//
//  After cooking: choose which matched fridge items were used up.
//

import Foundation
import Observation

@MainActor
@Observable
final class CookedViewModel {

    let recipe: Recipe?
    let usableItems: [FoodItem]
    var selectedIDs: Set<UUID>

    private let store: InventoryStore
    private let onDone: () -> Void
    private let now: () -> Date

    init(
        recipeID: String,
        store: InventoryStore,
        settings: AppSettings,
        recipes: [Recipe],
        onDone: @escaping () -> Void,
        now: @escaping () -> Date = { .now }
    ) {
        self.store = store
        self.onDone = onDone
        self.now = now
        let recipe = recipes.first { $0.id == recipeID }
        self.recipe = recipe
        let match = recipe.map {
            RecipeMatcher(soonThresholdDays: settings.soonThresholdDays, now: now()).match(recipe: $0, inventory: store.activeItems)
        }
        usableItems = match?.usedItems ?? []
        selectedIDs = Set(usableItems.map(\.id))
    }

    func isSelected(_ item: FoodItem) -> Bool {
        selectedIDs.contains(item.id)
    }

    func toggle(_ item: FoodItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    var selectedCount: Int { selectedIDs.count }

    func confirm() {
        let used = usableItems.filter { selectedIDs.contains($0.id) }
        if !used.isEmpty {
            store.markConsumed(used, at: now())
        }
        onDone()
    }

    func cancel() {
        onDone()
    }
}

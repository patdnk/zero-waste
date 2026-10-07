//
//  ItemFormViewModel.swift
//  ZeroBite
//

import Foundation
import Observation

@MainActor
@Observable
final class ItemFormViewModel {

    enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    let mode: Mode
    var draft: ItemDraft
    var errorMessage: String?

    private let store: InventoryStore
    private let onSaved: (FoodItem) -> Void
    private let now: () -> Date

    init(mode: Mode, draft: ItemDraft, store: InventoryStore, onSaved: @escaping (FoodItem) -> Void, now: @escaping () -> Date = { .now }) {
        self.mode = mode
        self.draft = draft
        self.store = store
        self.onSaved = onSaved
        self.now = now
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var title: String { isEditing ? "Edit item" : "New item" }
    var canSave: Bool { draft.isValid }

    var defaultShelfLifeDays: Int { draft.category.defaultShelfLifeDays }

    /// Sets the expiry from the category's typical shelf life (for items with no readable date).
    func applyDefaultShelfLife() {
        draft.expiresAt = Calendar.current.date(byAdding: .day, value: defaultShelfLifeDays, to: now()) ?? now()
    }

    func save() {
        guard canSave else { return }
        switch mode {
        case .add:
            onSaved(store.add(draft, now: now()))
        case .edit(let id):
            guard let item = store.item(id: id) else {
                errorMessage = "This item no longer exists."
                return
            }
            store.update(item, with: draft)
            onSaved(item)
        }
    }
}

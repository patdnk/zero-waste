//
//  InventoryStore.swift
//  ZeroBite
//
//  Single source of truth for fridge contents. Owns the SwiftData context; view models
//  read `items` / `activeItems` and mutate through the methods below so every change
//  is saved, re-read, and reported (→ notifications are re-planned).
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class InventoryStore {

    /// Kept alive on purpose: a `ModelContext` only weakly references its container, and
    /// inserting into a context whose container has been deallocated traps inside SwiftData.
    private let container: ModelContainer
    private let context: ModelContext

    /// Every item, including ones marked as used. Sorted by expiry.
    private(set) var items: [FoodItem] = []

    /// Called after any committed change.
    var onChange: (() -> Void)?

    init(container: ModelContainer) {
        self.container = container
        context = container.mainContext
        reload()
    }

    // MARK: - Reads

    var activeItems: [FoodItem] { items.filter { !$0.isConsumed } }
    var consumedItems: [FoodItem] { items.filter { $0.isConsumed } }

    func item(id: UUID) -> FoodItem? {
        items.first { $0.id == id }
    }

    func reload() {
        let descriptor = FetchDescriptor<FoodItem>(sortBy: [SortDescriptor(\.expiresAt), SortDescriptor(\.name)])
        items = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Writes

    @discardableResult
    func add(_ draft: ItemDraft, now: Date = .now) -> FoodItem {
        let item = draft.makeItem(now: now)
        context.insert(item)
        commit()
        return item
    }

    func update(_ item: FoodItem, with draft: ItemDraft) {
        draft.apply(to: item)
        commit()
    }

    func markConsumed(_ toConsume: [FoodItem], at date: Date = .now) {
        for item in toConsume { item.consumedAt = date }
        commit()
    }

    func markConsumed(_ item: FoodItem, at date: Date = .now) {
        markConsumed([item], at: date)
    }

    func restore(_ item: FoodItem) {
        item.consumedAt = nil
        commit()
    }

    func delete(_ item: FoodItem) {
        context.delete(item)
        commit()
    }

    func deleteAll() {
        for item in items { context.delete(item) }
        commit()
    }

    func loadSampleData(now: Date = .now) {
        for item in SampleData.items(now: now) { context.insert(item) }
        commit()
    }

    private func commit() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save inventory: \(error)")
        }
        reload()
        onChange?()
    }

    // MARK: - Factories

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = inMemory
            ? ModelConfiguration("inmemory-\(UUID().uuidString)", isStoredInMemoryOnly: true)
            : ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: FoodItem.self, configurations: configuration)
    }

    /// Throwaway store for tests and previews.
    static func inMemory() -> InventoryStore {
        do {
            return InventoryStore(container: try makeContainer(inMemory: true))
        } catch {
            fatalError("Could not create in-memory container: \(error)")
        }
    }
}

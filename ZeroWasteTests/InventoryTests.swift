//
//  InventoryTests.swift
//  ZeroWasteTests
//
//  Store + view model behaviour against an in-memory SwiftData container.
//

import Foundation
import Testing
@testable import ZeroWaste

@MainActor
struct InventoryStoreTests {

    private let now = TestSupport.date(2026, 9, 7)

    @Test func addUpdateConsumeAndDeleteRoundTrip() {
        let store = InventoryStore.inMemory()
        var changes = 0
        store.onChange = { changes += 1 }

        var draft = ItemDraft(now: now)
        draft.name = "  Milk "
        draft.category = .dairy
        draft.quantity = 2
        draft.unit = "pints"
        let item = store.add(draft, now: now)

        #expect(item.name == "Milk")
        #expect(store.activeItems.count == 1)
        #expect(changes == 1)

        draft.name = "Whole milk"
        store.update(item, with: draft)
        #expect(store.item(id: item.id)?.name == "Whole milk")

        store.markConsumed(item, at: now)
        #expect(store.activeItems.isEmpty)
        #expect(store.consumedItems.count == 1)

        store.restore(item)
        #expect(store.activeItems.count == 1)

        store.delete(item)
        #expect(store.items.isEmpty)
        #expect(changes == 5)
    }

    @Test func itemsAreSortedByExpiry() {
        let store = InventoryStore.inMemory()
        var late = ItemDraft(now: now); late.name = "Late"; late.expiresAt = TestSupport.date(2026, 10, 1)
        var early = ItemDraft(now: now); early.name = "Early"; early.expiresAt = TestSupport.date(2026, 9, 8)
        store.add(late, now: now)
        store.add(early, now: now)
        #expect(store.items.map(\.name) == ["Early", "Late"])
    }

    @Test func statusBucketsUseCalendarDays() {
        let expired = TestSupport.item("A", daysUntilExpiry: -1, from: now)
        let today = TestSupport.item("B", daysUntilExpiry: 0, from: now)
        let soon = TestSupport.item("C", daysUntilExpiry: 3, from: now)
        let fresh = TestSupport.item("D", daysUntilExpiry: 4, from: now)
        #expect(expired.status(soonThresholdDays: 3, now: now, calendar: TestSupport.calendar) == .expired)
        #expect(today.status(soonThresholdDays: 3, now: now, calendar: TestSupport.calendar) == .today)
        #expect(soon.status(soonThresholdDays: 3, now: now, calendar: TestSupport.calendar) == .soon)
        #expect(fresh.status(soonThresholdDays: 3, now: now, calendar: TestSupport.calendar) == .fresh)
        #expect(expired.expiryDescription(now: now) == "Expired yesterday")
        #expect(fresh.shortExpiryLabel(now: now) == "4d")
    }
}

@MainActor
struct InventoryViewModelTests {

    private let now = TestSupport.date(2026, 9, 7)

    private func makeViewModel() -> (InventoryViewModel, InventoryStore) {
        let store = InventoryStore.inMemory()
        store.loadSampleData(now: now)
        let viewModel = InventoryViewModel(
            store: store,
            settings: AppSettings.ephemeral(),
            notifications: ExpiryNotificationService(),
            coordinator: InventoryCoordinator(),
            now: { self.now }
        )
        return (viewModel, store)
    }

    @Test func sectionsAreOrderedByUrgency() {
        let (viewModel, _) = makeViewModel()
        let statuses = viewModel.sections.map(\.status)
        #expect(statuses == statuses.sorted())
        #expect(statuses.first == .expired)
        #expect(viewModel.sections.first?.items.map(\.name) == ["Greek yogurt"])
    }

    @Test func searchAndStorageFilterNarrowTheList() {
        let (viewModel, _) = makeViewModel()
        viewModel.searchText = "milk"
        #expect(viewModel.filteredItems.map(\.name) == ["Semi-skimmed milk"])

        viewModel.searchText = ""
        viewModel.storageFilter = .freezer
        #expect(viewModel.filteredItems.map(\.name) == ["Salmon fillets"])
    }

    @Test func markUsedRemovesFromActiveList() {
        let (viewModel, store) = makeViewModel()
        let before = viewModel.items.count
        viewModel.markUsed(viewModel.items[0])
        #expect(viewModel.items.count == before - 1)
        #expect(store.consumedItems.count == 1)
    }
}

@MainActor
struct ItemFormViewModelTests {

    private let now = TestSupport.date(2026, 9, 7)

    @Test func saveRequiresANameAndReportsTheSavedItem() {
        let store = InventoryStore.inMemory()
        var saved: FoodItem?
        let viewModel = ItemFormViewModel(mode: .add, draft: ItemDraft(now: now), store: store, onSaved: { saved = $0 }, now: { self.now })

        #expect(!viewModel.canSave)
        viewModel.save()
        #expect(saved == nil)

        viewModel.draft.name = "Bread"
        viewModel.draft.category = .bakery
        viewModel.applyDefaultShelfLife()
        viewModel.save()
        #expect(saved?.name == "Bread")
        #expect(saved?.daysUntilExpiry(from: now, calendar: TestSupport.calendar) == FoodCategory.bakery.defaultShelfLifeDays)
    }
}

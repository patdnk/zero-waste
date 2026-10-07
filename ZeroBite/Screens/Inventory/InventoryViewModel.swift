//
//  InventoryViewModel.swift
//  ZeroBite
//
//  ViewModel for the Fridge list: filtering, grouping by urgency, and item actions.
//

import Foundation
import Observation

struct InventorySection: Identifiable {
    let status: ExpiryStatus
    let items: [FoodItem]
    var id: ExpiryStatus { status }
}

@MainActor
@Observable
final class InventoryViewModel {

    enum StorageFilter: Hashable, CaseIterable {
        case all, fridge, freezer, pantry

        var title: String {
            switch self {
            case .all: "All"
            case .fridge: "Fridge"
            case .freezer: "Freezer"
            case .pantry: "Cupboard"
            }
        }

        var location: StorageLocation? {
            switch self {
            case .all: nil
            case .fridge: .fridge
            case .freezer: .freezer
            case .pantry: .pantry
            }
        }
    }

    var searchText = ""
    var storageFilter: StorageFilter = .all

    private let store: InventoryStore
    private let settings: AppSettings
    private let notifications: ExpiryNotificationService
    private let coordinator: InventoryCoordinator
    private let recalls: RecallStore?
    private let now: () -> Date

    init(
        store: InventoryStore,
        settings: AppSettings,
        notifications: ExpiryNotificationService,
        coordinator: InventoryCoordinator,
        recalls: RecallStore? = nil,
        now: @escaping () -> Date = { .now }
    ) {
        self.store = store
        self.settings = settings
        self.notifications = notifications
        self.coordinator = coordinator
        self.recalls = recalls
        self.now = now
    }

    // MARK: - Derived state

    var items: [FoodItem] { store.activeItems }
    var isEmpty: Bool { items.isEmpty }
    var soonThresholdDays: Int { settings.soonThresholdDays }

    var filteredItems: [FoodItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return items.filter { item in
            if let location = storageFilter.location, item.storage != location { return false }
            if !query.isEmpty, !item.name.lowercased().contains(query) { return false }
            return true
        }
    }

    /// Fridge items that may be affected by a current FSA recall, most confident first.
    var recallMatches: [RecallMatch] {
        guard let recalls, settings.recallChecksEnabled else { return [] }
        return recalls.matches(for: items, now: now())
    }

    var recalledItemIDs: Set<UUID> { Set(recallMatches.map(\.itemID)) }

    func showRecalledItem(_ match: RecallMatch) {
        coordinator.showItem(id: match.itemID)
    }

    /// The single most urgent item, highlighted above the grid while browsing (not searching).
    var useFirstItem: FoodItem? {
        guard searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return filteredItems
            .filter { $0.status(soonThresholdDays: soonThresholdDays, now: now()).needsAttention }
            .min { $0.expiresAt < $1.expiresAt }
    }

    /// Items needing attention other than the highlighted one.
    var othersNeedingAttention: Int {
        max(attentionCount - (useFirstItem == nil ? 0 : 1), 0)
    }

    /// Freezing only makes sense for food that hasn't gone off and isn't frozen already.
    func canFreeze(_ item: FoodItem) -> Bool {
        item.storage != .freezer && item.status(soonThresholdDays: soonThresholdDays, now: now()) != .expired
    }

    var headerDate: String {
        now().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    var sections: [InventorySection] {
        Self.group(filteredItems, soonThresholdDays: soonThresholdDays, now: now())
    }

    /// Sections for the grid below the "use first" card, which already shows its item.
    var gridSections: [InventorySection] {
        let heroID = useFirstItem?.id
        return Self.group(filteredItems.filter { $0.id != heroID }, soonThresholdDays: soonThresholdDays, now: now())
    }

    private static func group(_ items: [FoodItem], soonThresholdDays: Int, now: Date) -> [InventorySection] {
        let grouped = Dictionary(grouping: items) { $0.status(soonThresholdDays: soonThresholdDays, now: now) }
        return ExpiryStatus.allCases.compactMap { status in
            grouped[status].map { InventorySection(status: status, items: $0) }
        }
    }

    var attentionCount: Int {
        items.filter { $0.status(soonThresholdDays: soonThresholdDays, now: now()).needsAttention }.count
    }

    /// Nudge to enable reminders while they're off and the user hasn't refused at the OS level.
    var showsNotificationTip: Bool {
        !settings.dismissedNotificationTip && !settings.notificationsEnabled && !notifications.isDenied
    }

    // MARK: - Actions

    func markUsed(_ item: FoodItem) {
        store.markConsumed(item, at: now())
    }

    /// Moves an item to the freezer and gives it a typical frozen shelf life of three months.
    func freeze(_ item: FoodItem) {
        guard canFreeze(item) else { return }
        var draft = ItemDraft(item: item)
        draft.storage = .freezer
        let frozenUntil = Calendar.current.date(byAdding: .month, value: 3, to: now()) ?? item.expiresAt
        draft.expiresAt = max(item.expiresAt, frozenUntil)
        store.update(item, with: draft)
    }

    func delete(_ item: FoodItem) {
        store.delete(item)
    }

    func showDetails(_ item: FoodItem) {
        coordinator.showItem(id: item.id)
    }

    func showScan() {
        coordinator.showScan()
    }

    func showAddItem() {
        coordinator.showAddItem()
    }

    func loadSampleData() {
        store.loadSampleData(now: now())
    }

    func enableNotifications() async {
        let granted = await notifications.requestAuthorization()
        settings.notificationsEnabled = granted
        settings.dismissedNotificationTip = true
    }

    func dismissNotificationTip() {
        settings.dismissedNotificationTip = true
    }
}

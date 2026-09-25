//
//  InventoryViewModel.swift
//  ZeroWaste
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
    var dismissedNotificationTip = false

    private let store: InventoryStore
    private let settings: AppSettings
    private let notifications: ExpiryNotificationService
    private let coordinator: InventoryCoordinator
    private let now: () -> Date

    init(
        store: InventoryStore,
        settings: AppSettings,
        notifications: ExpiryNotificationService,
        coordinator: InventoryCoordinator,
        now: @escaping () -> Date = { .now }
    ) {
        self.store = store
        self.settings = settings
        self.notifications = notifications
        self.coordinator = coordinator
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

    var sections: [InventorySection] {
        let grouped = Dictionary(grouping: filteredItems) { $0.status(soonThresholdDays: soonThresholdDays, now: now()) }
        return ExpiryStatus.allCases.compactMap { status in
            grouped[status].map { InventorySection(status: status, items: $0) }
        }
    }

    var attentionCount: Int {
        items.filter { $0.status(soonThresholdDays: soonThresholdDays, now: now()).needsAttention }.count
    }

    /// Nudge to enable reminders while they're off and the user hasn't refused at the OS level.
    var showsNotificationTip: Bool {
        !dismissedNotificationTip && !settings.notificationsEnabled && !notifications.isDenied
    }

    // MARK: - Actions

    func markUsed(_ item: FoodItem) {
        store.markConsumed(item, at: now())
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
        dismissedNotificationTip = true
    }

    func dismissNotificationTip() {
        dismissedNotificationTip = true
    }
}

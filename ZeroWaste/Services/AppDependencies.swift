//
//  AppDependencies.swift
//  ZeroWaste
//
//  Composition root: the long-lived services handed to coordinators, factories and
//  view models. Build with `live()` for the app, `preview()` for previews/tests.
//

import Foundation
import SwiftData

@MainActor
final class AppDependencies {

    let settings: AppSettings
    let inventory: InventoryStore
    let notifications: ExpiryNotificationService
    let recipes: [Recipe]
    let productLookup: any ProductLookup

    init(
        settings: AppSettings,
        inventory: InventoryStore,
        notifications: ExpiryNotificationService,
        recipes: [Recipe],
        productLookup: any ProductLookup
    ) {
        self.settings = settings
        self.inventory = inventory
        self.notifications = notifications
        self.recipes = recipes
        self.productLookup = productLookup

        inventory.onChange = { [weak self] in
            Task { await self?.syncNotifications() }
        }
    }

    static func live() -> AppDependencies {
        let container: ModelContainer
        do {
            container = try InventoryStore.makeContainer()
        } catch {
            fatalError("Could not open the inventory database: \(error)")
        }
        return AppDependencies(
            settings: AppSettings(),
            inventory: InventoryStore(container: container),
            notifications: ExpiryNotificationService(),
            recipes: RecipeStore.loadBundled(),
            productLookup: OpenFoodFactsLookup()
        )
    }

    /// In-memory everything, optionally pre-filled with the sample fridge.
    static func preview(withSampleData: Bool = true) -> AppDependencies {
        let inventory = InventoryStore.inMemory()
        if withSampleData { inventory.loadSampleData() }
        return AppDependencies(
            settings: AppSettings.ephemeral(),
            inventory: inventory,
            notifications: ExpiryNotificationService(),
            recipes: RecipeStore.loadBundled(),
            productLookup: OpenFoodFactsLookup()
        )
    }

    /// Re-plans every pending expiry notification from the current fridge + preferences.
    func syncNotifications() async {
        let summaries = inventory.activeItems.map {
            ExpiringItemSummary(id: $0.id, name: $0.name, expiresAt: $0.expiresAt)
        }
        await notifications.reschedule(items: summaries, preferences: settings.notificationPreferences)
    }
}

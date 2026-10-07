//
//  AppDependencies.swift
//  ZeroBite
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
    let recalls: RecallStore

    init(
        settings: AppSettings,
        inventory: InventoryStore,
        notifications: ExpiryNotificationService,
        recipes: [Recipe],
        productLookup: any ProductLookup,
        recalls: RecallStore
    ) {
        self.settings = settings
        self.inventory = inventory
        self.notifications = notifications
        self.recipes = recipes
        self.productLookup = productLookup
        self.recalls = recalls

        inventory.onChange = { [weak self] in
            Task {
                await self?.syncNotifications()
                await self?.notifyNewRecallMatches()
            }
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
            productLookup: OpenFoodFactsLookup(),
            recalls: liveRecallStore()
        )
    }

    private static func liveRecallStore() -> RecallStore {
        #if DEBUG
        // Canned alerts in a throwaway store, so they never end up in the real cache.
        if ProcessInfo.processInfo.arguments.contains("--preview-alerts") {
            return RecallStore(client: PreviewFoodAlerts(), cacheURL: nil, defaults: AppSettings.ephemeral().userDefaults)
        }
        #endif
        return RecallStore(client: FSAFoodAlertsClient(), cacheURL: RecallStore.defaultCacheURL())
    }

    /// In-memory everything, optionally pre-filled with the sample fridge.
    static func preview(withSampleData: Bool = true, alerts: any FoodAlertsFetching = PreviewFoodAlerts()) -> AppDependencies {
        let inventory = InventoryStore.inMemory()
        if withSampleData { inventory.loadSampleData() }
        let settings = AppSettings.ephemeral()
        return AppDependencies(
            settings: settings,
            inventory: inventory,
            notifications: ExpiryNotificationService(),
            recipes: RecipeStore.loadBundled(),
            productLookup: OpenFoodFactsLookup(),
            recalls: RecallStore(client: alerts, cacheURL: nil, defaults: settings.userDefaults)
        )
    }

    /// Re-plans every pending expiry notification from the current fridge + preferences.
    func syncNotifications() async {
        let summaries = inventory.activeItems.map {
            ExpiringItemSummary(id: $0.id, name: $0.name, expiresAt: $0.expiresAt)
        }
        await notifications.reschedule(items: summaries, preferences: settings.notificationPreferences)
    }

    // MARK: - Recalls

    /// Fetches new FSA alerts (throttled unless `force`) and notifies about any new matches.
    func refreshRecalls(force: Bool = false) async {
        guard settings.recallChecksEnabled else { return }
        await recalls.refresh(force: force)
        await notifyNewRecallMatches()
    }

    /// Posts one notification per match the user hasn't heard about yet.
    func notifyNewRecallMatches() async {
        guard settings.recallChecksEnabled else { return }
        let fresh = recalls.matches(for: inventory.activeItems).filter { !recalls.notifiedMatchIDs.contains($0.id) }
        guard !fresh.isEmpty else { return }
        recalls.markNotified(fresh)
        for match in fresh.prefix(3) {
            await notifications.postRecallNotice(for: match)
        }
    }
}

/// Canned alerts for previews and `--preview-alerts` debug runs: a recall that matches the
/// sample fridge's milk, and a milk allergy alert.
struct PreviewFoodAlerts: FoodAlertsFetching {
    func fetchAlerts(since: Date) async throws -> [FoodAlert] {
        [
            FoodAlert(
                id: "FSA-PRIN-PREVIEW", title: "Dairy Co recalls Semi Skimmed Milk because it may contain pieces of plastic",
                shortTitle: "Dairy Co recalls Semi Skimmed Milk", kind: .recall, created: .now,
                url: URL(string: "https://www.food.gov.uk/news-alerts/search/alerts"), business: "Dairy Co",
                otherBusinesses: [], products: [
                    .init(name: "Dairy Co Semi Skimmed Milk", packSize: "2 pints (1.136L)", productCode: nil,
                          batches: [.init(batchCode: "All batches", bestBefore: nil, useBy: "All use by dates", lotNumber: nil)]),
                ],
                allergens: [], risk: "The product may contain small pieces of plastic, which makes it unsafe to eat.",
                consumerAdvice: "Do not eat it. Return it to the store for a full refund."
            ),
            FoodAlert(
                id: "FSA-AA-PREVIEW", title: "Snack Co recalls Crisps because of undeclared milk",
                shortTitle: nil, kind: .allergy, created: .now.addingTimeInterval(-86_400), url: nil,
                business: "Snack Co", otherBusinesses: [],
                products: [.init(name: "Snack Co Cheese Crisps", packSize: "150g", productCode: nil, batches: [])],
                allergens: ["Milk"], risk: "Contains milk, which is not mentioned on the label.",
                consumerAdvice: "If you have an allergy or intolerance to milk, do not eat it."
            ),
        ]
    }
}

//
//  FoodAlertsViewModel.swift
//  ZeroBite
//
//  Recent FSA food alerts, filtered to what matters to this user: recalls that may touch
//  their fridge and allergy alerts for their allergens.
//

import Foundation
import Observation

@MainActor
@Observable
final class FoodAlertsViewModel {

    enum Filter: Hashable, CaseIterable {
        case forYou, recalls, allergy, all

        var title: String {
            switch self {
            case .forYou: "For you"
            case .recalls: "Recalls"
            case .allergy: "Allergy alerts"
            case .all: "All"
            }
        }
    }

    struct Row: Identifiable {
        let alert: FoodAlert
        /// Why it's relevant: "In your fridge: Brie" or "Contains: Milk".
        let highlight: String?
        var id: String { alert.id }
    }

    var filter: Filter = .forYou

    private let recalls: RecallStore
    private let inventory: InventoryStore
    private let settings: AppSettings
    private let now: () -> Date

    init(recalls: RecallStore, inventory: InventoryStore, settings: AppSettings, now: @escaping () -> Date = { .now }) {
        self.recalls = recalls
        self.inventory = inventory
        self.settings = settings
        self.now = now
    }

    var isRefreshing: Bool { recalls.isRefreshing }
    var errorMessage: String? { recalls.lastErrorMessage }
    var hasAllergies: Bool { !settings.allergenProfile.isEmpty }

    var lastCheckedText: String {
        guard let date = recalls.lastChecked else { return "Not checked yet" }
        return "Checked \(date.formatted(.relative(presentation: .named)))"
    }

    var rows: [Row] {
        let matches = recalls.matches(for: inventory.activeItems, now: now())
        let matchedNames = Dictionary(grouping: matches, by: \.alert.id).mapValues { $0.map(\.itemName) }
        let allergens = settings.allergenProfile

        return recalls.alerts.compactMap { alert in
            let fridge = matchedNames[alert.id].map { "In your fridge: " + $0.joined(separator: ", ") }
            let concerns = alert.concerns(allergens)
            let allergy = concerns.isEmpty ? nil : "Contains: " + concerns.map(\.label).joined(separator: ", ")
            let highlight = fridge ?? allergy

            switch filter {
            case .forYou: guard highlight != nil else { return nil }
            case .recalls: guard alert.kind != .allergy else { return nil }
            case .allergy: guard alert.kind == .allergy else { return nil }
            case .all: break
            }
            return Row(alert: alert, highlight: highlight)
        }
    }

    var emptyTitle: String {
        switch filter {
        case .forYou: "Nothing affects you right now"
        case .recalls: "No recent recalls"
        case .allergy: "No recent allergy alerts"
        case .all: "No alerts downloaded yet"
        }
    }

    var emptyMessage: String {
        if filter == .forYou && !hasAllergies {
            return "No recall matches anything in your fridge. Add your allergies in Settings to see allergy alerts here too."
        }
        if filter == .forYou {
            return "No recall matches anything in your fridge, and there are no allergy alerts for your allergies."
        }
        return "Pull down to check the Food Standards Agency again."
    }

    func refresh() async {
        await recalls.refresh(force: true)
    }
}

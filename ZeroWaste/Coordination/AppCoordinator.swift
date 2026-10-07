//
//  AppCoordinator.swift
//  ZeroWaste
//
//  Main-content coordinator: tabs, sheets, alerts, and the feature coordinators.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {

    // MARK: - Navigation State

    var selectedTab: AppTab = .fridge
    var presentedSheet: SheetDestination?
    var alertConfig: AlertConfig?
    /// Onboarding replayed from Settings, shown full screen over the tabs.
    var isShowingHowItWorks = false

    let dependencies: AppDependencies

    // MARK: - Feature Coordinators

    let inventoryCoordinator: InventoryCoordinator
    let recipesCoordinator: RecipesCoordinator
    let settingsCoordinator: SettingsCoordinator

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        inventoryCoordinator = InventoryCoordinator()
        recipesCoordinator = RecipesCoordinator()
        settingsCoordinator = SettingsCoordinator()
        inventoryCoordinator.parent = self
        recipesCoordinator.parent = self
        settingsCoordinator.parent = self
    }

    // MARK: - Tabs

    enum AppTab: Hashable, CaseIterable {
        case fridge, recipes, settings

        var title: String {
            switch self {
            case .fridge: "Fridge"
            case .recipes: "Recipes"
            case .settings: "Settings"
            }
        }

        var symbol: String {
            switch self {
            case .fridge: "refrigerator"
            case .recipes: "frying.pan"
            case .settings: "gearshape"
            }
        }

        var selectedSymbol: String {
            switch self {
            case .fridge: "refrigerator.fill"
            case .recipes: "frying.pan.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    // MARK: - Sheets

    enum SheetDestination: Identifiable {
        case scan
        case addItem(ItemDraft)
        case editItem(UUID)
        case cooked(recipeID: String)

        var id: String {
            switch self {
            case .scan: "scan"
            case .addItem: "addItem"
            case .editItem(let id): "editItem-\(id.uuidString)"
            case .cooked(let recipeID): "cooked-\(recipeID)"
            }
        }
    }

    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func showHowItWorks() {
        isShowingHowItWorks = true
    }

    // MARK: - Alerts

    struct AlertConfig: Identifiable {
        let id = UUID()
        let title: String
        let message: String?
        let primaryButton: AlertButton
        let secondaryButton: AlertButton?

        struct AlertButton {
            let title: String
            let isDestructive: Bool
            let action: () -> Void

            init(title: String, isDestructive: Bool = false, action: @escaping () -> Void = {}) {
                self.title = title
                self.isDestructive = isDestructive
                self.action = action
            }
        }
    }

    func showAlert(
        title: String,
        message: String? = nil,
        primaryButton: AlertConfig.AlertButton,
        secondaryButton: AlertConfig.AlertButton? = nil
    ) {
        alertConfig = AlertConfig(title: title, message: message, primaryButton: primaryButton, secondaryButton: secondaryButton)
    }

    func dismissAlert() {
        alertConfig = nil
    }

    // MARK: - Cross-feature routing

    /// Deep link (e.g. from a notification tap): jump to the Fridge tab and open the item.
    func showItem(id: UUID) {
        presentedSheet = nil
        selectedTab = .fridge
        inventoryCoordinator.popToRoot()
        inventoryCoordinator.showItem(id: id)
    }
}

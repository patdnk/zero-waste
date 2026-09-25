//
//  MainView.swift
//  ZeroWaste
//
//  Tab navigation bound to AppCoordinator, plus app-level sheets and alerts.
//

import SwiftUI

struct MainView: View {
    @Bindable var coordinator: AppCoordinator

    private var dependencies: AppDependencies { coordinator.dependencies }

    var body: some View {
        TabView(selection: Binding(
            get: { coordinator.selectedTab },
            set: { coordinator.selectTab($0) }
        )) {
            ForEach(AppCoordinator.AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.symbol, value: tab) {
                    tabContent(for: tab)
                }
            }
        }
        .tint(Constants.Brand)
        .sheet(item: $coordinator.presentedSheet) { destination in
            sheetContent(for: destination)
        }
        .alert(
            coordinator.alertConfig?.title ?? "",
            isPresented: Binding(
                get: { coordinator.alertConfig != nil },
                set: { if !$0 { coordinator.dismissAlert() } }
            )
        ) {
            if let config = coordinator.alertConfig {
                Button(config.primaryButton.title, role: config.primaryButton.isDestructive ? .destructive : nil) {
                    config.primaryButton.action()
                    coordinator.dismissAlert()
                }
                if let secondary = config.secondaryButton {
                    Button(secondary.title, role: .cancel) {
                        secondary.action()
                        coordinator.dismissAlert()
                    }
                }
            }
        } message: {
            if let message = coordinator.alertConfig?.message {
                Text(message)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppCoordinator.AppTab) -> some View {
        switch tab {
        case .fridge:
            InventoryFactory.makeList(coordinator: coordinator.inventoryCoordinator, dependencies: dependencies)
        case .recipes:
            RecipesFactory.makeList(coordinator: coordinator.recipesCoordinator, dependencies: dependencies)
        case .settings:
            SettingsFactory.make(coordinator: coordinator.settingsCoordinator, dependencies: dependencies)
        }
    }

    @ViewBuilder
    private func sheetContent(for destination: AppCoordinator.SheetDestination) -> some View {
        switch destination {
        case .scan:
            ScanFactory.makeFlow(dependencies: dependencies, onFinished: { coordinator.dismissSheet() })
        case .addItem(let draft):
            NavigationStack {
                InventoryFactory.makeForm(mode: .add, draft: draft, dependencies: dependencies,
                                          onCancel: { coordinator.dismissSheet() },
                                          onSaved: { _ in coordinator.dismissSheet() })
            }
        case .editItem(let id):
            NavigationStack {
                if let item = dependencies.inventory.item(id: id) {
                    InventoryFactory.makeForm(mode: .edit(id), draft: ItemDraft(item: item), dependencies: dependencies,
                                              onCancel: { coordinator.dismissSheet() },
                                              onSaved: { _ in coordinator.dismissSheet() })
                } else {
                    ContentUnavailableView("Item not found", systemImage: "questionmark.circle")
                }
            }
        case .cooked(let recipeID):
            RecipesFactory.makeCooked(recipeID: recipeID, dependencies: dependencies, onDone: { coordinator.dismissSheet() })
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    MainView(coordinator: AppCoordinator(dependencies: .preview()))
}

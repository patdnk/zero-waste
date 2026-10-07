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

    @State private var isKeyboardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            // Every tab stays alive in the ZStack so scroll position and search text survive switching.
            ZStack {
                ForEach(AppCoordinator.AppTab.allCases, id: \.self) { tab in
                    let isSelected = coordinator.selectedTab == tab
                    tabContent(for: tab)
                        .opacity(isSelected ? 1 : 0)
                        .allowsHitTesting(isSelected)
                        .accessibilityHidden(!isSelected)
                }
            }
            // Root screens hide the navigation bar, so cover the status bar ourselves.
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    Constants.BackgroundPrimary
                        .frame(height: geo.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
            }

            // Hidden while typing so the bottom search field sits directly on the keyboard.
            if !isKeyboardVisible {
                AppTabBar(selection: Binding(
                    get: { coordinator.selectedTab },
                    set: { coordinator.selectTab($0) }
                ))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .tint(Constants.BrandOrange)
        .fullScreenCover(isPresented: $coordinator.isShowingHowItWorks) {
            WelcomeFactory.make(mode: .replay, dependencies: dependencies) {
                coordinator.isShowingHowItWorks = false
            }
        }
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

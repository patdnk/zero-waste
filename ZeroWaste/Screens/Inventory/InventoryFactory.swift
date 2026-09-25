//
//  InventoryFactory.swift
//  ZeroWaste
//
//  Factory for Fridge feature screens (MVVM-C).
//

import SwiftUI

@MainActor
enum InventoryFactory {

    static func makeList(coordinator: InventoryCoordinator, dependencies: AppDependencies) -> some View {
        ViewModelHost(InventoryViewModel(
            store: dependencies.inventory,
            settings: dependencies.settings,
            notifications: dependencies.notifications,
            coordinator: coordinator
        )) { viewModel in
            InventoryView(viewModel: viewModel, coordinator: coordinator, dependencies: dependencies)
        }
    }

    static func makeDetail(
        itemID: UUID,
        dependencies: AppDependencies,
        onEdit: @escaping (UUID) -> Void,
        onShowRecipe: @escaping (String) -> Void,
        onDeleted: @escaping () -> Void
    ) -> some View {
        ViewModelHost(ItemDetailViewModel(
            itemID: itemID,
            store: dependencies.inventory,
            settings: dependencies.settings,
            recipes: dependencies.recipes,
            onEdit: onEdit,
            onShowRecipe: onShowRecipe,
            onDeleted: onDeleted
        )) { viewModel in
            ItemDetailView(viewModel: viewModel)
        }
    }

    static func makeForm(
        mode: ItemFormViewModel.Mode,
        draft: ItemDraft,
        dependencies: AppDependencies,
        onCancel: @escaping () -> Void,
        onSaved: @escaping (FoodItem) -> Void
    ) -> some View {
        ViewModelHost(ItemFormViewModel(mode: mode, draft: draft, store: dependencies.inventory, onSaved: onSaved)) { viewModel in
            ItemFormView(viewModel: viewModel, onCancel: onCancel)
        }
    }
}

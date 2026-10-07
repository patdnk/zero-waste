//
//  RecipesFactory.swift
//  ZeroBite
//
//  Factory for Recipes feature screens (MVVM-C).
//

import SwiftUI

@MainActor
enum RecipesFactory {

    static func makeList(coordinator: RecipesCoordinator, dependencies: AppDependencies) -> some View {
        ViewModelHost(RecipesViewModel(
            store: dependencies.inventory,
            settings: dependencies.settings,
            recipes: dependencies.recipes,
            coordinator: coordinator
        )) { viewModel in
            RecipesView(viewModel: viewModel, coordinator: coordinator, dependencies: dependencies)
        }
    }

    static func makeDetail(
        recipeID: String,
        dependencies: AppDependencies,
        onShowItem: @escaping (UUID) -> Void,
        onCooked: @escaping (String) -> Void
    ) -> some View {
        ViewModelHost(RecipeDetailViewModel(
            recipeID: recipeID,
            store: dependencies.inventory,
            settings: dependencies.settings,
            recipes: dependencies.recipes,
            onShowItem: onShowItem,
            onCooked: onCooked
        )) { viewModel in
            RecipeDetailView(viewModel: viewModel)
        }
    }

    static func makeCooked(recipeID: String, dependencies: AppDependencies, onDone: @escaping () -> Void) -> some View {
        ViewModelHost(CookedViewModel(
            recipeID: recipeID,
            store: dependencies.inventory,
            settings: dependencies.settings,
            recipes: dependencies.recipes,
            onDone: onDone
        )) { viewModel in
            CookedView(viewModel: viewModel)
        }
    }
}

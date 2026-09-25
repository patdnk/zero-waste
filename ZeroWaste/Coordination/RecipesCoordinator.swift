//
//  RecipesCoordinator.swift
//  ZeroWaste
//
//  Navigation within the Recipes tab.
//

import Foundation
import Observation
import SwiftUI

enum RecipesRoute: Hashable {
    case recipe(String)
    case itemDetail(UUID)
}

@MainActor
@Observable
final class RecipesCoordinator {

    var navigationPath = NavigationPath()
    weak var parent: AppCoordinator?

    init(parent: AppCoordinator? = nil) {
        self.parent = parent
    }

    func showRecipe(id: String) {
        navigationPath.append(RecipesRoute.recipe(id))
    }

    func showItem(id: UUID) {
        navigationPath.append(RecipesRoute.itemDetail(id))
    }

    func showCooked(recipeID: String) {
        parent?.presentSheet(.cooked(recipeID: recipeID))
    }

    func showEditItem(id: UUID) {
        parent?.presentSheet(.editItem(id))
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

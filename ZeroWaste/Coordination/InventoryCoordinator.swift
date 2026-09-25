//
//  InventoryCoordinator.swift
//  ZeroWaste
//
//  Navigation within the Fridge tab.
//

import Foundation
import Observation
import SwiftUI

enum InventoryRoute: Hashable {
    case itemDetail(UUID)
    case recipe(String)
}

@MainActor
@Observable
final class InventoryCoordinator {

    var navigationPath = NavigationPath()
    weak var parent: AppCoordinator?

    init(parent: AppCoordinator? = nil) {
        self.parent = parent
    }

    func showItem(id: UUID) {
        navigationPath.append(InventoryRoute.itemDetail(id))
    }

    func showRecipe(id: String) {
        navigationPath.append(InventoryRoute.recipe(id))
    }

    func showScan() {
        parent?.presentSheet(.scan)
    }

    func showAddItem() {
        parent?.presentSheet(.addItem(ItemDraft()))
    }

    func showEditItem(id: UUID) {
        parent?.presentSheet(.editItem(id))
    }

    func showCooked(recipeID: String) {
        parent?.presentSheet(.cooked(recipeID: recipeID))
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

//
//  SettingsCoordinator.swift
//  ZeroWaste
//
//  Settings has no pushed routes today; it surfaces confirmations through the parent.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsCoordinator {

    weak var parent: AppCoordinator?

    init(parent: AppCoordinator? = nil) {
        self.parent = parent
    }

    func confirm(title: String, message: String, actionTitle: String, isDestructive: Bool = true, action: @escaping () -> Void) {
        parent?.showAlert(
            title: title,
            message: message,
            primaryButton: .init(title: actionTitle, isDestructive: isDestructive, action: action),
            secondaryButton: .init(title: "Cancel")
        )
    }

    func showHowItWorks() {
        parent?.showHowItWorks()
    }

    func showInfo(title: String, message: String) {
        parent?.showAlert(title: title, message: message, primaryButton: .init(title: "OK"))
    }
}

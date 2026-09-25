//
//  WelcomeViewModel.swift
//  ZeroWaste
//
//  First-run intro + notification opt-in.
//

import Foundation
import Observation

@MainActor
@Observable
final class WelcomeViewModel {

    enum Step: Equatable {
        case intro
        case requesting
        case denied
    }

    private(set) var step: Step = .intro

    private let settings: AppSettings
    private let notifications: ExpiryNotificationService
    private let onComplete: () -> Void

    init(settings: AppSettings, notifications: ExpiryNotificationService, onComplete: @escaping () -> Void) {
        self.settings = settings
        self.notifications = notifications
        self.onComplete = onComplete
    }

    var isRequesting: Bool { step == .requesting }

    func enableReminders() async {
        step = .requesting
        let granted = await notifications.requestAuthorization()
        settings.notificationsEnabled = granted
        if granted {
            onComplete()
        } else {
            step = .denied
        }
    }

    func skip() {
        settings.notificationsEnabled = false
        onComplete()
    }

    func continueAfterDenied() {
        onComplete()
    }
}

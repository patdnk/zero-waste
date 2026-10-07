//
//  WelcomeViewModel.swift
//  ZeroWaste
//
//  Onboarding: a short paged explainer of how the app works, ending (on first run) with the
//  notification opt-in. Can be replayed from Settings without the permission step.
//

import Foundation
import Observation

@MainActor
@Observable
final class WelcomeViewModel {

    enum Mode: Equatable {
        /// First launch: explainer pages, then ask for notification permission.
        case firstRun
        /// Opened from Settings: explainer pages only.
        case replay
    }

    enum Page: Hashable, CaseIterable {
        case welcome, scan, remind, cook, reminders
    }

    enum Step: Equatable {
        case intro
        case requesting
        case denied
    }

    let mode: Mode
    let pages: [Page]
    var currentPage: Page
    private(set) var step: Step = .intro

    private let settings: AppSettings
    private let notifications: ExpiryNotificationService
    private let onComplete: () -> Void

    init(
        mode: Mode = .firstRun,
        settings: AppSettings,
        notifications: ExpiryNotificationService,
        onComplete: @escaping () -> Void
    ) {
        self.mode = mode
        self.settings = settings
        self.notifications = notifications
        self.onComplete = onComplete
        pages = mode == .firstRun ? Page.allCases : Page.allCases.filter { $0 != .reminders }
        currentPage = pages[0]
    }

    // MARK: - Paging

    var pageIndex: Int { pages.firstIndex(of: currentPage) ?? 0 }
    var isLastPage: Bool { currentPage == pages.last }
    var isRequesting: Bool { step == .requesting }

    var primaryTitle: String {
        switch currentPage {
        case .reminders: step == .denied ? "Continue" : "Turn on reminders"
        case .cook: mode == .replay ? "Done" : "Next"
        case .welcome: "Show me how"
        default: "Next"
        }
    }

    /// Advances, or finishes on the last page (asking for permission on first run).
    func primaryAction() async {
        switch currentPage {
        case .reminders:
            if step == .denied {
                continueAfterDenied()
            } else {
                await enableReminders()
            }
        default:
            if isLastPage {
                finish()
            } else {
                currentPage = pages[pageIndex + 1]
            }
        }
    }

    /// Jumps past the explainer: to the permission page on first run, or closes when replaying.
    func skipIntro() {
        if mode == .firstRun, pages.contains(.reminders) {
            currentPage = .reminders
        } else {
            finish()
        }
    }

    // MARK: - Notifications

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

    func finish() {
        onComplete()
    }
}

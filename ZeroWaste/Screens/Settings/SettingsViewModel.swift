//
//  SettingsViewModel.swift
//  ZeroWaste
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class SettingsViewModel {

    enum NotificationState: Equatable {
        case on
        case off
        /// The user refused at the OS level; only the Settings app can change that.
        case denied
    }

    private(set) var isUpdatingNotifications = false

    private let dependencies: AppDependencies
    private let coordinator: SettingsCoordinator

    init(dependencies: AppDependencies, coordinator: SettingsCoordinator) {
        self.dependencies = dependencies
        self.coordinator = coordinator
    }

    private var settings: AppSettings { dependencies.settings }
    private var notifications: ExpiryNotificationService { dependencies.notifications }
    private var store: InventoryStore { dependencies.inventory }

    // MARK: - Notifications

    var notificationState: NotificationState {
        if settings.notificationsEnabled && notifications.isAuthorized { return .on }
        if notifications.isDenied { return .denied }
        return .off
    }

    var notificationsEnabled: Bool { notificationState == .on }

    var leadDays: Int {
        get { settings.leadDays }
        set {
            settings.leadDays = max(1, min(14, newValue))
            resync()
        }
    }

    var notifyTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: settings.notifyHour, minute: settings.notifyMinute)) ?? .now
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            settings.notifyHour = components.hour ?? 9
            settings.notifyMinute = components.minute ?? 0
            resync()
        }
    }

    var soonThresholdDays: Int {
        get { settings.soonThresholdDays }
        set {
            settings.soonThresholdDays = max(1, min(14, newValue))
            resync()
        }
    }

    func refresh() async {
        await notifications.refreshAuthorizationStatus()
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        isUpdatingNotifications = true
        defer { isUpdatingNotifications = false }
        if enabled {
            let granted = await notifications.requestAuthorization()
            settings.notificationsEnabled = granted
            if !granted {
                coordinator.showInfo(
                    title: "Notifications are off",
                    message: "Allow notifications for Zero Waste in the Settings app to get expiry reminders."
                )
            }
        } else {
            settings.notificationsEnabled = false
        }
        await dependencies.syncNotifications()
    }

    func sendTestNotification() async {
        await notifications.sendTestNotification()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Data

    var activeItemCount: Int { store.activeItems.count }
    var usedItemCount: Int { store.consumedItems.count }
    var recipeCount: Int { dependencies.recipes.count }

    var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    func loadSampleData() {
        store.loadSampleData()
    }

    func clearUsedHistory() {
        let used = store.consumedItems
        guard !used.isEmpty else { return }
        coordinator.confirm(
            title: "Clear used-up history?",
            message: "Removes \(used.count) items you've already marked as used.",
            actionTitle: "Clear"
        ) { [store] in
            for item in used { store.delete(item) }
        }
    }

    func deleteEverything() {
        coordinator.confirm(
            title: "Delete everything?",
            message: "This removes every item from your fridge. It can't be undone.",
            actionTitle: "Delete all"
        ) { [store] in
            store.deleteAll()
        }
    }

    private func resync() {
        Task { await dependencies.syncNotifications() }
    }

    func showHowItWorks() {
        coordinator.showHowItWorks()
    }
}

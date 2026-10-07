//
//  ExpiryNotificationService.swift
//  ZeroBite
//
//  Schedules local notifications for expiring food. Everything is re-planned from scratch
//  after each inventory change so the pending set always mirrors the fridge.
//

import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class ExpiryNotificationService {

    nonisolated static let itemIDKey = "itemID"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let planner = ExpiryNotificationPlanner()

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    var isDenied: Bool { authorizationStatus == .denied }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Prompts the system permission dialog. Returns whether notifications are now allowed.
    func requestAuthorization() async -> Bool {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Fall through: status below reflects reality either way.
        }
        await refreshAuthorizationStatus()
        return isAuthorized
    }

    func reschedule(items: [ExpiringItemSummary], preferences: NotificationPreferences, now: Date = .now) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(ExpiryNotificationPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        guard preferences.enabled, isAuthorized else { return }

        for planned in planner.plan(items: items, preferences: preferences, now: now) {
            let content = UNMutableNotificationContent()
            content.title = planned.title
            content.body = planned.body
            content.sound = .default
            content.userInfo = [Self.itemIDKey: planned.itemID.uuidString]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: planned.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Immediate alert that something in the fridge may be recalled. Tapping it opens the item.
    func postRecallNotice(for match: RecallMatch) async {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = match.confidence == .likely ? "Recall: check your \(match.itemName)" : "Possible recall: \(match.itemName)"
        content.body = "\(match.alert.displayTitle). Check the pack before eating it."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [Self.itemIDKey: match.itemID.uuidString]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "zerobite.recall.\(match.id)", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Zero Bite reminders are on"
        content.body = "This is how you'll hear about food that's about to expire."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "zerobite.test", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

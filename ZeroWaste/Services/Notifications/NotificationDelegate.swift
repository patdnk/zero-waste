//
//  NotificationDelegate.swift
//  ZeroWaste
//
//  Shows banners while the app is in the foreground and routes taps to the item.
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Set by the app to deep-link into the tapped item.
    var onOpenItem: (@Sendable (UUID) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let raw = userInfo[ExpiryNotificationService.itemIDKey] as? String,
              let id = UUID(uuidString: raw)
        else { return }
        onOpenItem?(id)
    }
}

//
//  NotificationPreferences.swift
//  ZeroBite
//

import Foundation

struct NotificationPreferences: Equatable, Sendable {
    var enabled: Bool
    /// Days before expiry for the first heads-up.
    var leadDays: Int
    var hour: Int
    var minute: Int

    static let `default` = NotificationPreferences(enabled: false, leadDays: 3, hour: 9, minute: 0)
}

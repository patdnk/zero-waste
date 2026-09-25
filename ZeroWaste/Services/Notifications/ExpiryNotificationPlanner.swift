//
//  ExpiryNotificationPlanner.swift
//  ZeroWaste
//
//  Pure planning of which local notifications an item needs. No UserNotifications
//  dependency so it is trivially unit-testable.
//

import Foundation

struct ExpiringItemSummary: Equatable, Sendable {
    let id: UUID
    let name: String
    let expiresAt: Date
}

struct PlannedNotification: Equatable, Sendable {
    let id: String
    let itemID: UUID
    let title: String
    let body: String
    let fireDate: Date
}

struct ExpiryNotificationPlanner: Sendable {

    static let identifierPrefix = "zerowaste.item."

    /// iOS keeps at most 64 pending local notifications per app; leave headroom.
    var limit = 60
    var calendar: Calendar = .current

    func plan(items: [ExpiringItemSummary], preferences: NotificationPreferences, now: Date = .now) -> [PlannedNotification] {
        guard preferences.enabled else { return [] }
        return items
            .flatMap { plan(item: $0, preferences: preferences, now: now) }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(limit)
            .map { $0 }
    }

    func plan(item: ExpiringItemSummary, preferences: NotificationPreferences, now: Date = .now) -> [PlannedNotification] {
        let expiryDay = calendar.startOfDay(for: item.expiresAt)

        func fireTime(daysFromExpiry offset: Int) -> Date? {
            guard let day = calendar.date(byAdding: .day, value: offset, to: expiryDay) else { return nil }
            return calendar.date(bySettingHour: preferences.hour, minute: preferences.minute, second: 0, of: day)
        }

        let leadPhrase = preferences.leadDays == 1 ? "tomorrow" : "in \(preferences.leadDays) days"
        let candidates: [(suffix: String, date: Date?, title: String, body: String)] = [
            ("soon", fireTime(daysFromExpiry: -preferences.leadDays),
             "\(item.name) expires \(leadPhrase)",
             "Plan a meal around it — Zero Waste has recipe ideas."),
            ("today", fireTime(daysFromExpiry: 0),
             "\(item.name) expires today",
             "Use it today or freeze it."),
            ("expired", fireTime(daysFromExpiry: 1),
             "\(item.name) has expired",
             "Check it and update your fridge."),
        ]

        return candidates.compactMap { candidate in
            guard let date = candidate.date, date > now else { return nil }
            return PlannedNotification(
                id: "\(Self.identifierPrefix)\(item.id.uuidString).\(candidate.suffix)",
                itemID: item.id,
                title: candidate.title,
                body: candidate.body,
                fireDate: date
            )
        }
    }
}

//
//  ExpiryNotificationPlannerTests.swift
//  ZeroBiteTests
//

import Foundation
import Testing
@testable import ZeroBite

struct ExpiryNotificationPlannerTests {

    private let now = TestSupport.date(2026, 9, 7, hour: 8)
    private let prefs = NotificationPreferences(enabled: true, leadDays: 3, hour: 9, minute: 30)
    private var planner: ExpiryNotificationPlanner { ExpiryNotificationPlanner(calendar: TestSupport.calendar) }

    @Test func plansLeadTodayAndExpiredReminders() {
        let item = ExpiringItemSummary(id: UUID(), name: "Milk", expiresAt: TestSupport.date(2026, 9, 12))
        let planned = planner.plan(item: item, preferences: prefs, now: now)

        #expect(planned.map(\.fireDate) == [
            TestSupport.date(2026, 9, 9, hour: 9).addingTimeInterval(30 * 60),
            TestSupport.date(2026, 9, 12, hour: 9).addingTimeInterval(30 * 60),
            TestSupport.date(2026, 9, 13, hour: 9).addingTimeInterval(30 * 60),
        ])
        #expect(planned[0].title == "Milk expires in 3 days")
        #expect(planned[1].title == "Milk expires today")
        #expect(planned[2].title == "Milk has expired")
        #expect(planned.allSatisfy { $0.id.hasPrefix(ExpiryNotificationPlanner.identifierPrefix + item.id.uuidString) })
    }

    @Test func dropsRemindersAlreadyInThePast() {
        let item = ExpiringItemSummary(id: UUID(), name: "Yogurt", expiresAt: TestSupport.date(2026, 9, 7))
        let planned = planner.plan(item: item, preferences: prefs, now: now)
        // Lead reminder was on the 4th (past); today's 09:30 is still ahead of 08:00; expired fires tomorrow.
        #expect(planned.map(\.title) == ["Yogurt expires today", "Yogurt has expired"])

        let longGone = ExpiringItemSummary(id: UUID(), name: "Old", expiresAt: TestSupport.date(2026, 8, 1))
        #expect(planner.plan(item: longGone, preferences: prefs, now: now).isEmpty)
    }

    @Test func disabledPreferencesPlanNothingAndLimitIsRespected() {
        let items = (0..<40).map { ExpiringItemSummary(id: UUID(), name: "Item \($0)", expiresAt: TestSupport.date(2026, 10, 1 + $0 % 28)) }
        #expect(planner.plan(items: items, preferences: NotificationPreferences(enabled: false, leadDays: 3, hour: 9, minute: 0), now: now).isEmpty)

        let planned = planner.plan(items: items, preferences: prefs, now: now)
        #expect(planned.count == 60)
        #expect(planned == planned.sorted { $0.fireDate < $1.fireDate })
    }

    @Test func singleDayLeadSaysTomorrow() {
        let item = ExpiringItemSummary(id: UUID(), name: "Bread", expiresAt: TestSupport.date(2026, 9, 12))
        let planned = planner.plan(item: item, preferences: NotificationPreferences(enabled: true, leadDays: 1, hour: 9, minute: 0), now: now)
        #expect(planned.first?.title == "Bread expires tomorrow")
    }
}

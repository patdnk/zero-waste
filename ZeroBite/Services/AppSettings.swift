//
//  AppSettings.swift
//  ZeroBite
//
//  User preferences persisted in UserDefaults. Observable so screens update live.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {

    private enum Keys {
        static let hasCompletedWelcome = "hasCompletedWelcome"
        static let notificationsEnabled = "notificationsEnabled"
        static let leadDays = "notificationLeadDays"
        static let notifyHour = "notifyHour"
        static let notifyMinute = "notifyMinute"
        static let soonThresholdDays = "soonThresholdDays"
        static let dismissedNotificationTip = "dismissedNotificationTip"
        static let recallChecksEnabled = "recallChecksEnabled"
        static let allergens = "allergens"
    }

    private let defaults: UserDefaults

    /// First-run welcome (intro + notification opt-in) has been seen.
    var hasCompletedWelcome: Bool {
        didSet { defaults.set(hasCompletedWelcome, forKey: Keys.hasCompletedWelcome) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    /// Days before expiry for the first reminder.
    var leadDays: Int {
        didSet { defaults.set(leadDays, forKey: Keys.leadDays) }
    }

    var notifyHour: Int {
        didSet { defaults.set(notifyHour, forKey: Keys.notifyHour) }
    }

    var notifyMinute: Int {
        didSet { defaults.set(notifyMinute, forKey: Keys.notifyMinute) }
    }

    /// Items expiring within this many days are shown as "expiring soon".
    var soonThresholdDays: Int {
        didSet { defaults.set(soonThresholdDays, forKey: Keys.soonThresholdDays) }
    }

    /// The Fridge screen's "turn on reminders" tip was answered (turned on or "Not now").
    var dismissedNotificationTip: Bool {
        didSet { defaults.set(dismissedNotificationTip, forKey: Keys.dismissedNotificationTip) }
    }

    /// Check the Food Standards Agency for recalls and allergy alerts.
    var recallChecksEnabled: Bool {
        didSet { defaults.set(recallChecksEnabled, forKey: Keys.recallChecksEnabled) }
    }

    /// Allergens the user wants allergy alerts for (FSA allergen labels, e.g. "Milk", "Peanuts").
    var allergens: [String] {
        didSet { defaults.set(allergens, forKey: Keys.allergens) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedWelcome = defaults.bool(forKey: Keys.hasCompletedWelcome)
        notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        leadDays = defaults.object(forKey: Keys.leadDays) as? Int ?? NotificationPreferences.default.leadDays
        notifyHour = defaults.object(forKey: Keys.notifyHour) as? Int ?? NotificationPreferences.default.hour
        notifyMinute = defaults.object(forKey: Keys.notifyMinute) as? Int ?? NotificationPreferences.default.minute
        soonThresholdDays = defaults.object(forKey: Keys.soonThresholdDays) as? Int ?? 3
        dismissedNotificationTip = defaults.bool(forKey: Keys.dismissedNotificationTip)
        recallChecksEnabled = defaults.object(forKey: Keys.recallChecksEnabled) as? Bool ?? true
        allergens = defaults.stringArray(forKey: Keys.allergens) ?? []
    }

    var notificationPreferences: NotificationPreferences {
        NotificationPreferences(enabled: notificationsEnabled, leadDays: leadDays, hour: notifyHour, minute: notifyMinute)
    }

    /// The backing store, so related stores (e.g. recall dismissals) share the same suite.
    var userDefaults: UserDefaults { defaults }

    /// Isolated defaults for tests and previews.
    static func ephemeral() -> AppSettings {
        let suite = UserDefaults(suiteName: "zerobite.ephemeral.\(UUID().uuidString)")!
        suite.removePersistentDomain(forName: suite.description)
        return AppSettings(defaults: suite)
    }
}

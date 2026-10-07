//
//  RecallStore.swift
//  ZeroBite
//
//  Fetches recent UK food alerts from the Food Standards Agency, caches them on disk, and
//  keeps the user's "not my batch" dismissals. Matching against the fridge is done on demand
//  with RecallMatcher so it always reflects the current inventory.
//

import Foundation
import Observation

protocol FoodAlertsFetching: Sendable {
    func fetchAlerts(since: Date) async throws -> [FoodAlert]
}

/// Free, keyless FSA Food Alerts API (Open Government Licence v3.0).
/// https://data.food.gov.uk/food-alerts/ui/reference
struct FSAFoodAlertsClient: FoodAlertsFetching {

    var session: URLSession = .shared

    func fetchAlerts(since: Date) async throws -> [FoodAlert] {
        var components = URLComponents(string: "https://data.food.gov.uk/food-alerts/id.json")!
        components.queryItems = [
            URLQueryItem(name: "_view", value: "full"),
            URLQueryItem(name: "_sort", value: "-created"),
            URLQueryItem(name: "_limit", value: "200"),
            URLQueryItem(name: "min-created", value: FSAAlertResponse.dayFormatter.string(from: since)),
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ZeroBite-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(FSAAlertResponse.self, from: data).items
    }
}

@MainActor
@Observable
final class RecallStore {

    private(set) var alerts: [FoodAlert] = []
    private(set) var lastChecked: Date?
    private(set) var isRefreshing = false
    private(set) var lastErrorMessage: String?
    private(set) var dismissedMatchIDs: Set<String>

    /// Matches the user has already been notified about, so each one alerts only once.
    private(set) var notifiedMatchIDs: Set<String>

    private let client: any FoodAlertsFetching
    private let cacheURL: URL?
    private let defaults: UserDefaults

    private enum Keys {
        static let lastChecked = "recalls.lastChecked"
        static let dismissed = "recalls.dismissedMatches"
        static let notified = "recalls.notifiedMatches"
    }

    /// How far back to fetch; matches older than RecallMatcher's lookback are ignored anyway.
    static let historyDays = 120
    /// Don't hit the API more often than this unless the user asks.
    static let refreshInterval: TimeInterval = 6 * 60 * 60

    init(client: any FoodAlertsFetching, cacheURL: URL?, defaults: UserDefaults = .standard) {
        self.client = client
        self.cacheURL = cacheURL
        self.defaults = defaults
        lastChecked = defaults.object(forKey: Keys.lastChecked) as? Date
        dismissedMatchIDs = Set(defaults.stringArray(forKey: Keys.dismissed) ?? [])
        notifiedMatchIDs = Set(defaults.stringArray(forKey: Keys.notified) ?? [])
        alerts = Self.loadCache(from: cacheURL)
    }

    static func defaultCacheURL() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("fsa-food-alerts.json")
    }

    // MARK: - Matching

    func matches(for items: [FoodItem], now: Date = .now) -> [RecallMatch] {
        RecallMatcher(now: now).matches(alerts: alerts, items: items, dismissed: dismissedMatchIDs)
    }

    func dismiss(_ match: RecallMatch) {
        dismissedMatchIDs.insert(match.id)
        defaults.set(Array(dismissedMatchIDs), forKey: Keys.dismissed)
    }

    func markNotified(_ matches: [RecallMatch]) {
        notifiedMatchIDs.formUnion(matches.map(\.id))
        defaults.set(Array(notifiedMatchIDs), forKey: Keys.notified)
    }

    // MARK: - Fetching

    var needsRefresh: Bool {
        guard let lastChecked else { return true }
        return Date.now.timeIntervalSince(lastChecked) > Self.refreshInterval
    }

    /// Fetches the last `historyDays` of alerts. Returns false if the request failed
    /// (the cached alerts stay in place).
    @discardableResult
    func refresh(force: Bool = false, now: Date = .now) async -> Bool {
        guard force || needsRefresh, !isRefreshing else { return true }
        isRefreshing = true
        defer { isRefreshing = false }
        let since = Calendar.current.date(byAdding: .day, value: -Self.historyDays, to: now) ?? now
        do {
            let fetched = try await client.fetchAlerts(since: since)
            alerts = fetched.sorted { $0.created > $1.created }
            lastChecked = now
            lastErrorMessage = nil
            defaults.set(now, forKey: Keys.lastChecked)
            Self.saveCache(alerts, to: cacheURL)
            return true
        } catch {
            lastErrorMessage = "Couldn't reach the Food Standards Agency. Showing the last alerts we downloaded."
            return false
        }
    }

    // MARK: - Cache

    private static func loadCache(from url: URL?) -> [FoodAlert] {
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([FoodAlert].self, from: data)) ?? []
    }

    private static func saveCache(_ alerts: [FoodAlert], to url: URL?) {
        guard let url, let data = try? JSONEncoder().encode(alerts) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

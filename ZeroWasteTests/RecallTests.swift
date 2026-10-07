//
//  RecallTests.swift
//  ZeroWasteTests
//
//  FSA alert decoding (against a real API response), batch date parsing, recall matching
//  and the recall store.
//

import Foundation
import Testing
@testable import ZeroWaste

private final class FixtureBundleToken {}

enum AlertFixtures {
    static func load() throws -> [FoodAlert] {
        let url = try #require(Bundle(for: FixtureBundleToken.self).url(forResource: "fsa-alerts", withExtension: "json"))
        return try JSONDecoder().decode(FSAAlertResponse.self, from: Data(contentsOf: url)).items
    }

    static func alert(_ id: String) throws -> FoodAlert {
        try #require(try load().first { $0.id == id })
    }
}

struct FoodAlertDecodingTests {

    @Test func decodesRealResponseIncludingLooseFields() throws {
        let alerts = try AlertFixtures.load()
        #expect(alerts.count == 7)

        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        #expect(brie.kind == .recall)
        #expect(brie.business == "Traditional Cheese Company")
        #expect(brie.url?.absoluteString == "https://alerts.food.gov.uk/news-alerts/alert/fsa-prin-28-2026")
        #expect(brie.products.map(\.name).contains("Traditional Cheese Company French Brie"))
        #expect(brie.products.first?.batches.first?.useBy == "10 July 2026, 16 July 2026, and 17 July 2026")

        let potNoodle = try AlertFixtures.alert("FSA-AA-43-2026")
        #expect(potNoodle.kind == .allergy)
        #expect(potNoodle.allergens == ["Milk"])
    }

    @Test func flagsNoticesCoveringEveryBatch() throws {
        let falooda = try AlertFixtures.alert("FSA-AA-27-2026")
        #expect(falooda.products.first?.batches.first?.coversAllBatches == true)
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        #expect(brie.products.first?.batches.first?.coversAllBatches == false)
    }

    @Test func cachedModelRoundTrips() throws {
        let alerts = try AlertFixtures.load()
        let data = try JSONEncoder().encode(alerts)
        #expect(try JSONDecoder().decode([FoodAlert].self, from: data) == alerts)
    }
}

struct AlertDateParserTests {

    @Test(arguments: [
        ("16 July 2026", [AlertDateSpec(year: 2026, month: 7, day: 16)]),
        ("10, 16 and 17 July 2026", [16, 10, 17].map { AlertDateSpec(year: 2026, month: 7, day: $0) }),
        ("end of 28 April 2026", [AlertDateSpec(year: 2026, month: 4, day: 28)]),
        ("May 2027", [AlertDateSpec(year: 2027, month: 5, day: nil)]),
        ("31 January 2027 02 May 2027", [AlertDateSpec(year: 2027, month: 1, day: 31), AlertDateSpec(year: 2027, month: 5, day: 2)]),
        ("12/08/2026", [AlertDateSpec(year: 2026, month: 8, day: 12)]),
        ("All best before dates", []),
    ])
    func parsesNoticeDates(text: String, expected: [AlertDateSpec]) {
        #expect(Set(AlertDateParser.dates(in: text)) == Set(expected))
    }
}

@MainActor
struct RecallMatcherTests {

    private let now = TestSupport.date(2026, 7, 12)
    private var matcher: RecallMatcher { RecallMatcher(now: now, calendar: TestSupport.calendar) }

    private func item(_ name: String, expires: Date, brand: String? = nil, barcode: String? = nil) -> FoodItem {
        FoodItem(name: name, category: .dairy, addedAt: TestSupport.date(2026, 7, 5), expiresAt: expires, barcode: barcode, brand: brand)
    }

    @Test func barcodeOnTheNoticeIsALikelyMatch() throws {
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        let match = try #require(matcher.match(alert: brie, product: brie.products[0],
                                               item: item("Cheese", expires: TestSupport.date(2026, 8, 1), barcode: "5099874213772")))
        #expect(match.confidence == .likely)
        #expect(match.reasons.contains(.barcode))
    }

    @Test func headNounWithMatchingDateIsPossible() throws {
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        // The Dunnes Stores brie lists use-by dates of 10, 16 and 17 July.
        let match = try #require(matcher.match(alert: brie, product: brie.products[0],
                                               item: item("Brie", expires: TestSupport.date(2026, 7, 16))))
        #expect(match.confidence == .possible)
        #expect(match.reasons == [.name, .date])
    }

    @Test func nameBrandAndDateIsLikely() throws {
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        let match = try #require(matcher.match(alert: brie, product: brie.products[1],
                                               item: item("French brie", expires: TestSupport.date(2026, 7, 17), brand: "Traditional Cheese Company")))
        #expect(match.confidence == .likely)
        #expect(match.reasons.isSuperset(of: [.name, .brand, .date]))
    }

    @Test func nameOnlyWithADifferentBatchDateIsIgnored() throws {
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        #expect(matcher.match(alert: brie, product: brie.products[1], item: item("Brie", expires: TestSupport.date(2026, 9, 3))) == nil)
    }

    @Test func singleWordMustBeTheProductsHeadNoun() throws {
        let chocolate = try AlertFixtures.alert("FSA-PRIN-47-2026-update-1")
        for product in chocolate.products {
            #expect(matcher.match(alert: chocolate, product: product, item: item("Milk", expires: TestSupport.date(2026, 7, 20))) == nil)
        }
        #expect(RecallMatcher.nameMatches(itemWords: ["ham"], productWords: RecallMatcher.words("Brady Family Crumb Irish Ham")))
        #expect(RecallMatcher.nameMatches(itemWords: RecallMatcher.words("Greek yoghurts"), productWords: RecallMatcher.words("Greek Style Yogurt 500g")))
    }

    @Test func dismissedConsumedAndOldAlertsAreSkipped() throws {
        let alerts = try AlertFixtures.load()
        let brie = item("Brie", expires: TestSupport.date(2026, 7, 16))
        let found = matcher.matches(alerts: alerts, items: [brie])
        let match = try #require(found.first)
        #expect(match.alert.id == "FSA-PRIN-28-2026")
        #expect(matcher.matches(alerts: alerts, items: [brie], dismissed: [match.id]).isEmpty)

        brie.consumedAt = now
        #expect(matcher.matches(alerts: alerts, items: [brie]).isEmpty)

        let muchLater = RecallMatcher(now: TestSupport.date(2027, 3, 1), calendar: TestSupport.calendar)
        #expect(muchLater.matches(alerts: alerts, items: [item("Brie", expires: TestSupport.date(2026, 7, 16))]).isEmpty)
    }
}

@MainActor
struct RecallStoreTests {

    private struct StubClient: FoodAlertsFetching {
        let result: Result<[FoodAlert], Error>
        func fetchAlerts(since: Date) async throws -> [FoodAlert] { try result.get() }
    }

    private func makeStore(_ result: Result<[FoodAlert], Error>, cacheURL: URL? = nil) -> RecallStore {
        RecallStore(client: StubClient(result: result), cacheURL: cacheURL, defaults: AppSettings.ephemeral().userDefaults)
    }

    @Test func refreshCachesAlertsAndThrottles() async throws {
        let cache = FileManager.default.temporaryDirectory.appendingPathComponent("alerts-\(UUID().uuidString).json")
        let store = makeStore(.success(try AlertFixtures.load()), cacheURL: cache)
        #expect(store.needsRefresh)
        #expect(await store.refresh())
        #expect(store.alerts.count == 7)
        #expect(!store.needsRefresh)

        let reloaded = RecallStore(client: StubClient(result: .success([])), cacheURL: cache, defaults: AppSettings.ephemeral().userDefaults)
        #expect(reloaded.alerts.count == 7)
    }

    @Test func failedRefreshKeepsCachedAlerts() async throws {
        let store = makeStore(.failure(URLError(.notConnectedToInternet)))
        #expect(await store.refresh() == false)
        #expect(store.lastErrorMessage != nil)
        #expect(store.alerts.isEmpty)
    }

    @Test func dismissAndNotifiedArePersisted() async throws {
        let settings = AppSettings.ephemeral()
        let store = RecallStore(client: StubClient(result: .success(try AlertFixtures.load())), cacheURL: nil, defaults: settings.userDefaults)
        await store.refresh()
        let brie = FoodItem(name: "Brie", expiresAt: TestSupport.date(2026, 7, 16))
        let match = try #require(store.matches(for: [brie], now: TestSupport.date(2026, 7, 12)).first)

        store.markNotified([match])
        store.dismiss(match)
        let again = RecallStore(client: StubClient(result: .success([])), cacheURL: nil, defaults: settings.userDefaults)
        #expect(again.dismissedMatchIDs.contains(match.id))
        #expect(again.notifiedMatchIDs.contains(match.id))
    }
}

struct AllergenTests {

    @Test func profileCoversFSAAllergenLabels() {
        #expect(Allergen.gluten.matches(alertLabel: "Wheat"))
        #expect(Allergen.gluten.matches(alertLabel: "Barley"))
        #expect(Allergen.nuts.matches(alertLabel: "Hazelnut"))
        #expect(!Allergen.nuts.matches(alertLabel: "Peanuts"))
        #expect(Allergen.milk.matches(alertLabel: "Milk"))
        #expect(!Allergen.milk.matches(alertLabel: "Egg"))
    }

    @Test func onlyAllergyAlertsConcernAllergies() throws {
        let potNoodle = try AlertFixtures.alert("FSA-AA-43-2026")
        #expect(potNoodle.concerns([.milk, .egg]) == [.milk])
        let brie = try AlertFixtures.alert("FSA-PRIN-28-2026")
        #expect(brie.concerns([.milk]).isEmpty)
    }
}

@MainActor
struct FoodAlertsViewModelTests {

    @Test func forYouShowsFridgeMatchesAndAllergyAlerts() async {
        let dependencies = AppDependencies.preview(alerts: PreviewFoodAlerts())
        await dependencies.recalls.refresh(force: true)
        let viewModel = FoodAlertsViewModel(recalls: dependencies.recalls, inventory: dependencies.inventory, settings: dependencies.settings)

        // The sample fridge has semi-skimmed milk, so the milk recall is "for you".
        #expect(viewModel.rows.map(\.alert.id) == ["FSA-PRIN-PREVIEW"])
        #expect(viewModel.rows.first?.highlight == "In your fridge: Semi-skimmed milk")

        dependencies.settings.allergenProfile = [.milk]
        #expect(viewModel.rows.map(\.alert.id) == ["FSA-PRIN-PREVIEW", "FSA-AA-PREVIEW"])

        viewModel.filter = .allergy
        #expect(viewModel.rows.map(\.alert.id) == ["FSA-AA-PREVIEW"])
    }
}

struct FoodAlertBatchTests {
    @Test func summaryReadsNaturally() {
        #expect(FoodAlert.Batch(batchCode: "L123", bestBefore: "May 2027").summary == "Batch L123 · Best before May 2027")
        #expect(FoodAlert.Batch(batchCode: "All batches", useBy: "All use by dates").summary == "All batches · All use by dates")
    }
}

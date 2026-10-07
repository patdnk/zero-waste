//
//  ScanReviewViewModelTests.swift
//  ZeroBiteTests
//

import Foundation
import Testing
@testable import ZeroBite

@MainActor
struct ScanReviewViewModelTests {

    private let now = TestSupport.date(2026, 9, 7)

    private func result() -> ScanResult {
        LabelScanner.analyse(lines: ["SEMI SKIMMED MILK", "USE BY 12 SEP 2026", "PACKED 01/09/2026"], barcode: "5000000000000", now: now)
    }

    @Test func barcodeLookupFillsNameAndCategoryWithoutOverwritingUserEdits() async {
        let coordinator = ScanCoordinator(onFinished: {})
        let lookup = StubProductLookup(info: ProductInfo(barcode: "5000000000000", name: "Organic Semi Skimmed Milk", brand: "Yeo", category: .dairy))

        let viewModel = ScanReviewViewModel(result: result(), productLookup: lookup, coordinator: coordinator, now: { self.now })
        #expect(viewModel.name == "Semi Skimmed Milk")
        await viewModel.loadProduct()
        #expect(viewModel.name == "Organic Semi Skimmed Milk")
        #expect(viewModel.category == .dairy)

        let edited = ScanReviewViewModel(result: result(), productLookup: lookup, coordinator: coordinator, now: { self.now })
        edited.name = "My milk"
        await edited.loadProduct()
        #expect(edited.name == "My milk")
    }

    @Test func draftUsesSelectedDateOrFallsBackToShelfLife() {
        let coordinator = ScanCoordinator(onFinished: {})
        let viewModel = ScanReviewViewModel(result: result(), productLookup: StubProductLookup(info: nil), coordinator: coordinator, now: { self.now })

        // Best candidate (the "use by" line) is pre-selected.
        let draft = viewModel.makeDraft()
        let day = TestSupport.calendar.dateComponents([.year, .month, .day], from: draft.expiresAt)
        #expect([day.year, day.month, day.day] == [2026, 9, 12])
        #expect(draft.barcode == "5000000000000")

        viewModel.clearSelection()
        viewModel.category = .dairy
        let fallback = viewModel.makeDraft()
        let days = TestSupport.calendar.dateComponents([.day], from: TestSupport.calendar.startOfDay(for: now), to: TestSupport.calendar.startOfDay(for: fallback.expiresAt)).day
        #expect(days == FoodCategory.dairy.defaultShelfLifeDays)
    }

    @Test func continuePushesFormRoute() {
        let coordinator = ScanCoordinator(onFinished: {})
        let viewModel = ScanReviewViewModel(result: result(), productLookup: StubProductLookup(info: nil), coordinator: coordinator, now: { self.now })
        viewModel.continueToForm()
        #expect(coordinator.navigationPath.count == 1)
    }
}

@MainActor
struct AppFlowControllerTests {

    @Test func firstLaunchGoesToWelcomeThenRemembersCompletion() {
        let settings = AppSettings.ephemeral()
        let flow = AppFlowController(settings: settings)
        #expect(flow.phase == .launch)
        flow.transitionFromLaunch()
        #expect(flow.phase == .welcome)
        flow.transitionToMain()
        #expect(flow.phase == .main)
        #expect(settings.hasCompletedWelcome)

        let relaunch = AppFlowController(settings: settings)
        relaunch.transitionFromLaunch()
        #expect(relaunch.phase == .main)
    }
}

//
//  WelcomeViewModelTests.swift
//  ZeroBiteTests
//

import Foundation
import Testing
@testable import ZeroBite

@MainActor
struct WelcomeViewModelTests {

    @Test func firstRunPagesThroughToTheRemindersStep() async {
        var completed = false
        let viewModel = WelcomeViewModel(settings: .ephemeral(), notifications: ExpiryNotificationService(), onComplete: { completed = true })

        #expect(viewModel.pages.last == .reminders)
        for _ in 0..<(viewModel.pages.count - 1) {
            await viewModel.primaryAction()
        }
        #expect(viewModel.currentPage == .reminders)
        #expect(viewModel.isLastPage)
        #expect(!completed)
    }

    @Test func skipJumpsToRemindersOnFirstRun() {
        let viewModel = WelcomeViewModel(settings: .ephemeral(), notifications: ExpiryNotificationService(), onComplete: {})
        viewModel.skipIntro()
        #expect(viewModel.currentPage == .reminders)
    }

    @Test func replayHasNoPermissionStepAndFinishesOnLastPage() async {
        var completed = false
        let viewModel = WelcomeViewModel(mode: .replay, settings: .ephemeral(), notifications: ExpiryNotificationService(), onComplete: { completed = true })

        #expect(!viewModel.pages.contains(.reminders))
        for _ in 0..<viewModel.pages.count {
            await viewModel.primaryAction()
        }
        #expect(completed)
    }
}

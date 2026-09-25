//
//  ScanCoordinator.swift
//  ZeroWaste
//
//  Drives the add-item flow presented as a sheet: choose source → (live scan) → review →
//  form → done. Created fresh for each presentation.
//

import Foundation
import Observation
import SwiftUI

enum ScanRoute: Hashable {
    case live
    case review(ScanResult)
    case form(ItemDraft)
}

@MainActor
@Observable
final class ScanCoordinator {

    var navigationPath = NavigationPath()
    private let onFinished: () -> Void

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    func showLiveScanner() {
        navigationPath.append(ScanRoute.live)
    }

    func showReview(_ result: ScanResult) {
        navigationPath.append(ScanRoute.review(result))
    }

    func showForm(_ draft: ItemDraft) {
        navigationPath.append(ScanRoute.form(draft))
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    /// Saved or cancelled: close the sheet.
    func finish() {
        onFinished()
    }
}

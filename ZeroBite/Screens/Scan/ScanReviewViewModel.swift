//
//  ScanReviewViewModel.swift
//  ZeroBite
//
//  Lets the user confirm what was read: product name (barcode lookup when possible) and
//  which of the detected dates is the expiry.
//

import Foundation
import Observation

@MainActor
@Observable
final class ScanReviewViewModel {

    let result: ScanResult

    var name: String
    var category: FoodCategory = .other
    var selectedCandidateID: DateCandidate.ID?
    private(set) var product: ProductInfo?
    private(set) var isLookingUp = false

    private let productLookup: any ProductLookup
    private let coordinator: ScanCoordinator
    private let now: () -> Date

    init(result: ScanResult, productLookup: any ProductLookup, coordinator: ScanCoordinator, now: @escaping () -> Date = { .now }) {
        self.result = result
        self.productLookup = productLookup
        self.coordinator = coordinator
        self.now = now
        name = result.suggestedName ?? ""
        selectedCandidateID = result.bestCandidate?.id
    }

    var candidates: [DateCandidate] { result.candidates }
    var lines: [String] { result.lines }
    var barcode: String? { result.barcode }

    var selectedCandidate: DateCandidate? {
        candidates.first { $0.id == selectedCandidateID }
    }

    var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    func loadProduct() async {
        guard let barcode, product == nil, !isLookingUp else { return }
        isLookingUp = true
        defer { isLookingUp = false }
        guard let info = try? await productLookup.lookup(barcode: barcode) else { return }
        product = info
        // A catalogue name beats an OCR guess; keep anything the user has already typed.
        if name.isEmpty || name == result.suggestedName {
            name = info.name
        }
        if let category = info.category {
            self.category = category
        }
    }

    func select(_ candidate: DateCandidate) {
        selectedCandidateID = candidate.id
    }

    func clearSelection() {
        selectedCandidateID = nil
    }

    func makeDraft() -> ItemDraft {
        var draft = ItemDraft(now: now())
        draft.name = name.trimmingCharacters(in: .whitespaces)
        draft.category = category
        draft.barcode = barcode
        draft.brand = product?.brand
        if let date = selectedCandidate?.date {
            draft.expiresAt = date
        } else {
            draft.expiresAt = Calendar.current.date(byAdding: .day, value: category.defaultShelfLifeDays, to: now()) ?? now()
        }
        return draft
    }

    func continueToForm() {
        guard canContinue else { return }
        coordinator.showForm(makeDraft())
    }
}

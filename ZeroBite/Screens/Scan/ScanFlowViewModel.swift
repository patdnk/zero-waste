//
//  ScanFlowViewModel.swift
//  ZeroBite
//
//  State machine for the add-food sheet: idle → processing → (review | failed).
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ScanFlowViewModel {

    enum Phase: Equatable {
        case idle
        case processing
        case failed(String)
    }

    private(set) var phase: Phase = .idle

    let coordinator: ScanCoordinator
    let supportsLiveScanning: Bool

    private let scan: @Sendable (Data) async throws -> ScanResult

    init(
        coordinator: ScanCoordinator,
        supportsLiveScanning: Bool,
        scan: @escaping @Sendable (Data) async throws -> ScanResult = { try await LabelScanner.scan(imageData: $0) }
    ) {
        self.coordinator = coordinator
        self.supportsLiveScanning = supportsLiveScanning
        self.scan = scan
    }

    var isProcessing: Bool { phase == .processing }

    var errorMessage: String? {
        if case .failed(let message) = phase { return message }
        return nil
    }

    // MARK: - Actions

    func startLiveScan() {
        coordinator.showLiveScanner()
    }

    func enterManually() {
        coordinator.showForm(ItemDraft())
    }

    func liveScanFinished(_ result: ScanResult) {
        coordinator.showReview(result)
    }

    /// Runs OCR + barcode detection on a chosen photo and moves to the review screen.
    func process(imageData: Data) async {
        guard phase != .processing else { return }
        phase = .processing
        guard let normalized = UIImage(data: imageData)?.normalizedJPEGData() else {
            phase = .failed("That file doesn't look like a photo.")
            return
        }
        do {
            let result = try await scan(normalized)
            phase = .idle
            if result.isEmpty {
                phase = .failed("No text or barcode was found. Try a sharper, closer photo of the label.")
            } else {
                coordinator.showReview(result)
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func photoLoadFailed() {
        phase = .failed("Couldn't load that photo.")
    }

    func dismissError() {
        phase = .idle
    }

    func cancel() {
        coordinator.finish()
    }
}

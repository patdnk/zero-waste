//
//  ScanFactory.swift
//  ZeroWaste
//
//  Factory for the add-food flow (scan → review → form).
//

import SwiftUI

@MainActor
enum ScanFactory {

    static func makeFlow(dependencies: AppDependencies, onFinished: @escaping () -> Void) -> some View {
        ViewModelHost(ScanFlowViewModel(
            coordinator: ScanCoordinator(onFinished: onFinished),
            supportsLiveScanning: LiveScannerView.isSupported
        )) { viewModel in
            ScanFlowView(viewModel: viewModel, dependencies: dependencies)
        }
    }

    static func makeReview(result: ScanResult, coordinator: ScanCoordinator, dependencies: AppDependencies) -> some View {
        ViewModelHost(ScanReviewViewModel(
            result: result,
            productLookup: dependencies.productLookup,
            coordinator: coordinator
        )) { viewModel in
            ScanReviewView(viewModel: viewModel)
        }
    }
}

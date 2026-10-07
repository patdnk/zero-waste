//
//  ScanFlowView.swift
//  ZeroBite
//

import PhotosUI
import SwiftUI

struct ScanFlowView: View {
    @Bindable var viewModel: ScanFlowViewModel
    let dependencies: AppDependencies

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        @Bindable var coordinator = viewModel.coordinator
        NavigationStack(path: $coordinator.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    DetailTitle(overline: "Scan or type", title: "Add food")

                    VStack(spacing: Spacing.sm) {
                        if viewModel.supportsLiveScanning {
                            Button { viewModel.startLiveScan() } label: {
                                ScanOptionRow(symbol: "barcode.viewfinder", title: "Scan with the camera", subtitle: "Reads dates and barcodes live", isPrimary: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("scan.live")
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            ScanOptionRow(symbol: "photo.on.rectangle", title: "Choose a photo of the label", subtitle: "Pick a picture of the packaging")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("scan.photo")
                        Button { viewModel.enterManually() } label: {
                            ScanOptionRow(symbol: "square.and.pencil", title: "Type it in", subtitle: "No label to read")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("scan.manual")
                    }

                    Text("Point at the best-before or use-by date. A barcode helps fill in the product name.")
                        .font(.app(.caption))
                        .foregroundStyle(Constants.TextSecondary)
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.bottom, Spacing.xl)
            }
            .pageBackground()
            .topBar(.close { viewModel.cancel() })
            .navigationDestination(for: ScanRoute.self) { route in
                destination(for: route, coordinator: coordinator)
            }
        }
        .loadingOverlay(viewModel.isProcessing, message: "Reading the label…")
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            pickerItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.process(imageData: data)
                } else {
                    viewModel.photoLoadFailed()
                }
            }
        }
        .alert(
            "Couldn't read that",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func destination(for route: ScanRoute, coordinator: ScanCoordinator) -> some View {
        switch route {
        case .live:
            LiveScannerView(onFinish: { viewModel.liveScanFinished($0) })
        case .review(let result):
            ScanFactory.makeReview(result: result, coordinator: coordinator, dependencies: dependencies)
        case .form(let draft):
            InventoryFactory.makeForm(
                mode: .add,
                draft: draft,
                dependencies: dependencies,
                onCancel: { coordinator.finish() },
                onSaved: { _ in coordinator.finish() }
            )
        }
    }
}

private struct ScanOptionRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    var isPrimary = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isPrimary ? .white : Constants.BrandOrange)
                .frame(width: 44, height: 44)
                .background(isPrimary ? Constants.BrandOrange : Constants.BrandOrange.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: Radius.control))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.app(.subheadline, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                Text(subtitle).font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Constants.TextMuted)
        }
        .cardStyle()
        .contentShape(Rectangle())
    }
}

#Preview {
    ScanFactory.makeFlow(dependencies: .preview(), onFinished: {})
}

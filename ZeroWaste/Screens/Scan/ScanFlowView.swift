//
//  ScanFlowView.swift
//  ZeroWaste
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
            List {
                Section {
                    if viewModel.supportsLiveScanning {
                        Button { viewModel.startLiveScan() } label: {
                            ScanOptionRow(symbol: "camera.viewfinder", title: "Scan with the camera", subtitle: "Reads dates and barcodes live")
                        }
                        .accessibilityIdentifier("scan.live")
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        ScanOptionRow(symbol: "photo.on.rectangle", title: "Choose a photo of the label", subtitle: "Pick a picture of the packaging")
                    }
                    .accessibilityIdentifier("scan.photo")
                    Button { viewModel.enterManually() } label: {
                        ScanOptionRow(symbol: "square.and.pencil", title: "Type it in", subtitle: "No label to read")
                    }
                    .accessibilityIdentifier("scan.manual")
                } footer: {
                    Text("Point at the best-before or use-by date. A barcode helps fill in the product name.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Constants.BackgroundSecondary)
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.cancel() }
                }
            }
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

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.app(.title2))
                .foregroundStyle(Constants.Brand)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.app(.headline, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                Text(subtitle).font(.app(.subheadline)).foregroundStyle(Constants.TextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScanFactory.makeFlow(dependencies: .preview(), onFinished: {})
}

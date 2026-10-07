//
//  LiveScannerView.swift
//  ZeroWaste
//
//  Live camera scanning with VisionKit's DataScannerViewController. Accumulates every text
//  line and barcode it sees, parses expiry dates on the fly, and hands back a ScanResult.
//  Not available on the simulator (use the photo option there).
//

import SwiftUI
import Vision
import VisionKit

struct LiveScannerView: View {
    let onFinish: (ScanResult) -> Void

    @State private var seenLines: [String] = []
    @State private var seenSet = Set<String>()
    @State private var barcode: String?
    @State private var unavailableMessage: String?

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    private var result: ScanResult {
        LabelScanner.analyse(lines: seenLines, barcode: barcode)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DataScannerRepresentable(
                onItems: handle,
                onUnavailable: { unavailableMessage = $0 }
            )
            .ignoresSafeArea()

            summaryCard
        }
        .navigationTitle("Scan label")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Camera unavailable",
            isPresented: Binding(
                get: { unavailableMessage != nil },
                set: { if !$0 { unavailableMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(unavailableMessage ?? "")
        }
    }

    private var summaryCard: some View {
        let current = result
        return VStack(alignment: .leading, spacing: 10) {
            if let best = current.bestCandidate {
                Label(best.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                    .font(.app(.headline, weight: .semibold))
            } else {
                Label("Looking for a best-before date…", systemImage: "calendar")
                    .foregroundStyle(Constants.TextSecondary)
            }
            if let barcode {
                Label(barcode, systemImage: "barcode")
            }
            if let name = current.suggestedName {
                Label(name, systemImage: "tag")
            }
            Text("\(seenLines.count) lines read")
                .font(.app(.caption))
                .foregroundStyle(Constants.TextSecondary)
            PrimaryButton("Use what I've found", isEnabled: !current.isEmpty) {
                onFinish(current)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.card))
        .padding(16)
    }

    private func handle(_ items: [RecognizedItem]) {
        for item in items {
            switch item {
            case .text(let text):
                for rawLine in text.transcript.components(separatedBy: .newlines) {
                    let line = rawLine.trimmingCharacters(in: .whitespaces)
                    guard line.count >= 2, seenSet.insert(line).inserted else { continue }
                    seenLines.append(line)
                }
            case .barcode(let code):
                if barcode == nil, let value = code.payloadStringValue {
                    barcode = value
                }
            default:
                break
            }
        }
    }
}

// MARK: - UIKit bridge

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onItems: ([RecognizedItem]) -> Void
    let onUnavailable: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .text(),
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .qr]),
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
        guard !controller.isScanning else { return }
        do {
            try controller.startScanning()
        } catch {
            onUnavailable(error.localizedDescription)
        }
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerRepresentable

        init(parent: DataScannerRepresentable) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            parent.onItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            parent.onItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            parent.onUnavailable(error.localizedDescription)
        }
    }
}

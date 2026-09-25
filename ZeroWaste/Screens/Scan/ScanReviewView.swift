//
//  ScanReviewView.swift
//  ZeroWaste
//

import SwiftUI

struct ScanReviewView: View {
    @Bindable var viewModel: ScanReviewViewModel

    var body: some View {
        Form {
            Section("Product") {
                TextField("Name", text: $viewModel.name)
                    .accessibilityIdentifier("review.name")
                Picker("Category", selection: $viewModel.category) {
                    ForEach(FoodCategory.allCases) { category in
                        Label(category.label, systemImage: category.symbol).tag(category)
                    }
                }
                if viewModel.isLookingUp {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Looking up barcode…").foregroundStyle(Constants.TextSecondary)
                    }
                }
                if let product = viewModel.product {
                    LabeledContent("Found", value: [product.brand, product.name].compactMap { $0 }.joined(separator: " · "))
                }
                if let barcode = viewModel.barcode {
                    LabeledContent("Barcode", value: barcode)
                }
            }

            Section {
                if viewModel.candidates.isEmpty {
                    Text("No date was found on the label. You can set one on the next screen.")
                        .foregroundStyle(Constants.TextSecondary)
                } else {
                    ForEach(viewModel.candidates) { candidate in
                        Button { viewModel.select(candidate) } label: {
                            candidateRow(candidate, isSelected: viewModel.selectedCandidateID == candidate.id)
                        }
                        .buttonStyle(.plain)
                    }
                    Button("None of these") { viewModel.clearSelection() }
                        .foregroundStyle(Constants.TextSecondary)
                }
            } header: {
                Text("Expiry date")
            } footer: {
                if !viewModel.candidates.isEmpty {
                    Text("Pick the best-before or use-by date. Most likely first.")
                }
            }

            if !viewModel.lines.isEmpty {
                Section("Text read from the label") {
                    DisclosureGroup("\(viewModel.lines.count) lines") {
                        ForEach(viewModel.lines.indices, id: \.self) { index in
                            Text(viewModel.lines[index])
                                .font(.app(.footnote))
                                .foregroundStyle(Constants.TextSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Check the details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") { viewModel.continueToForm() }
                    .disabled(!viewModel.canContinue)
                    .accessibilityIdentifier("review.continue")
            }
        }
        .task { await viewModel.loadProduct() }
    }

    private func candidateRow(_ candidate: DateCandidate, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.date.formatted(date: .long, time: .omitted))
                    .font(.app(.headline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("“\(candidate.sourceLine)”")
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            ConfidenceDots(confidence: candidate.confidence)
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Constants.Brand : Constants.TextSecondary)
        }
        .contentShape(Rectangle())
    }
}

private struct ConfidenceDots: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Double(index) / 3 < confidence ? Constants.BrandOrange : Constants.TextSecondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Confidence \(Int(confidence * 100)) percent")
    }
}

#Preview {
    let now = Date.now
    let result = LabelScanner.analyse(
        lines: ["TESCO", "SEMI SKIMMED MILK", "USE BY 12 SEP 2026", "2 PINTS 1.136L", "PACKED 01/09/2026"],
        barcode: "5000119000000",
        now: now
    )
    NavigationStack {
        ScanFactory.makeReview(result: result, coordinator: ScanCoordinator(onFinished: {}), dependencies: .preview())
    }
}

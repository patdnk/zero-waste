//
//  ScanReviewView.swift
//  ZeroWaste
//

import SwiftUI

struct ScanReviewView: View {
    @Bindable var viewModel: ScanReviewViewModel

    @State private var showsLines = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    DetailTitle(overline: "Scanned label", title: "Check the details")

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        LabeledInput(label: "Name", placeholder: "Product name", text: $viewModel.name, accessibilityID: "review.name")
                        if viewModel.isLookingUp {
                            HStack(spacing: Spacing.sm) {
                                ProgressView().controlSize(.small)
                                Text("Looking up barcode…")
                            }
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Overline("Category")
                        ChipFilter(options: FoodCategory.allCases, selection: $viewModel.category) { $0.label }
                    }

                    if viewModel.product != nil || viewModel.barcode != nil {
                        CardSection("Product") {
                            if let product = viewModel.product {
                                InfoRow("Found", symbol: "checkmark.seal", value: [product.brand, product.name].compactMap { $0 }.joined(separator: " · "))
                            }
                            if let barcode = viewModel.barcode {
                                InfoRow("Barcode", symbol: "barcode", value: barcode)
                            }
                        }
                    }

                    expiry

                    if !viewModel.lines.isEmpty {
                        CardSection("Text read from the label") {
                            ActionRow(title: showsLines ? "Hide \(viewModel.lines.count) lines" : "Show \(viewModel.lines.count) lines",
                                      symbol: showsLines ? "chevron.up" : "chevron.down",
                                      tint: Constants.TextSecondary) {
                                withAnimation(.snappy) { showsLines.toggle() }
                            }
                            if showsLines {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(viewModel.lines.indices, id: \.self) { index in
                                        Text(viewModel.lines[index])
                                            .font(.app(.footnote).monospaced())
                                            .foregroundStyle(Constants.TextSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton("Continue", isEnabled: viewModel.canContinue) { viewModel.continueToForm() }
                .accessibilityIdentifier("review.continue")
                .padding(.horizontal, Spacing.gutter)
                .padding(.vertical, Spacing.sm)
                .background(Constants.BackgroundPrimary)
        }
        .pageBackground()
        .topBar(.back)
        .task { await viewModel.loadProduct() }
    }

    @ViewBuilder
    private var expiry: some View {
        if viewModel.candidates.isEmpty {
            CardSection("Expiry date") {
                Text("No date was found on the label. You can set one on the next screen.")
                    .font(.app(.subheadline))
                    .foregroundStyle(Constants.TextSecondary)
            }
        } else {
            CardSection("Expiry date", footer: "Pick the best-before or use-by date. Most likely first.") {
                ForEach(viewModel.candidates) { candidate in
                    Button { viewModel.select(candidate) } label: {
                        candidateRow(candidate, isSelected: viewModel.selectedCandidateID == candidate.id)
                    }
                    .buttonStyle(.plain)
                }
                ActionRow(title: "None of these", symbol: "xmark", tint: Constants.TextSecondary) {
                    viewModel.clearSelection()
                }
            }
        }
    }

    private func candidateRow(_ candidate: DateCandidate, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.date.formatted(date: .long, time: .omitted))
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("“\(candidate.sourceLine)”")
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            ConfidenceDots(confidence: candidate.confidence)
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundStyle(isSelected ? Constants.BrandOrange : Constants.TextMuted)
        }
        .contentShape(Rectangle())
    }
}

private struct ConfidenceDots: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(Double(index) / 3 < confidence ? Constants.BrandOrange : Constants.ChipFill)
                    .frame(width: 4, height: 10)
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

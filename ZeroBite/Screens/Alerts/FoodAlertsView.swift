//
//  FoodAlertsView.swift
//  ZeroBite
//

import SwiftUI

@MainActor
enum FoodAlertsFactory {
    static func makeList(dependencies: AppDependencies) -> some View {
        ViewModelHost(FoodAlertsViewModel(
            recalls: dependencies.recalls,
            inventory: dependencies.inventory,
            settings: dependencies.settings
        )) { viewModel in
            FoodAlertsView(viewModel: viewModel)
        }
    }
}

struct FoodAlertsView: View {
    @Bindable var viewModel: FoodAlertsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                DetailTitle(overline: viewModel.lastCheckedText, title: "Food alerts")

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.app(.caption))
                        .foregroundStyle(Constants.StatusExpired)
                }

                ChipFilter(options: FoodAlertsViewModel.Filter.allCases, selection: $viewModel.filter) { $0.title }

                let rows = viewModel.rows
                if rows.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.emptyTitle)
                            .font(.app(.headline, weight: .semibold))
                            .foregroundStyle(Constants.TextPrimary)
                        Text(viewModel.emptyMessage)
                            .font(.app(.subheadline))
                            .foregroundStyle(Constants.TextSecondary)
                    }
                    .cardStyle(padding: Spacing.lg)
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(rows) { row in
                            NavigationLink(value: row.alert) {
                                FoodAlertRow(alert: row.alert, highlight: row.highlight)
                                    .cardStyle(accent: row.highlight == nil ? nil : row.alert.kind.tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Alerts from the Food Standards Agency. Contains public sector information licensed under the Open Government Licence v3.0.")
                    .font(.app(.caption2))
                    .foregroundStyle(Constants.TextMuted)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.xl)
        }
        .refreshable { await viewModel.refresh() }
        .pageBackground()
        .topBar(.back) {
            if viewModel.isRefreshing {
                ProgressView().frame(width: 38, height: 38)
            }
        }
        .navigationDestination(for: FoodAlert.self) { alert in
            FoodAlertDetailView(alert: alert)
        }
    }
}

struct FoodAlertDetailView: View {
    let alert: FoodAlert

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                DetailTitle(
                    overline: "\(alert.kind.label) · \(alert.created.formatted(date: .long, time: .omitted))",
                    title: alert.displayTitle,
                    overlineTint: alert.kind.tint
                )

                if !alert.businesses.isEmpty {
                    CardSection {
                        InfoRow("From", symbol: "building.2", value: alert.businesses.joined(separator: ", "))
                    }
                }

                if !alert.allergens.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Overline("Allergens")
                        FlowTags(tags: alert.allergens, tint: alert.kind.tint)
                    }
                }

                if let risk = alert.risk {
                    CardSection("Why") {
                        Text(risk)
                            .font(.app(.subheadline))
                            .foregroundStyle(Constants.TextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Overline(alert.products.count == 1 ? "Product" : "Products")
                    ForEach(Array(alert.products.enumerated()), id: \.offset) { _, product in
                        AlertProductDetails(product: product)
                    }
                }

                if let advice = alert.consumerAdvice {
                    CardSection("What to do") {
                        Text(advice)
                            .font(.app(.subheadline))
                            .foregroundStyle(Constants.TextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let url = alert.url {
                    Link(destination: url) {
                        Label("Read the full notice", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(.app(.ink))
                }

                Text("Source: Food Standards Agency (\(alert.id)). Open Government Licence v3.0.")
                    .font(.app(.caption2))
                    .foregroundStyle(Constants.TextMuted)
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.xl)
        }
        .pageBackground()
        .topBar(.back)
    }
}

/// Wrapping row of tags.
struct FlowTags: View {
    let tags: [String]
    var tint: Color?

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { Tag(text: $0, tint: tint) }
        }
    }
}

/// Minimal left-to-right wrapping layout.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        FoodAlertsFactory.makeList(dependencies: dependencies)
    }
    .task { await dependencies.recalls.refresh(force: true) }
}

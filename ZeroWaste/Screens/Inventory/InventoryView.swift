//
//  InventoryView.swift
//  ZeroWaste
//

import SwiftUI

struct InventoryView: View {
    @Bindable var viewModel: InventoryViewModel
    @Bindable var coordinator: InventoryCoordinator
    let dependencies: AppDependencies

    private let columns = [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)]

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ScreenHeader(overline: viewModel.headerDate, title: "Fridge", count: viewModel.isEmpty ? nil : viewModel.items.count) {
                            addMenu
                        }

                        if viewModel.isEmpty {
                            EmptyStateView(
                                title: "Your fridge is empty",
                                message: "Scan a label or add something by hand. We'll remind you before it goes off and suggest what to cook.",
                                systemImage: "refrigerator",
                                primaryTitle: "Scan a label",
                                primaryAction: { viewModel.showScan() },
                                primarySymbol: "barcode.viewfinder",
                                secondaryTitle: "Try it with sample food",
                                secondaryAction: { viewModel.loadSampleData() }
                            )
                            .padding(.top, 40)
                        } else {
                            content
                        }
                    }
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                if !viewModel.isEmpty {
                    BottomSearchBar(
                        text: $viewModel.searchText,
                        prompt: "Search your food",
                        accessoryAction: ("barcode.viewfinder", "Scan label or barcode", { viewModel.showScan() }),
                        accessibilityID: "inventory.search"
                    )
                }
            }
            .pageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: InventoryRoute.self) { route in
                destination(for: route)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var content: some View {
        let recallMatches = viewModel.recallMatches
        if !recallMatches.isEmpty {
            RecallBanner(matches: recallMatches) { viewModel.showRecalledItem($0) }
        }

        if viewModel.showsNotificationTip {
            notificationTip
        }

        if let item = viewModel.useFirstItem {
            UseFirstCard(
                item: item,
                othersNeedingAttention: viewModel.othersNeedingAttention,
                soonThresholdDays: viewModel.soonThresholdDays,
                onOpen: { viewModel.showDetails(item) },
                onUsed: { withAnimation { viewModel.markUsed(item) } },
                onFreeze: viewModel.canFreeze(item) ? { withAnimation { viewModel.freeze(item) } } : nil,
                onRecipes: { viewModel.showDetails(item) }
            )
        }

        ChipFilter(options: InventoryViewModel.StorageFilter.allCases, selection: $viewModel.storageFilter) { $0.title }

        let sections = viewModel.gridSections
        if sections.isEmpty {
            Text(viewModel.searchText.isEmpty ? "Nothing stored here." : "Nothing matches “\(viewModel.searchText)”.")
                .font(.app(.subheadline))
                .foregroundStyle(Constants.TextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }

        ForEach(sections) { section in
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeading(
                    title: section.status.sectionTitle,
                    detail: section.items.count == 1 ? "1 item" : "\(section.items.count) items",
                    tint: section.status == .fresh ? Constants.TextPrimary : section.status.tint
                )
                let flagged = viewModel.recalledItemIDs
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(section.items) { item in
                        NavigationLink(value: InventoryRoute.itemDetail(item.id)) {
                            FoodItemCard(item: item, soonThresholdDays: viewModel.soonThresholdDays, isRecallFlagged: flagged.contains(item.id))
                        }
                        .buttonStyle(.plain)
                        .contextMenu { itemMenu(for: item) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemMenu(for item: FoodItem) -> some View {
        Button { withAnimation { viewModel.markUsed(item) } } label: {
            Label("Used it", systemImage: "checkmark")
        }
        if viewModel.canFreeze(item) {
            Button { withAnimation { viewModel.freeze(item) } } label: {
                Label("Move to freezer", systemImage: "snowflake")
            }
        }
        Button { coordinator.showEditItem(id: item.id) } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) { withAnimation { viewModel.delete(item) } } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var addMenu: some View {
        Menu {
            Button { viewModel.showScan() } label: {
                Label("Scan label or barcode", systemImage: "barcode.viewfinder")
            }
            Button { viewModel.showAddItem() } label: {
                Label("Add manually", systemImage: "square.and.pencil")
            }
        } label: {
            HeaderIconButtonLabel(symbol: "plus")
        }
        .accessibilityLabel("Add food")
        .accessibilityIdentifier("inventory.addButton")
    }

    private var notificationTip: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            IconTile(symbol: "bell.badge", tint: Constants.BrandOrange)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Get reminded before food expires")
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundStyle(Constants.TextPrimary)
                Text("We'll nudge you a few days before the date.")
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
                HStack(spacing: 6) {
                    Button("Turn on") { Task { await viewModel.enableNotifications() } }
                        .buttonStyle(.app(.ink, compact: true))
                    Button("Not now") { viewModel.dismissNotificationTip() }
                        .buttonStyle(.app(.tonal, compact: true))
                }
                .padding(.top, 2)
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func destination(for route: InventoryRoute) -> some View {
        switch route {
        case .itemDetail(let id):
            InventoryFactory.makeDetail(
                itemID: id,
                dependencies: dependencies,
                onEdit: { coordinator.showEditItem(id: $0) },
                onShowRecipe: { coordinator.showRecipe(id: $0) },
                onDeleted: { coordinator.pop() }
            )
        case .recipe(let id):
            RecipesFactory.makeDetail(
                recipeID: id,
                dependencies: dependencies,
                onShowItem: { coordinator.showItem(id: $0) },
                onCooked: { coordinator.showCooked(recipeID: $0) }
            )
        }
    }
}

#Preview("Sample fridge") {
    let dependencies = AppDependencies.preview()
    let coordinator = AppCoordinator(dependencies: dependencies)
    InventoryFactory.makeList(coordinator: coordinator.inventoryCoordinator, dependencies: dependencies)
}

#Preview("Empty") {
    let dependencies = AppDependencies.preview(withSampleData: false)
    let coordinator = AppCoordinator(dependencies: dependencies)
    InventoryFactory.makeList(coordinator: coordinator.inventoryCoordinator, dependencies: dependencies)
}

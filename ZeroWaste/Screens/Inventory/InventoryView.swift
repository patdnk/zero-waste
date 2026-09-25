//
//  InventoryView.swift
//  ZeroWaste
//

import SwiftUI

struct InventoryView: View {
    @Bindable var viewModel: InventoryViewModel
    @Bindable var coordinator: InventoryCoordinator
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            Group {
                if viewModel.isEmpty {
                    EmptyStateView(
                        title: "Your fridge is empty",
                        message: "Scan a label or add something by hand. We'll remind you before it goes off and suggest what to cook.",
                        primaryTitle: "Scan a label",
                        primaryAction: { viewModel.showScan() },
                        secondaryTitle: "Try it with sample food",
                        secondaryAction: { viewModel.loadSampleData() }
                    )
                } else {
                    list
                }
            }
            .background(Constants.BackgroundSecondary)
            .navigationTitle("Fridge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { viewModel.showScan() } label: {
                            Label("Scan label or barcode", systemImage: "camera.viewfinder")
                        }
                        Button { viewModel.showAddItem() } label: {
                            Label("Add manually", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("inventory.addButton")
                }
            }
            .navigationDestination(for: InventoryRoute.self) { route in
                destination(for: route)
            }
        }
    }

    private var list: some View {
        List {
            if viewModel.showsNotificationTip {
                Section {
                    notificationTip
                }
            }

            Section {
                Picker("Storage", selection: $viewModel.storageFilter) {
                    ForEach(InventoryViewModel.StorageFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        NavigationLink(value: InventoryRoute.itemDetail(item.id)) {
                            FoodItemRow(item: item, soonThresholdDays: viewModel.soonThresholdDays)
                        }
                        .swipeActions(edge: .leading) {
                            Button { viewModel.markUsed(item) } label: {
                                Label("Used", systemImage: "checkmark")
                            }
                            .tint(Constants.StatusFresh)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { viewModel.delete(item) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Label(section.status.sectionTitle, systemImage: section.status.symbol)
                        .foregroundStyle(section.status.tint)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search your food")
        .scrollContentBackground(.hidden)
    }

    private var notificationTip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Get reminded before food expires", systemImage: "bell.badge")
                .font(.app(.headline, weight: .semibold))
            Text("Turn on reminders to hear about items a few days before their date.")
                .font(.app(.subheadline))
                .foregroundStyle(Constants.TextSecondary)
            HStack {
                Button("Turn on") { Task { await viewModel.enableNotifications() } }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.Brand)
                Button("Not now") { viewModel.dismissNotificationTip() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
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

//
//  ItemDetailView.swift
//  ZeroWaste
//

import SwiftUI

struct ItemDetailView: View {
    @Bindable var viewModel: ItemDetailViewModel
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let item = viewModel.item {
                content(for: item)
            } else {
                EmptyStateView(title: "Item removed", message: "This item is no longer in your fridge.", systemImage: "trash")
                    .padding(Spacing.gutter)
            }
        }
        .pageBackground()
        .topBar(.back) {
            if viewModel.state != .missing {
                Menu {
                    Button { viewModel.edit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    HeaderIconButtonLabel(symbol: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .confirmationDialog("Delete this item?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { viewModel.delete() }
        }
    }

    private func content(for item: FoodItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                DetailTitle(overline: item.category.label, title: item.name)

                statusCard(for: item)

                CardSection("Details") {
                    InfoRow("Stored in", symbol: item.storage.symbol, value: item.storage.label)
                    InfoRow("Quantity", symbol: "scalemass", value: item.quantityText)
                    InfoRow("Expires", symbol: "calendar", value: item.expiresAt.formatted(date: .long, time: .omitted))
                    InfoRow("Added", symbol: "plus.circle", value: item.addedAt.formatted(date: .abbreviated, time: .omitted))
                    if let barcode = item.barcode, !barcode.isEmpty {
                        InfoRow("Barcode", symbol: "barcode", value: barcode)
                    }
                }

                if !item.notes.isEmpty {
                    CardSection("Notes") {
                        Text(item.notes)
                            .font(.app(.subheadline))
                            .foregroundStyle(Constants.TextPrimary)
                    }
                }

                if viewModel.state == .active {
                    recipes(for: item)
                }

                actions
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func statusCard(for item: FoodItem) -> some View {
        let status = viewModel.status ?? .fresh
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.md) {
                IconTile(symbol: item.category.symbol, tint: viewModel.state == .used ? Constants.TextSecondary : status.tint, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.state == .used, let consumedAt = item.consumedAt {
                        Text("Used up")
                            .font(.app(.headline, weight: .semibold))
                            .foregroundStyle(Constants.TextPrimary)
                        Text(consumedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
                    } else {
                        Text(item.expiryDescription())
                            .font(.app(.headline, weight: .semibold))
                            .foregroundStyle(status.tint)
                        // "Expires today" would just repeat the headline, so show what's left instead.
                        Text(item.expiryDescription() == status.sectionTitle
                             ? "\(item.quantityText) · \(item.storage.label)"
                             : status.sectionTitle)
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
                    }
                }
                Spacer()
            }
            if viewModel.state == .active {
                ShelfLifeBar(progress: item.shelfLifeProgress(), tint: status.tint)
            }
        }
        .cardStyle(accent: viewModel.state == .active && status.needsAttention ? status.tint : nil)
    }

    @ViewBuilder
    private func recipes(for item: FoodItem) -> some View {
        let matches = viewModel.recipeMatches
        CardSection("Recipes using \(item.name.lowercased())") {
            if matches.isEmpty {
                Text("No recipe in the catalogue uses this yet.")
                    .font(.app(.subheadline))
                    .foregroundStyle(Constants.TextSecondary)
            } else {
                ForEach(matches) { match in
                    Button { viewModel.showRecipe(match) } label: {
                        RecipeRow(match: match)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            if viewModel.state == .used {
                PrimaryButton("Put it back in the fridge", systemImage: "arrow.uturn.backward", kind: .tonal) {
                    viewModel.restore()
                }
            } else {
                PrimaryButton("Mark as used up", systemImage: "checkmark") { viewModel.markUsed() }
                PrimaryButton("Edit", systemImage: "pencil", kind: .tonal) { viewModel.edit() }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        InventoryFactory.makeDetail(
            itemID: dependencies.inventory.activeItems[2].id,
            dependencies: dependencies,
            onEdit: { _ in },
            onShowRecipe: { _ in },
            onDeleted: {}
        )
    }
}

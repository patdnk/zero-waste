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
                ContentUnavailableView("Item removed", systemImage: "trash")
            }
        }
        .navigationTitle(viewModel.item?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.state != .missing {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { viewModel.edit() } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete this item?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { viewModel.delete() }
        }
    }

    private func content(for item: FoodItem) -> some View {
        List {
            Section {
                statusCard(for: item)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Details") {
                LabeledContent("Category", value: item.category.label)
                LabeledContent("Stored in", value: item.storage.label)
                LabeledContent("Quantity", value: item.quantityText)
                LabeledContent("Expires", value: item.expiresAt.formatted(date: .long, time: .omitted))
                LabeledContent("Added", value: item.addedAt.formatted(date: .abbreviated, time: .omitted))
                if let barcode = item.barcode, !barcode.isEmpty {
                    LabeledContent("Barcode", value: barcode)
                }
                if !item.notes.isEmpty {
                    Text(item.notes).foregroundStyle(Constants.TextSecondary)
                }
            }

            if viewModel.state == .active {
                let matches = viewModel.recipeMatches
                Section("Recipes using \(item.name)") {
                    if matches.isEmpty {
                        Text("No bundled recipe uses this yet.")
                            .foregroundStyle(Constants.TextSecondary)
                    } else {
                        ForEach(matches) { match in
                            Button { viewModel.showRecipe(match) } label: {
                                RecipeRow(match: match)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section {
                if viewModel.state == .used {
                    Button { viewModel.restore() } label: {
                        Label("Put it back in the fridge", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button { viewModel.markUsed() } label: {
                        Label("Mark as used up", systemImage: "checkmark.circle")
                    }
                    .foregroundStyle(Constants.StatusFresh)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Constants.BackgroundSecondary)
    }

    private func statusCard(for item: FoodItem) -> some View {
        let status = viewModel.status ?? .fresh
        return HStack(spacing: 16) {
            Image(systemName: item.category.symbol)
                .font(.system(size: 36))
                .foregroundStyle(status.tint)
                .frame(width: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.app(.title2, weight: .bold)).foregroundStyle(Constants.TextPrimary)
                if viewModel.state == .used, let consumedAt = item.consumedAt {
                    Text("Used up on \(consumedAt.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(Constants.TextSecondary)
                } else {
                    Label(item.expiryDescription(), systemImage: status.symbol)
                        .foregroundStyle(status.tint)
                        .fontWeight(.semibold)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(status.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
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

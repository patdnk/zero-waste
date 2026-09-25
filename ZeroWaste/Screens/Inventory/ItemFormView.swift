//
//  ItemFormView.swift
//  ZeroWaste
//

import SwiftUI

struct ItemFormView: View {
    @Bindable var viewModel: ItemFormViewModel
    let onCancel: () -> Void

    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section("Product") {
                TextField("Name", text: $viewModel.draft.name)
                    .focused($nameFocused)
                    .accessibilityIdentifier("itemForm.name")
                Picker("Category", selection: $viewModel.draft.category) {
                    ForEach(FoodCategory.allCases) { category in
                        Label(category.label, systemImage: category.symbol).tag(category)
                    }
                }
                Picker("Stored in", selection: $viewModel.draft.storage) {
                    ForEach(StorageLocation.allCases) { location in
                        Label(location.label, systemImage: location.symbol).tag(location)
                    }
                }
            }

            Section("Quantity") {
                HStack {
                    TextField("Amount", value: $viewModel.draft.quantity, format: .number)
                        .keyboardType(.decimalPad)
                    Divider()
                    TextField("Unit", text: $viewModel.draft.unit)
                        .frame(maxWidth: 90)
                    Menu {
                        ForEach(ItemDraft.unitSuggestions, id: \.self) { unit in
                            Button(unit) { viewModel.draft.unit = unit }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
            }

            Section {
                DatePicker("Expires on", selection: $viewModel.draft.expiresAt, displayedComponents: .date)
                Button("Use typical shelf life (\(viewModel.defaultShelfLifeDays) days)") {
                    viewModel.applyDefaultShelfLife()
                }
            } header: {
                Text("Expiry")
            } footer: {
                Text("No date on the label? Use the typical shelf life for \(viewModel.draft.category.label.lowercased()).")
            }

            Section("Notes") {
                TextField("Opened on Monday, half left…", text: $viewModel.draft.notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let barcode = viewModel.draft.barcode {
                Section("Barcode") {
                    Text(barcode).foregroundStyle(Constants.TextSecondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error).foregroundStyle(Constants.StatusExpired)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { viewModel.save() }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("itemForm.save")
            }
        }
        .onAppear {
            if viewModel.draft.name.isEmpty { nameFocused = true }
        }
    }
}

#Preview {
    NavigationStack {
        InventoryFactory.makeForm(mode: .add, draft: ItemDraft(), dependencies: .preview(), onCancel: {}, onSaved: { _ in })
    }
}

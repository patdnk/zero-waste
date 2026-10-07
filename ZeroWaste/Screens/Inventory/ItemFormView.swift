//
//  ItemFormView.swift
//  ZeroWaste
//

import SwiftUI

struct ItemFormView: View {
    @Bindable var viewModel: ItemFormViewModel
    let onCancel: () -> Void

    @FocusState private var quantityFocused: Bool
    @FocusState private var unitFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    DetailTitle(overline: viewModel.isEditing ? "Edit" : "Add to your fridge", title: viewModel.title)

                    LabeledInput(
                        label: "Name",
                        placeholder: "Greek yogurt",
                        text: $viewModel.draft.name,
                        accessibilityID: "itemForm.name",
                        autoFocus: viewModel.draft.name.isEmpty
                    )

                    LabeledInput(
                        label: "Brand (optional, helps spot recalls)",
                        placeholder: "Yeo Valley",
                        text: Binding(
                            get: { viewModel.draft.brand ?? "" },
                            set: { viewModel.draft.brand = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
                        ),
                        accessibilityID: "itemForm.brand"
                    )

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Overline("Category")
                        ChipFilter(options: FoodCategory.allCases, selection: $viewModel.draft.category) { $0.label }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Overline("Stored in")
                        ChipFilter(options: StorageLocation.allCases, selection: $viewModel.draft.storage) { $0.label }
                    }

                    quantity

                    CardSection("Expiry", footer: "No date on the label? Use the typical shelf life for \(viewModel.draft.category.label.lowercased()).") {
                        InfoRow("Expires on", symbol: "calendar") {
                            DatePicker("Expires on", selection: $viewModel.draft.expiresAt, displayedComponents: .date)
                                .labelsHidden()
                        }
                        ActionRow(title: "Use typical shelf life (\(viewModel.defaultShelfLifeDays) days)", symbol: "wand.and.stars", tint: Constants.BrandOrange) {
                            viewModel.applyDefaultShelfLife()
                        }
                    }

                    LabeledInput(label: "Notes", placeholder: "Opened on Monday, half left", text: $viewModel.draft.notes, axis: .vertical)

                    if let barcode = viewModel.draft.barcode {
                        CardSection {
                            InfoRow("Barcode", symbol: "barcode", value: barcode)
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.app(.subheadline, weight: .medium))
                            .foregroundStyle(Constants.StatusExpired)
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(viewModel.isEditing ? "Save changes" : "Add to fridge", isEnabled: viewModel.canSave) {
                viewModel.save()
            }
            .accessibilityIdentifier("itemForm.save")
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.sm)
            .background(Constants.BackgroundPrimary)
        }
        .pageBackground()
        .topBar(.close(onCancel))
    }

    private var quantity: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Overline("Quantity")
            HStack(spacing: Spacing.sm) {
                TextField("Amount", value: $viewModel.draft.quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.app(.body))
                    .focused($quantityFocused)
                    .inputChrome(isFocused: quantityFocused)
                TextField("Unit", text: $viewModel.draft.unit)
                    .font(.app(.body))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($unitFocused)
                    .inputChrome(isFocused: unitFocused)
                    .frame(width: 110)
            }
            ChipFilter(options: ItemDraft.unitSuggestions, selection: $viewModel.draft.unit) { $0 }
        }
    }
}

#Preview {
    NavigationStack {
        InventoryFactory.makeForm(mode: .add, draft: ItemDraft(), dependencies: .preview(), onCancel: {}, onSaved: { _ in })
    }
}

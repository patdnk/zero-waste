//
//  CookedView.swift
//  ZeroWaste
//

import SwiftUI

struct CookedView: View {
    @Bindable var viewModel: CookedViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.usableItems) { item in
                        Button { viewModel.toggle(item) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.isSelected(item) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.isSelected(item) ? Constants.Brand : Constants.TextSecondary)
                                    .font(.app(.title3))
                                Text(item.name).foregroundStyle(Constants.TextPrimary)
                                Spacer()
                                Text(item.quantityText).foregroundStyle(Constants.TextSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Nice one! What did you use up?")
                } footer: {
                    Text("Ticked items are marked as used. Anything unticked stays in your fridge — edit its quantity if you only used some.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Constants.BackgroundSecondary)
            .navigationTitle(viewModel.recipe?.title ?? "Cooked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.selectedCount == 0 ? "Done" : "Update fridge") { viewModel.confirm() }
                        .accessibilityIdentifier("cooked.confirm")
                }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RecipesFactory.makeCooked(recipeID: dependencies.recipes.first?.id ?? "", dependencies: dependencies, onDone: {})
}

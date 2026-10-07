//
//  CookedView.swift
//  ZeroBite
//

import SwiftUI

struct CookedView: View {
    @Bindable var viewModel: CookedViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        DetailTitle(overline: viewModel.recipe?.title ?? "Cooked", title: "Nice one! What did you use up?")

                        CardSection(footer: "Ticked items are marked as used. Anything unticked stays in your fridge — edit its quantity if you only used some.") {
                            ForEach(viewModel.usableItems) { item in
                                let isSelected = viewModel.isSelected(item)
                                Button { viewModel.toggle(item) } label: {
                                    HStack(spacing: Spacing.md) {
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 20))
                                            .foregroundStyle(isSelected ? Constants.BrandOrange : Constants.TextMuted)
                                        Text(item.name)
                                            .font(.app(.subheadline, weight: .medium))
                                            .foregroundStyle(Constants.TextPrimary)
                                        Spacer()
                                        Text(item.quantityText)
                                            .font(.app(.caption))
                                            .foregroundStyle(Constants.TextSecondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl)
                }

                PrimaryButton(viewModel.selectedCount == 0 ? "Done" : "Update fridge") { viewModel.confirm() }
                    .accessibilityIdentifier("cooked.confirm")
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.vertical, Spacing.sm)
            }
            .pageBackground()
            .topBar(.close { viewModel.cancel() })
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RecipesFactory.makeCooked(recipeID: dependencies.recipes.first?.id ?? "", dependencies: dependencies, onDone: {})
}

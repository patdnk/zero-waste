//
//  RecipesView.swift
//  ZeroWaste
//

import SwiftUI

struct RecipesView: View {
    @Bindable var viewModel: RecipesViewModel
    @Bindable var coordinator: RecipesCoordinator
    let dependencies: AppDependencies

    private let columns = [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)]

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ScreenHeader(overline: "From your fridge", title: "Recipes")

                        if viewModel.showsExpiringStrip {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                SectionHeading(title: "Use these first", tint: Constants.BrandOrange, symbol: "clock.badge.exclamationmark")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(viewModel.expiringItems) { item in
                                            Button { viewModel.showItem(item) } label: {
                                                ExpiringChip(item: item, soonThresholdDays: viewModel.soonThresholdDays)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, Spacing.gutter)
                                }
                                .scrollClipDisabled()
                                .padding(.horizontal, -Spacing.gutter)
                            }
                        }

                        ChipFilter(options: RecipesViewModel.Scope.allCases, selection: $viewModel.scope) { $0.title }

                        results
                    }
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.bottom, Spacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                BottomSearchBar(text: $viewModel.searchText, prompt: "Search recipes or ingredients", accessibilityID: "recipes.search")
            }
            .pageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipesRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        let matches = viewModel.displayedMatches
        if matches.isEmpty {
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
            SectionHeading(
                title: viewModel.scope.sectionTitle,
                detail: matches.count == 1 ? "1 recipe" : "\(matches.count) recipes"
            )
            if let first = matches.first {
                NavigationLink(value: RecipesRoute.recipe(first.recipe.id)) {
                    FeaturedRecipeCard(match: first)
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(matches.dropFirst()) { match in
                    NavigationLink(value: RecipesRoute.recipe(match.recipe.id)) {
                        RecipeCard(match: match)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: RecipesRoute) -> some View {
        switch route {
        case .recipe(let id):
            RecipesFactory.makeDetail(
                recipeID: id,
                dependencies: dependencies,
                onShowItem: { coordinator.showItem(id: $0) },
                onCooked: { coordinator.showCooked(recipeID: $0) }
            )
        case .itemDetail(let id):
            InventoryFactory.makeDetail(
                itemID: id,
                dependencies: dependencies,
                onEdit: { coordinator.showEditItem(id: $0) },
                onShowRecipe: { coordinator.showRecipe(id: $0) },
                onDeleted: { coordinator.pop() }
            )
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let coordinator = AppCoordinator(dependencies: dependencies)
    RecipesFactory.makeList(coordinator: coordinator.recipesCoordinator, dependencies: dependencies)
}

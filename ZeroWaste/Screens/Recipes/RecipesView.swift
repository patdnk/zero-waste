//
//  RecipesView.swift
//  ZeroWaste
//

import SwiftUI

struct RecipesView: View {
    @Bindable var viewModel: RecipesViewModel
    @Bindable var coordinator: RecipesCoordinator
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            List {
                if viewModel.showsExpiringStrip {
                    Section("Use these first") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.expiringItems) { item in
                                    Button { viewModel.showItem(item) } label: {
                                        ExpiringChip(item: item, soonThresholdDays: viewModel.soonThresholdDays)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    Picker("Scope", selection: $viewModel.scope) {
                        ForEach(RecipesViewModel.Scope.allCases, id: \.self) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section(viewModel.scope.sectionTitle) {
                    let matches = viewModel.displayedMatches
                    if matches.isEmpty {
                        ContentUnavailableView(
                            viewModel.emptyTitle,
                            systemImage: "frying.pan",
                            description: Text(viewModel.emptyMessage)
                        )
                    } else {
                        ForEach(matches) { match in
                            NavigationLink(value: RecipesRoute.recipe(match.recipe.id)) {
                                RecipeRow(match: match)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Constants.BackgroundSecondary)
            .searchable(text: $viewModel.searchText, prompt: "Search recipes or ingredients")
            .navigationTitle("Recipes")
            .navigationDestination(for: RecipesRoute.self) { route in
                destination(for: route)
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

//
//  RecipeStore.swift
//  ZeroBite
//
//  Loads the bundled recipe catalogue.
//

import Foundation

enum RecipeStore {

    static func loadBundled(bundle: Bundle = .main) -> [Recipe] {
        guard let url = bundle.url(forResource: "recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([Recipe].self, from: data)) ?? []
    }
}

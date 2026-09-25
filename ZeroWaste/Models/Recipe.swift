//
//  Recipe.swift
//  ZeroWaste
//
//  Bundled recipe catalogue model (Resources/recipes.json).
//

import Foundation

struct Recipe: Codable, Identifiable, Hashable, Sendable {

    struct Ingredient: Codable, Hashable, Identifiable, Sendable {
        var name: String
        var amount: String
        var optional: Bool

        var id: String { "\(name)|\(amount)" }

        init(name: String, amount: String = "", optional: Bool = false) {
            self.name = name
            self.amount = amount
            self.optional = optional
        }

        private enum CodingKeys: String, CodingKey { case name, amount, optional }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
            optional = try container.decodeIfPresent(Bool.self, forKey: .optional) ?? false
        }
    }

    let id: String
    let title: String
    let summary: String
    let ingredients: [Ingredient]
    let steps: [String]
    let prepMinutes: Int
    let servings: Int
    let tags: [String]

    var requiredIngredients: [Ingredient] { ingredients.filter { !$0.optional } }
}

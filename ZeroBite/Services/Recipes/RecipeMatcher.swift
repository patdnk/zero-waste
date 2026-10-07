//
//  RecipeMatcher.swift
//  ZeroBite
//
//  Scores recipes against what's in the fridge, favouring recipes that use up food that
//  is about to expire. Pure logic — no SwiftData context needed — so it's unit-testable.
//

import Foundation

struct MatchedIngredient: Hashable {
    let ingredient: Recipe.Ingredient
    /// The fridge item satisfying this ingredient. `nil` means it's a store-cupboard staple.
    let item: FoodItem?

    var isStaple: Bool { item == nil }
}

struct RecipeMatch: Identifiable, Hashable {
    let recipe: Recipe
    let matched: [MatchedIngredient]
    let missing: [Recipe.Ingredient]
    let missingOptional: [Recipe.Ingredient]
    let expiringItems: [FoodItem]
    let score: Double

    var id: String { recipe.id }
    var canMake: Bool { missing.isEmpty }
    var usedItems: [FoodItem] {
        var seen = Set<UUID>()
        return matched.compactMap { $0.item }.filter { seen.insert($0.id).inserted }
    }
    var requiredCount: Int { recipe.requiredIngredients.count }
    var requiredMatchedCount: Int { matched.filter { !$0.ingredient.optional }.count }

    func uses(itemID: UUID) -> Bool { matched.contains { $0.item?.id == itemID } }
}

struct RecipeMatcher: Sendable {

    var soonThresholdDays: Int = 3
    var now: Date = .now

    // MARK: - Vocabulary

    /// Assumed to always be in the cupboard; never counted as "missing".
    static let staples: Set<String> = Set([
        "salt", "black pepper", "olive oil", "vegetable oil", "oil", "water", "sugar", "flour",
        "plain flour", "vinegar", "soy sauce", "stock", "stock cube", "chilli flakes", "dried herbs",
    ].map(normalize))

    /// Names that should be treated as interchangeable when matching.
    static let synonymGroups: [[String]] = [
        ["cheese", "cheddar", "mozzarella", "parmesan", "feta", "gouda", "brie", "halloumi", "gruyere", "emmental"],
        ["chicken", "chicken breast", "chicken thigh"],
        ["yogurt", "yoghurt", "greek yogurt", "natural yogurt", "skyr"],
        ["courgette", "zucchini"],
        ["aubergine", "eggplant"],
        ["coriander", "cilantro"],
        ["spring onion", "scallion", "green onion"],
        ["rocket", "arugula"],
        ["mince", "minced beef", "beef mince", "ground beef", "beef"],
        ["pasta", "spaghetti", "penne", "fusilli", "tagliatelle", "linguine", "macaroni", "rigatoni"],
        ["rice", "basmati", "jasmine rice", "long grain rice"],
        ["bread", "sourdough", "baguette", "ciabatta", "roll", "bap", "pitta", "pita", "loaf"],
        ["cream", "double cream", "single cream", "creme fraiche"],
        ["bacon", "pancetta", "lardons"],
        ["bell pepper", "red pepper", "green pepper", "yellow pepper", "capsicum"],
        ["tortilla", "wrap", "flatbread"],
        ["noodle", "egg noodle", "rice noodle", "ramen"],
        ["berry", "strawberry", "blueberry", "raspberry", "blackberry", "mixed berries"],
        ["prawn", "shrimp"],
        ["lettuce", "salad leaves", "mixed leaves", "romaine", "iceberg", "little gem"],
        ["tuna", "tinned tuna"],
        ["banana"],
    ].map { $0.map(normalize) }

    // MARK: - Matching

    func match(recipes: [Recipe], inventory: [FoodItem]) -> [RecipeMatch] {
        let available = inventory.filter { !$0.isConsumed }
        return recipes
            .map { match(recipe: $0, inventory: available) }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.recipe.title < $1.recipe.title
            }
    }

    func match(recipe: Recipe, inventory: [FoodItem]) -> RecipeMatch {
        let available = inventory.filter { !$0.isConsumed }
        var matched: [MatchedIngredient] = []
        var missing: [Recipe.Ingredient] = []
        var missingOptional: [Recipe.Ingredient] = []

        for ingredient in recipe.ingredients {
            if let item = bestItem(for: ingredient.name, in: available) {
                matched.append(MatchedIngredient(ingredient: ingredient, item: item))
            } else if Self.isStaple(ingredient.name) {
                matched.append(MatchedIngredient(ingredient: ingredient, item: nil))
            } else if ingredient.optional {
                missingOptional.append(ingredient)
            } else {
                missing.append(ingredient)
            }
        }

        let required = recipe.requiredIngredients.count
        let requiredMatched = matched.filter { !$0.ingredient.optional }.count
        let coverage = required == 0 ? 1 : Double(requiredMatched) / Double(required)

        var seen = Set<UUID>()
        let expiring = matched
            .compactMap { $0.item }
            .filter { $0.status(soonThresholdDays: soonThresholdDays, now: now).needsAttention }
            .filter { seen.insert($0.id).inserted }

        let realMatches = matched.filter { $0.item != nil }.count
        var score = coverage * 100
        score += Double(expiring.count) * 15
        score -= Double(missing.count) * 5
        if missing.isEmpty { score += 20 }
        if realMatches == 0 { score -= 100 } // only staples: not really "makeable from the fridge"

        return RecipeMatch(
            recipe: recipe,
            matched: matched,
            missing: missing,
            missingOptional: missingOptional,
            expiringItems: expiring,
            score: score
        )
    }

    /// Prefers the item that expires soonest when several satisfy the ingredient.
    func bestItem(for ingredient: String, in items: [FoodItem]) -> FoodItem? {
        items
            .filter { Self.matches(ingredient: ingredient, itemName: $0.name) }
            .min { $0.expiresAt < $1.expiresAt }
    }

    // MARK: - Name matching

    static func matches(ingredient: String, itemName: String) -> Bool {
        let a = normalize(ingredient)
        let b = normalize(itemName)
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }
        if containsWords(a, in: b) || containsWords(b, in: a) { return true }
        if let ga = synonymGroup(for: a), let gb = synonymGroup(for: b), ga == gb { return true }
        return false
    }

    static func isStaple(_ name: String) -> Bool {
        let normalized = normalize(name)
        return staples.contains(normalized) || staples.contains { containsWords($0, in: normalized) }
    }

    /// Lowercase, strip accents/punctuation, singularise each word.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
        let cleaned = folded.map { $0.isLetter || $0 == " " ? $0 : " " }
        return String(cleaned)
            .split(separator: " ")
            .map { singularize(String($0)) }
            .joined(separator: " ")
    }

    static func singularize(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("ss") || word.hasSuffix("us") || word.hasSuffix("is") { return word }
        if word.hasSuffix("ches") || word.hasSuffix("shes") || word.hasSuffix("xes") || word.hasSuffix("ses") {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("s") { return String(word.dropLast()) }
        return word
    }

    /// Whole-word phrase containment: "onion" is in "spring onion" but not in "onionring".
    static func containsWords(_ needle: String, in haystack: String) -> Bool {
        guard needle.count >= 3 else { return false }
        return " \(haystack) ".contains(" \(needle) ")
    }

    private static func synonymGroup(for normalizedName: String) -> Int? {
        synonymGroups.firstIndex { group in
            group.contains { $0 == normalizedName || containsWords($0, in: normalizedName) }
        }
    }
}

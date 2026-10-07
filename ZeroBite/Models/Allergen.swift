//
//  Allergen.swift
//  ZeroBite
//
//  The 14 allergens UK law requires on labels, and how they map to the (more specific)
//  allergen labels used in FSA allergy alerts, e.g. "Gluten" covers "Wheat" and "Barley".
//

import Foundation

enum Allergen: String, CaseIterable, Identifiable, Codable, Sendable {
    case celery, gluten, crustaceans, egg, fish, lupin, milk, molluscs, mustard, nuts, peanuts, sesame, soya, sulphites

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gluten: "Gluten"
        case .nuts: "Tree nuts"
        case .sulphites: "Sulphites"
        default: rawValue.capitalized
        }
    }

    /// Lowercased FSA alert labels (or prefixes) this allergen covers.
    private var alertTerms: [String] {
        switch self {
        case .celery: ["celery", "celeriac"]
        case .gluten: ["gluten", "wheat", "barley", "rye", "oat", "spelt", "kamut"]
        case .crustaceans: ["crustacean", "crab", "lobster", "prawn", "shrimp", "langoustine"]
        case .egg: ["egg"]
        case .fish: ["fish"]
        case .lupin: ["lupin"]
        case .milk: ["milk", "lactose", "whey", "casein"]
        case .molluscs: ["mollusc", "mussel", "oyster", "squid", "clam", "scallop"]
        case .mustard: ["mustard"]
        case .nuts: ["nut", "almond", "hazelnut", "walnut", "cashew", "pecan", "brazil", "pistachio", "macadamia"]
        case .peanuts: ["peanut"]
        case .sesame: ["sesame"]
        case .soya: ["soy"]
        case .sulphites: ["sulphite", "sulfite", "sulphur dioxide"]
        }
    }

    func matches(alertLabel: String) -> Bool {
        let label = alertLabel.lowercased()
        // "Peanuts" is its own allergen, not a tree nut.
        if self == .nuts, label.hasPrefix("peanut") { return false }
        return alertTerms.contains { label.hasPrefix($0) || label.contains(" \($0)") }
    }
}

extension FoodAlert {
    /// The user's allergens this allergy alert concerns.
    func concerns(_ allergens: [Allergen]) -> [Allergen] {
        guard kind == .allergy else { return [] }
        return allergens.filter { allergen in self.allergens.contains(where: allergen.matches(alertLabel:)) }
    }
}

extension AppSettings {
    var allergenProfile: [Allergen] {
        get { allergens.compactMap(Allergen.init(rawValue:)) }
        set { allergens = newValue.map(\.rawValue) }
    }
}

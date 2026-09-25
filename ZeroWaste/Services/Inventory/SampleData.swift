//
//  SampleData.swift
//  ZeroWaste
//
//  A realistic fridge for previews, the simulator, and "try it out".
//

import Foundation

enum SampleData {

    static func items(now: Date = .now) -> [FoodItem] {
        func day(_ offset: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: offset, to: now) ?? now
        }
        return [
            FoodItem(name: "Greek yogurt", quantity: 500, unit: "g", category: .dairy, expiresAt: day(-1)),
            FoodItem(name: "Spinach", quantity: 1, unit: "bag", category: .vegetables, expiresAt: day(0)),
            FoodItem(name: "Chicken breast", quantity: 2, unit: "pcs", category: .meat, expiresAt: day(1)),
            FoodItem(name: "Semi-skimmed milk", quantity: 2, unit: "pints", category: .dairy, expiresAt: day(2)),
            FoodItem(name: "Mushrooms", quantity: 250, unit: "g", category: .vegetables, expiresAt: day(2)),
            FoodItem(name: "Sourdough bread", quantity: 1, unit: "loaf", category: .bakery, expiresAt: day(2)),
            FoodItem(name: "Cherry tomatoes", quantity: 1, unit: "punnet", category: .vegetables, expiresAt: day(3)),
            FoodItem(name: "Red pepper", quantity: 2, unit: "pcs", category: .vegetables, expiresAt: day(4)),
            FoodItem(name: "Bacon", quantity: 1, unit: "pack", category: .meat, expiresAt: day(5)),
            FoodItem(name: "Lemon", quantity: 3, unit: "pcs", category: .fruit, expiresAt: day(8)),
            FoodItem(name: "Bananas", quantity: 5, unit: "pcs", category: .fruit, expiresAt: day(4)),
            FoodItem(name: "Carrots", quantity: 6, unit: "pcs", category: .vegetables, expiresAt: day(10)),
            FoodItem(name: "Onion", quantity: 3, unit: "pcs", category: .vegetables, expiresAt: day(12)),
            FoodItem(name: "Eggs", quantity: 6, unit: "pcs", category: .dairy, expiresAt: day(12)),
            FoodItem(name: "Cheddar cheese", quantity: 350, unit: "g", category: .dairy, expiresAt: day(14)),
            FoodItem(name: "Potatoes", quantity: 1.5, unit: "kg", category: .vegetables, storage: .pantry, expiresAt: day(14)),
            FoodItem(name: "Garlic", quantity: 1, unit: "bulb", category: .vegetables, storage: .pantry, expiresAt: day(30)),
            FoodItem(name: "Butter", quantity: 250, unit: "g", category: .dairy, expiresAt: day(30)),
            FoodItem(name: "Salmon fillets", quantity: 2, unit: "pcs", category: .fish, storage: .freezer, expiresAt: day(60)),
            FoodItem(name: "Basmati rice", quantity: 1, unit: "kg", category: .grains, storage: .pantry, expiresAt: day(300)),
            FoodItem(name: "Spaghetti", quantity: 500, unit: "g", category: .grains, storage: .pantry, expiresAt: day(400)),
        ]
    }
}

//
//  ItemDraft.swift
//  ZeroWaste
//
//  Value-type editing buffer for the add/edit item form. Keeps SwiftData objects out of
//  the form until the user commits.
//

import Foundation

struct ItemDraft: Hashable, Sendable {
    var name = ""
    var category: FoodCategory = .other
    var storage: StorageLocation = .fridge
    var quantity: Double = 1
    var unit = "pcs"
    var expiresAt: Date
    var notes = ""
    var barcode: String?
    var brand: String?

    static let unitSuggestions = ["pcs", "g", "kg", "ml", "l", "pack", "slices"]

    init(now: Date = .now) {
        expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
    }

    init(item: FoodItem) {
        name = item.name
        category = item.category
        storage = item.storage
        quantity = item.quantity
        unit = item.unit
        expiresAt = item.expiresAt
        notes = item.notes
        barcode = item.barcode
        brand = item.brand
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty && quantity > 0 }

    func makeItem(now: Date = .now) -> FoodItem {
        FoodItem(
            name: trimmedName,
            quantity: quantity,
            unit: unit.trimmingCharacters(in: .whitespaces).isEmpty ? "pcs" : unit,
            category: category,
            storage: storage,
            addedAt: now,
            expiresAt: expiresAt,
            barcode: barcode,
            brand: brand,
            notes: notes
        )
    }

    func apply(to item: FoodItem) {
        item.name = trimmedName
        item.quantity = quantity
        item.unit = unit.trimmingCharacters(in: .whitespaces).isEmpty ? "pcs" : unit
        item.category = category
        item.storage = storage
        item.expiresAt = expiresAt
        item.notes = notes
        item.barcode = barcode
        item.brand = brand
    }
}

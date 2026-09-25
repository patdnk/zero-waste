//
//  TestSupport.swift
//  ZeroWasteTests
//

import Foundation
@testable import ZeroWaste

enum TestSupport {

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    static func item(_ name: String, daysUntilExpiry: Int, from now: Date, category: FoodCategory = .other, consumed: Bool = false) -> FoodItem {
        FoodItem(
            name: name,
            category: category,
            expiresAt: calendar.date(byAdding: .day, value: daysUntilExpiry, to: now)!,
            consumedAt: consumed ? now : nil
        )
    }
}

struct StubProductLookup: ProductLookup {
    let info: ProductInfo?

    func lookup(barcode: String) async throws -> ProductInfo? { info }
}

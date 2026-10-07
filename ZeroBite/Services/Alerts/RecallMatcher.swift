//
//  RecallMatcher.swift
//  ZeroBite
//
//  Decides which food alerts might concern items in the fridge. FSA notices carry product
//  names, businesses, pack sizes and free-text batch dates but rarely a barcode, so matching
//  is deliberately cautious: results are "likely" or "possible", never certain, and the UI
//  always asks the user to check the pack.
//

import Foundation

struct RecallMatch: Identifiable, Hashable, Sendable {

    enum Confidence: Int, Comparable, Sendable {
        case possible
        case likely

        static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    enum Reason: String, Hashable, Sendable {
        /// The item's barcode appears on the notice.
        case barcode
        /// The item's name matches a recalled product.
        case name
        /// The item's brand (or a brand word in its name) matches the business or product.
        case brand
        /// The item's date matches a recalled batch date.
        case date
        /// The notice covers every batch of the product.
        case allBatches
    }

    let alert: FoodAlert
    let product: FoodAlert.Product
    let itemID: UUID
    let itemName: String
    let confidence: Confidence
    let reasons: Set<Reason>

    var id: String { Self.id(alertID: alert.id, itemID: itemID) }

    static func id(alertID: String, itemID: UUID) -> String { "\(alertID)|\(itemID.uuidString)" }
}

struct RecallMatcher: Sendable {

    var now: Date = .now
    var calendar: Calendar = .current
    /// Older notices are ignored: products from them have long left the shelves.
    var lookbackDays = 120

    func matches(alerts: [FoodAlert], items: [FoodItem], dismissed: Set<String> = []) -> [RecallMatch] {
        let cutoff = calendar.date(byAdding: .day, value: -lookbackDays, to: now) ?? now
        let recent = alerts.filter { $0.created >= cutoff }
        var results: [RecallMatch] = []
        for item in items where !item.isConsumed {
            // Keep only the best-matching product per alert for each item.
            var best: [String: RecallMatch] = [:]
            for alert in recent {
                for product in alert.products {
                    guard let match = match(alert: alert, product: product, item: item),
                          !dismissed.contains(match.id)
                    else { continue }
                    if let existing = best[alert.id], existing.confidence >= match.confidence { continue }
                    best[alert.id] = match
                }
            }
            results.append(contentsOf: best.values)
        }
        return results.sorted {
            if $0.confidence != $1.confidence { return $0.confidence > $1.confidence }
            return $0.alert.created > $1.alert.created
        }
    }

    func match(alert: FoodAlert, product: FoodAlert.Product, item: FoodItem) -> RecallMatch? {
        var reasons = Set<RecallMatch.Reason>()

        if let barcode = item.barcode?.filter(\.isNumber), barcode.count >= 8, Self.barcodes(on: product).contains(barcode) {
            reasons.insert(.barcode)
        }

        let productWords = Self.words(product.name)
        let businessWords = Set(alert.businesses.flatMap { Self.words($0) }).subtracting(Self.genericBusinessWords)
        let brandWords = Set(Self.words(item.brand ?? ""))
        let itemWords = Self.words(item.name).filter { !businessWords.contains($0) && !brandWords.contains($0) }

        if Self.nameMatches(itemWords: itemWords, productWords: productWords) {
            reasons.insert(.name)
        }

        let allItemWords = Set(Self.words(item.name)).union(brandWords)
        if !businessWords.isDisjoint(with: allItemWords) || (!brandWords.isEmpty && !brandWords.isDisjoint(with: productWords)) {
            reasons.insert(.brand)
        }

        let specs = product.batches.flatMap { AlertDateParser.dates(in: [$0.useBy, $0.bestBefore].compactMap { $0 }.joined(separator: " ")) }
        if product.batches.contains(where: \.coversAllBatches) {
            reasons.insert(.allBatches)
        } else if specs.contains(where: { $0.matches(item.expiresAt, calendar: calendar) }) {
            reasons.insert(.date)
        }
        let dateContradicts = !specs.isEmpty && !reasons.contains(.date) && !reasons.contains(.allBatches)

        let confidence: RecallMatch.Confidence
        if reasons.contains(.barcode) {
            confidence = .likely
        } else if reasons.contains(.name) && reasons.contains(.brand) {
            confidence = (reasons.contains(.date) || reasons.contains(.allBatches)) ? .likely : .possible
        } else if reasons.contains(.name) && !dateContradicts {
            confidence = .possible
        } else {
            return nil
        }

        return RecallMatch(alert: alert, product: product, itemID: item.id, itemName: item.name,
                           confidence: confidence, reasons: reasons)
    }

    // MARK: - Name matching

    /// A one-word item ("Brie", "Ham") must be the product's head noun, so "Milk" doesn't match
    /// "Pistachio Milk Chocolate". Longer names need every word to appear in the product name.
    static func nameMatches(itemWords: [String], productWords: [String]) -> Bool {
        guard !itemWords.isEmpty, let head = productWords.last else { return false }
        if itemWords.count == 1 { return itemWords[0] == head }
        let product = Set(productWords)
        return itemWords.allSatisfy(product.contains)
    }

    /// Lowercased, accent-folded, singular content words, in order.
    static func words(_ text: String) -> [String] {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_GB"))
        return folded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.rangeOfCharacter(from: .decimalDigits) == nil }
            .map(singular)
            .map { synonyms[$0] ?? $0 }
    }

    private static func singular(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("s") && !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    /// Long digit runs on the notice (product codes and barcode-style batch codes).
    static func barcodes(on product: FoodAlert.Product) -> Set<String> {
        let text = ([product.productCode] + product.batches.map(\.batchCode)).compactMap { $0 }.joined(separator: " ")
        return Set(text.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { $0.count >= 8 })
    }

    static let stopWords: Set<String> = [
        "the", "and", "with", "of", "in", "a", "an", "for", "style", "flavour", "flavor", "flavoured",
        "pack", "x", "g", "kg", "ml", "l", "pcs", "organic", "mini", "deluxe", "family", "range", "fresh",
        "finest", "classic", "original", "selection", "everyday", "essential", "taste", "own", "brand",
    ]

    static let genericBusinessWords: Set<String> = [
        "ltd", "limited", "plc", "uk", "co", "company", "foods", "food", "store", "group", "international",
        "trading", "brand", "products", "inc", "llp", "fine", "traditional",
    ]

    static let synonyms: [String: String] = [
        "yoghurt": "yogurt", "yoghurts": "yogurt",
        "courgette": "zucchini", "aubergine": "eggplant", "coriander": "cilantro",
    ]
}

// MARK: - Dates in notices

/// A date from a notice, at day or month precision ("16 July 2026", "May 2027").
struct AlertDateSpec: Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int?

    func matches(_ date: Date, calendar: Calendar) -> Bool {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard parts.year == year, parts.month == month else { return false }
        return day == nil || parts.day == day
    }
}

/// Pulls dates out of FSA batch text such as "10, 16 and 17 July 2026", "end of 28 April 2026",
/// "31 January 2027 02 May 2027" or "May 2027".
enum AlertDateParser {

    private static let monthPattern = "(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"

    private static let written = try! NSRegularExpression(
        pattern: "((?:\\b\\d{1,2}(?:st|nd|rd|th)?\\b[\\s,&]*(?:and\\s+)?)*)\\b\(monthPattern)\\.?,?\\s+(\\d{4})",
        options: [.caseInsensitive]
    )

    private static let numeric = try! NSRegularExpression(pattern: "\\b(\\d{1,2})[/.](\\d{1,2})[/.](\\d{2,4})\\b")

    static func dates(in text: String) -> [AlertDateSpec] {
        let ns = text as NSString
        var specs: [AlertDateSpec] = []

        for match in written.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let daysText = ns.substring(with: match.range(at: 1))
            let monthText = ns.substring(with: match.range(at: 2)).lowercased()
            guard let year = Int(ns.substring(with: match.range(at: 3))),
                  let month = monthIndex(monthText)
            else { continue }
            let days = daysText.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init).filter { (1...31).contains($0) }
            if days.isEmpty {
                specs.append(AlertDateSpec(year: year, month: month, day: nil))
            } else {
                specs.append(contentsOf: days.map { AlertDateSpec(year: year, month: month, day: $0) })
            }
        }

        for match in numeric.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard let day = Int(ns.substring(with: match.range(at: 1))),
                  let month = Int(ns.substring(with: match.range(at: 2))),
                  var year = Int(ns.substring(with: match.range(at: 3))),
                  (1...31).contains(day), (1...12).contains(month)
            else { continue }
            if year < 100 { year += 2000 }
            specs.append(AlertDateSpec(year: year, month: month, day: day))
        }
        return specs
    }

    private static func monthIndex(_ text: String) -> Int? {
        let names = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        return names.firstIndex { text.hasPrefix($0) }.map { $0 + 1 }
    }
}

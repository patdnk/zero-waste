//
//  ScanResult.swift
//  ZeroBite
//
//  Output of reading a label (live camera or photo): raw text, barcode, and the
//  expiry-date candidates the parser found.
//

import Foundation

/// A date the parser found on the label, with how confident it is that it's the expiry.
struct DateCandidate: Identifiable, Hashable, Sendable {
    let date: Date
    let matchedText: String
    let sourceLine: String
    let confidence: Double

    var id: String { "\(Int(date.timeIntervalSince1970))|\(matchedText)|\(sourceLine)" }
}

/// Product details resolved from a barcode (Open Food Facts).
struct ProductInfo: Hashable, Sendable {
    let barcode: String
    let name: String
    let brand: String?
    let category: FoodCategory?
}

struct ScanResult: Hashable, Sendable {
    var lines: [String]
    var barcode: String?
    var candidates: [DateCandidate]
    var suggestedName: String?

    init(lines: [String] = [], barcode: String? = nil, candidates: [DateCandidate] = [], suggestedName: String? = nil) {
        self.lines = lines
        self.barcode = barcode
        self.candidates = candidates
        self.suggestedName = suggestedName
    }

    var bestCandidate: DateCandidate? { candidates.first }
    var isEmpty: Bool { lines.isEmpty && barcode == nil }
}

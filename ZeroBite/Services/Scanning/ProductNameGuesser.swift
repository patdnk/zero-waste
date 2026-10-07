//
//  ProductNameGuesser.swift
//  ZeroBite
//
//  Picks the line of OCR'd label text most likely to be the product name.
//

import Foundation

enum ProductNameGuesser {

    /// Lines containing any of these are label boilerplate, not a product name.
    static let blocklist: [String] = [
        "ingredients", "nutrition", "storage", "keep refrigerated", "keep chilled", "refrigerate",
        "www", "http", "kcal", "kj", "per 100", "typical values", "allergen", "contains", "recycle",
        "barcode", "batch", "lot ", "net weight", "energy", "protein", "carbohydrate", "fat ",
        "salt", "sugars", "fibre", "serving", "once opened", "made in", "produced", "packed",
        "ltd", "plc", "gmbh", "inc.", "©", "®", "tesco", "sainsbury", "asda", "aldi", "lidl",
        "morrisons", "waitrose", "co-op", "m&s", "marks & spencer", "ocado", "iceland",
    ]

    static func guess(from lines: [String]) -> String? {
        var best: (score: Double, text: String)?

        for raw in lines {
            let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 3, text.count <= 40 else { continue }
            let lower = text.lowercased()
            guard !blocklist.contains(where: { lower.contains($0) }) else { continue }
            guard !ExpiryDateParser.containsKeyword(text) else { continue }

            let letters = text.filter(\.isLetter).count
            let digits = text.filter(\.isNumber).count
            guard letters >= 3, digits <= 2, Double(letters) / Double(text.count) >= 0.6 else { continue }

            let words = text.split(separator: " ").count
            var score = Double(letters) + Double(min(words, 4)) * 2
            if text == text.uppercased() { score += 3 } // pack fronts shout the product name

            if best == nil || score > best!.score {
                best = (score, text)
            }
        }

        return best.map { prettify($0.text) }
    }

    static func prettify(_ text: String) -> String {
        text.lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

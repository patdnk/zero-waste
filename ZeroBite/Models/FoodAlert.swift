//
//  FoodAlert.swift
//  ZeroBite
//
//  A UK Food Standards Agency food alert (product recall or allergy alert), reduced to what
//  the app needs. `FSAAlertResponse` decodes the API's JSON-LD, which is loose about types
//  (a field can be a string, an object with "@id", or an array), into this clean model.
//
//  Contains public sector information licensed under the Open Government Licence v3.0.
//

import Foundation

struct FoodAlert: Codable, Identifiable, Hashable, Sendable {

    enum Kind: String, Codable, Sendable {
        /// Allergy alert: an allergen is missing from or wrong on the label.
        case allergy = "AA"
        /// Product recall information notice.
        case recall = "PRIN"
        /// "Food alert for action": a recall that also needs local authority action.
        case actionRequired = "FAFA"

        var label: String {
            switch self {
            case .allergy: "Allergy alert"
            case .recall, .actionRequired: "Product recall"
            }
        }
    }

    struct Batch: Codable, Hashable, Sendable {
        var batchCode: String?
        var bestBefore: String?
        var useBy: String?
        var lotNumber: String?

        /// Human-readable summary, e.g. "Batch L6232 · Best before May 2027".
        var summary: String {
            // "All batches" / "All use by dates" read on their own; don't prefix them.
            func label(_ prefix: String, _ value: String?) -> String? {
                guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
                return value.lowercased().hasPrefix("all") ? value : "\(prefix) \(value)"
            }
            return [label("Batch", batchCode), label("Lot", lotNumber), label("Use by", useBy), label("Best before", bestBefore)]
                .compactMap { $0 }
                .joined(separator: " · ")
        }

        /// True when the notice covers every batch ("All batches", "All best before dates").
        var coversAllBatches: Bool {
            [batchCode, bestBefore, useBy].compactMap { $0?.lowercased() }.contains { $0.contains("all ") }
        }
    }

    struct Product: Codable, Hashable, Sendable {
        var name: String
        var packSize: String?
        var productCode: String?
        var batches: [Batch]
    }

    let id: String
    let title: String
    var shortTitle: String?
    let kind: Kind
    let created: Date
    var url: URL?
    var business: String?
    var otherBusinesses: [String]
    var products: [Product]
    var allergens: [String]
    var risk: String?
    var consumerAdvice: String?

    var displayTitle: String { shortTitle ?? title }

    /// Businesses named on the notice (manufacturer first, then retailers).
    var businesses: [String] { ([business] + otherBusinesses.map(Optional.some)).compactMap { $0 } }
}

// MARK: - FSA API decoding

/// `GET https://data.food.gov.uk/food-alerts/id.json?_view=full…`
struct FSAAlertResponse: Decodable {
    let items: [FoodAlert]

    private enum CodingKeys: String, CodingKey { case items }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode([RawAlert].self, forKey: .items)
        items = raw.compactMap(\.alert)
    }

    private struct RawAlert: Decodable {
        let notation: String?
        let title: String?
        let shortTitle: String?
        let created: String?
        let type: [Loose]?
        let alertURL: Loose?
        let reportingBusiness: Business?
        let otherBusiness: LooseArray<Business>?
        let problem: [Problem]?
        let productDetails: [RawProduct]?
        let consumerAdvice: String?

        struct Business: Decodable { let commonName: String? }
        struct Problem: Decodable {
            let riskStatement: String?
            let allergen: LooseArray<Loose>?
        }
        struct RawProduct: Decodable {
            let productName: String?
            let packSizeDescription: String?
            let productCode: String?
            let batchDescription: LooseArray<RawBatch>?
        }
        struct RawBatch: Decodable {
            let batchCode: String?
            let bestBeforeDescription: String?
            let useByDescription: String?
            let lotNumber: String?
        }

        var alert: FoodAlert? {
            guard let notation, let title,
                  let created = created.flatMap(FSAAlertResponse.dayFormatter.date(from:))
            else { return nil }
            let kind = type?.lazy.compactMap { $0.value.flatMap { FoodAlert.Kind(rawValue: String($0.split(separator: "/").last ?? "")) } }.first
            guard let kind else { return nil }

            let problems = problem ?? []
            return FoodAlert(
                id: notation,
                title: title,
                shortTitle: shortTitle,
                kind: kind,
                created: created,
                url: alertURL?.value.flatMap(URL.init(string:)),
                business: reportingBusiness?.commonName,
                otherBusinesses: (otherBusiness?.values ?? []).compactMap(\.commonName),
                products: (productDetails ?? []).compactMap { product in
                    guard let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
                    return FoodAlert.Product(
                        name: name,
                        packSize: product.packSizeDescription,
                        productCode: product.productCode,
                        batches: (product.batchDescription?.values ?? []).map {
                            FoodAlert.Batch(batchCode: $0.batchCode, bestBefore: $0.bestBeforeDescription,
                                            useBy: $0.useByDescription, lotNumber: $0.lotNumber)
                        }
                    )
                },
                allergens: Array(Set(problems.flatMap { ($0.allergen?.values ?? []).compactMap(\.label) })).sorted(),
                risk: problems.compactMap(\.riskStatement).first,
                consumerAdvice: consumerAdvice
            )
        }
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/London")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

/// A JSON-LD value that may be a plain string or an object with "@id" and/or "label"
/// (where "label" itself may be a string or an array of strings).
private struct Loose: Decodable {
    let id: String?
    let label: String?

    /// The string form: the plain value, else "@id".
    var value: String? { id ?? label }

    private enum CodingKeys: String, CodingKey {
        case id = "@id"
        case label
    }

    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            id = string
            label = string
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        if let single = try? container.decodeIfPresent(String.self, forKey: .label) {
            label = single
        } else {
            label = (try? container.decodeIfPresent([String].self, forKey: .label))?.first
        }
    }
}

/// A field that is sometimes a single object and sometimes an array of them.
private struct LooseArray<Element: Decodable>: Decodable {
    let values: [Element]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let many = try? container.decode([Element].self) {
            values = many
        } else {
            values = [try container.decode(Element.self)]
        }
    }
}

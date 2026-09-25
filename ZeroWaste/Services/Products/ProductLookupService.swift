//
//  ProductLookupService.swift
//  ZeroWaste
//
//  Resolves a barcode to a product name/category. Backed by the free Open Food Facts API;
//  the protocol lets view models be tested with a stub.
//

import Foundation

protocol ProductLookup: Sendable {
    func lookup(barcode: String) async throws -> ProductInfo?
}

struct OpenFoodFactsLookup: ProductLookup {

    var session: URLSession = .shared

    private struct Response: Decodable {
        struct Product: Decodable {
            let productName: String?
            let brands: String?
            let categoriesTags: [String]?

            private enum CodingKeys: String, CodingKey {
                case productName = "product_name"
                case brands
                case categoriesTags = "categories_tags"
            }
        }
        let status: Int
        let product: Product?
    }

    func lookup(barcode: String) async throws -> ProductInfo? {
        let code = barcode.filter(\.isNumber)
        guard !code.isEmpty,
              var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(code)")
        else { return nil }
        components.queryItems = [URLQueryItem(name: "fields", value: "product_name,brands,categories_tags")]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("ZeroWaste-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == 1, let product = decoded.product,
              let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty
        else { return nil }

        return ProductInfo(
            barcode: code,
            name: name,
            brand: product.brands?.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) },
            category: Self.category(fromTags: product.categoriesTags ?? [])
        )
    }

    /// Maps Open Food Facts category tags (general → specific) to our coarse categories.
    static func category(fromTags tags: [String]) -> FoodCategory? {
        let rules: [(FoodCategory, [String])] = [
            (.dairy, ["dairy", "dairies", "milk", "cheese", "yogurt", "yoghurt", "egg", "butter", "cream"]),
            (.meat, ["meat", "poultry", "chicken", "beef", "pork", "lamb", "sausage", "bacon", "ham"]),
            (.fish, ["fish", "seafood", "salmon", "tuna", "prawn", "shrimp"]),
            (.bakery, ["bread", "bakery", "pastry", "pastries", "cake", "biscuit"]),
            (.grains, ["pasta", "rice", "cereal", "grain", "flour", "noodle"]),
            (.condiments, ["sauce", "condiment", "spread", "dressing", "mayonnaise", "ketchup", "mustard"]),
            (.drinks, ["beverage", "drink", "juice", "water", "soda"]),
            (.fruit, ["fruit"]),
            (.vegetables, ["vegetable", "salad", "legume"]),
        ]
        for tag in tags.reversed() {
            let lower = tag.lowercased()
            for (category, needles) in rules where needles.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return nil
    }
}

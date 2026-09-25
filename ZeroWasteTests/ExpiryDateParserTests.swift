//
//  ExpiryDateParserTests.swift
//  ZeroWasteTests
//

import Foundation
import Testing
@testable import ZeroWaste

struct ExpiryDateParserTests {

    private let now = TestSupport.date(2026, 9, 7)
    private var parser: ExpiryDateParser { ExpiryDateParser(calendar: TestSupport.calendar, referenceDate: now) }

    /// [year, month, day] of a candidate, or [] when there is none.
    private func ymd(_ candidate: DateCandidate?) -> [Int] {
        guard let candidate else { return [] }
        let c = TestSupport.calendar.dateComponents([.year, .month, .day], from: candidate.date)
        return [c.year!, c.month!, c.day!]
    }

    @Test func parsesUKNumericDate() {
        let best = parser.parse(text: "BEST BEFORE 12/09/2026").first
        #expect(ymd(best) == [2026, 9, 12])
    }

    @Test func parsesMonthNameWithTwoDigitYear() {
        let best = parser.parse(text: "USE BY 15 SEP 26").first
        #expect(ymd(best) == [2026, 9, 15])
    }

    @Test func parsesDottedTwoDigitYear() {
        let best = parser.parse(text: "BB 03.10.26").first
        #expect(ymd(best) == [2026, 10, 3])
    }

    @Test func parsesISOAndSwapsObviousMonthFirst() {
        #expect(ymd(parser.parse(text: "2026-11-02").first) == [2026, 11, 2])
        #expect(ymd(parser.parse(text: "09/14/2026").first) == [2026, 9, 14])
    }

    @Test func monthAndYearMeansEndOfMonth() {
        let best = parser.parse(text: "BEST BEFORE END OCT 2026").first
        #expect(ymd(best) == [2026, 10, 31])
    }

    @Test func missingYearAssumesUpcomingOccurrence() {
        // September 2026 now; "05 JAN" must mean January 2027.
        let best = parser.parse(text: "USE BY 05 JAN").first
        #expect(ymd(best) == [2027, 1, 5])
    }

    @Test func keywordLineOutranksPackingDate() {
        let candidates = parser.parse(lines: ["PACKED 01/09/2026", "USE BY 10/09/2026"])
        #expect(candidates.count == 2)
        #expect(ymd(candidates.first) == [2026, 9, 10])
    }

    @Test func keywordOnPreviousLineBoostsDate() {
        let candidates = parser.parse(lines: ["BEST BEFORE", "20 SEP 2026", "LOT 4471 12/08/2026"])
        #expect(ymd(candidates.first) == [2026, 9, 20])
    }

    @Test func ignoresBatchCodesAndImpossibleDates() {
        #expect(parser.parse(text: "LOT 123456").isEmpty)
        #expect(parser.parse(text: "L2026091 4").isEmpty)
        #expect(parser.parse(text: "31/02/2026").isEmpty)
        #expect(parser.parse(text: "1.136L").isEmpty)
    }

    @Test func compactDigitsOnlyCountWithKeyword() {
        #expect(parser.parse(text: "120926").isEmpty)
        #expect(ymd(parser.parse(text: "EXP 120926").first) == [2026, 9, 12])
    }

    @Test func rejectsYearsFarOutsideRange() {
        #expect(parser.parse(text: "USE BY 12/09/1999").isEmpty)
        #expect(parser.parse(text: "USE BY 12/09/2099").isEmpty)
    }

    @Test func dedupesSameDayKeepingHighestConfidence() {
        let candidates = parser.parse(lines: ["12/09/2026", "USE BY 12 SEP 2026"])
        #expect(candidates.count == 1)
        #expect(candidates[0].sourceLine == "USE BY 12 SEP 2026")
    }
}

struct ProductNameGuesserTests {

    @Test func picksTheProductLineNotTheRetailerOrDate() {
        let lines = ["TESCO", "SEMI SKIMMED MILK", "USE BY 12 SEP", "2 PINTS 1.136L", "Keep refrigerated"]
        #expect(ProductNameGuesser.guess(from: lines) == "Semi Skimmed Milk")
    }

    @Test func returnsNilWhenNothingLooksLikeAName() {
        #expect(ProductNameGuesser.guess(from: ["12/09/2026", "500g", "www.example.com"]) == nil)
    }
}

struct LabelScannerTests {

    @Test func analyseCombinesTextBarcodeAndDates() {
        let now = TestSupport.date(2026, 9, 7)
        let result = LabelScanner.analyse(lines: ["GREEK YOGURT", "USE BY 14 SEP 2026"], barcode: "5000000000000", now: now)
        #expect(result.barcode == "5000000000000")
        #expect(result.suggestedName == "Greek Yogurt")
        #expect(result.bestCandidate != nil)
        #expect(!result.isEmpty)
    }
}

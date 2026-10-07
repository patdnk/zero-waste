//
//  ExpiryDateParser.swift
//  ZeroBite
//
//  Finds best-before / use-by dates in OCR'd label text. Pure and synchronous so it is
//  fully unit-testable. UK/EU day-month-year ordering is assumed for ambiguous numerics.
//

import Foundation

struct ExpiryDateParser: Sendable {

    var calendar: Calendar
    var referenceDate: Date

    init(calendar: Calendar = .current, referenceDate: Date = .now) {
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    // MARK: - Vocabulary

    /// Words that mark a line as being about the expiry date.
    static let keywordRegex = try! NSRegularExpression(
        pattern: #"\b(best before end|best before|best by|bbe|bb|use by|use before|expiry|expires|expire|exp|display until|sell by|consume by|eat by)(?![a-z])"#,
        options: [.caseInsensitive]
    )

    /// Words that mark a line as a packing / manufacture date (not what we want).
    static let manufactureRegex = try! NSRegularExpression(
        pattern: #"\b(packed on|packed|manufactured|mfg|mfd|prod\.?|production|batch|lot)(?![a-z])"#,
        options: [.caseInsensitive]
    )

    static let monthNames = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

    static func containsKeyword(_ line: String) -> Bool {
        keywordRegex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) != nil
    }

    // MARK: - Patterns

    private enum Kind { case ymd, dmy, dMonY, monDY, dMon, monY, mY, compact8, compact6 }

    private struct Pattern {
        let kind: Kind
        let regex: NSRegularExpression
        let baseConfidence: Double
    }

    private static let patterns: [Pattern] = {
        func rx(_ pattern: String) -> NSRegularExpression {
            try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }
        let month = #"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?"#
        let notDigitBefore = #"(?<!\d)"#
        let notDigitAfter = #"(?!\d)"#
        return [
            Pattern(kind: .ymd, regex: rx(notDigitBefore + #"(\d{4})[./-](\d{1,2})[./-](\d{1,2})"# + notDigitAfter), baseConfidence: 0.8),
            Pattern(kind: .dMonY, regex: rx(notDigitBefore + #"(\d{1,2})(?:st|nd|rd|th)?\s*[-./]?\s*"# + month + #"\s*[-./,']?\s*(\d{2,4})"# + notDigitAfter), baseConfidence: 0.85),
            Pattern(kind: .monDY, regex: rx(#"\b"# + month + #"\s*(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{2,4})"# + notDigitAfter), baseConfidence: 0.8),
            Pattern(kind: .dmy, regex: rx(notDigitBefore + #"(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})"# + notDigitAfter), baseConfidence: 0.75),
            Pattern(kind: .monY, regex: rx(#"\b"# + month + #"\s*[-./,']?\s*(\d{4})"# + notDigitAfter), baseConfidence: 0.6),
            Pattern(kind: .dMon, regex: rx(notDigitBefore + #"(\d{1,2})(?:st|nd|rd|th)?\s*[-./]?\s*"# + month + #"\b"#), baseConfidence: 0.5),
            Pattern(kind: .mY, regex: rx(#"(?<![\d./-])"# + #"(\d{1,2})[./-](\d{4})"# + notDigitAfter), baseConfidence: 0.55),
            Pattern(kind: .compact8, regex: rx(notDigitBefore + #"(\d{2})(\d{2})(\d{4})"# + notDigitAfter), baseConfidence: 0.3),
            Pattern(kind: .compact6, regex: rx(notDigitBefore + #"(\d{2})(\d{2})(\d{2})"# + notDigitAfter), baseConfidence: 0.25),
        ]
    }()

    // MARK: - Parsing

    func parse(text: String) -> [DateCandidate] {
        parse(lines: text.components(separatedBy: .newlines))
    }

    /// Returns candidates sorted by confidence (desc), then date (asc), de-duplicated per day.
    func parse(lines rawLines: [String]) -> [DateCandidate] {
        let lines = rawLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var found: [DateCandidate] = []

        for (index, line) in lines.enumerated() {
            let ns = line as NSString
            let fullRange = NSRange(location: 0, length: ns.length)
            let hasKeyword = Self.containsKeyword(line)
            let previousHasKeyword = index > 0 && Self.containsKeyword(lines[index - 1])
            let looksLikeManufacture = Self.manufactureRegex.firstMatch(in: line, range: fullRange) != nil
            var consumed: [NSRange] = []

            for pattern in Self.patterns {
                // Bare digit runs are only worth considering when the line says "use by" etc.
                if (pattern.kind == .compact6 || pattern.kind == .compact8) && !hasKeyword { continue }

                for match in pattern.regex.matches(in: line, range: fullRange) {
                    if consumed.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) { continue }
                    consumed.append(match.range)
                    guard let date = makeDate(kind: pattern.kind, match: match, in: ns) else { continue }

                    var confidence = pattern.baseConfidence
                    if hasKeyword { confidence += 0.2 } else if previousHasKeyword { confidence += 0.15 }
                    if looksLikeManufacture { confidence -= 0.3 }

                    let days = calendar.dateComponents(
                        [.day],
                        from: calendar.startOfDay(for: referenceDate),
                        to: calendar.startOfDay(for: date)
                    ).day ?? 0
                    if days < -365 { confidence -= 0.3 } else if days < -30 { confidence -= 0.1 }
                    if days > 365 * 5 { confidence -= 0.15 }

                    found.append(DateCandidate(
                        date: date,
                        matchedText: ns.substring(with: match.range),
                        sourceLine: line,
                        confidence: min(1, max(0, confidence))
                    ))
                }
            }
        }

        var bestPerDay: [Date: DateCandidate] = [:]
        for candidate in found {
            let day = calendar.startOfDay(for: candidate.date)
            if let existing = bestPerDay[day], existing.confidence >= candidate.confidence { continue }
            bestPerDay[day] = candidate
        }

        return bestPerDay.values.sorted {
            if $0.confidence != $1.confidence { return $0.confidence > $1.confidence }
            return $0.date < $1.date
        }
    }

    func bestDate(in lines: [String]) -> Date? {
        parse(lines: lines).first?.date
    }

    // MARK: - Date construction

    private func makeDate(kind: Kind, match: NSTextCheckingResult, in ns: NSString) -> Date? {
        func group(_ i: Int) -> String {
            let range = match.range(at: i)
            return range.location == NSNotFound ? "" : ns.substring(with: range)
        }
        func int(_ i: Int) -> Int? { Int(group(i)) }
        func monthName(_ i: Int) -> Int? {
            let prefix = String(group(i).lowercased().prefix(3))
            return Self.monthNames.firstIndex(of: prefix).map { $0 + 1 }
        }
        func year(_ i: Int) -> Int? {
            guard let value = int(i) else { return nil }
            return value < 100 ? 2000 + value : value
        }

        var day: Int?
        var month: Int?
        var yearValue: Int?
        var endOfMonth = false
        var yearInferred = false

        switch kind {
        case .ymd:
            yearValue = year(1); month = int(2); day = int(3)
        case .dmy:
            day = int(1); month = int(2); yearValue = year(3)
            // "09/14/2026" can only be month-first; "12/09/2026" is read day-first (UK).
            if let d = day, let m = month, d <= 12, m > 12 { swap(&day, &month) }
        case .dMonY:
            day = int(1); month = monthName(2); yearValue = year(3)
        case .monDY:
            month = monthName(1); day = int(2); yearValue = year(3)
        case .dMon:
            day = int(1); month = monthName(2); yearInferred = true
        case .monY:
            month = monthName(1); yearValue = year(2); endOfMonth = true
        case .mY:
            month = int(1); yearValue = year(2); endOfMonth = true
        case .compact8, .compact6:
            day = int(1); month = int(2); yearValue = year(3)
        }

        guard let m = month, (1...12).contains(m) else { return nil }
        let referenceYear = calendar.component(.year, from: referenceDate)
        if yearInferred { yearValue = referenceYear }
        guard let y = yearValue, (referenceYear - 2 ... referenceYear + 15).contains(y) else { return nil }

        var components = DateComponents(year: y, month: m, hour: 12)
        if endOfMonth {
            guard let first = calendar.date(from: DateComponents(year: y, month: m, day: 1)),
                  let range = calendar.range(of: .day, in: .month, for: first) else { return nil }
            components.day = range.count
        } else {
            guard let d = day, (1...31).contains(d) else { return nil }
            components.day = d
        }

        guard var date = calendar.date(from: components) else { return nil }
        // Reject impossible dates that Calendar would otherwise roll forward (e.g. 31 Feb).
        if calendar.component(.day, from: date) != components.day { return nil }

        if yearInferred, let cutoff = calendar.date(byAdding: .day, value: -60, to: referenceDate), date < cutoff {
            guard let next = calendar.date(byAdding: .year, value: 1, to: date) else { return nil }
            date = next
        }
        return date
    }
}

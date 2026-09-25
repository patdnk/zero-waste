//
//  TextRecognitionService.swift
//  ZeroWaste
//
//  On-device OCR and barcode detection using the Swift Vision API (iOS 18+).
//

import Foundation
import Vision

enum TextRecognitionService {

    /// Recognised text lines, ordered top-to-bottom as they appear in the image.
    static func recognizeLines(in imageData: Data) async throws -> [String] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [Locale.Language(identifier: "en-GB")]

        let observations = try await request.perform(on: imageData)
        // Vision uses a bottom-left origin, so larger y is higher on the page.
        let sorted = observations.sorted { $0.boundingBox.cgRect.midY > $1.boundingBox.cgRect.midY }
        return sorted.compactMap { $0.topCandidates(1).first?.string }
    }

    /// Payload strings of any retail barcodes in the image (EAN/UPC first).
    static func detectBarcodes(in imageData: Data) async throws -> [String] {
        var request = DetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce, .code128, .qr]
        let observations = try await request.perform(on: imageData)
        return observations.compactMap(\.payloadString)
    }
}

/// Turns an image of a label into a `ScanResult` (text + barcode + parsed dates).
enum LabelScanner {

    static func scan(imageData: Data, now: Date = .now) async throws -> ScanResult {
        async let linesTask = TextRecognitionService.recognizeLines(in: imageData)
        async let barcodesTask = TextRecognitionService.detectBarcodes(in: imageData)

        let lines = try await linesTask
        let barcodes = (try? await barcodesTask) ?? []
        return analyse(lines: lines, barcode: barcodes.first, now: now)
    }

    /// Shared by the photo path and the live scanner: parse text we've already read.
    static func analyse(lines: [String], barcode: String?, now: Date = .now) -> ScanResult {
        let parser = ExpiryDateParser(referenceDate: now)
        return ScanResult(
            lines: lines,
            barcode: barcode,
            candidates: parser.parse(lines: lines),
            suggestedName: ProductNameGuesser.guess(from: lines)
        )
    }
}

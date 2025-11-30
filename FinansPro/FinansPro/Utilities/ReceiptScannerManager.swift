//
//  ReceiptScannerManager.swift
//  FinansPro
//
//  Fiş/fatura OCR tarama yöneticisi
//  Vision framework kullanarak fotoğraflardan metin çıkarır
//

import UIKit
import Vision
import VisionKit

class ReceiptScannerManager: ObservableObject {
    static let shared = ReceiptScannerManager()

    @Published var isScanning = false
    @Published var recognizedText = ""
    @Published var error: Error?

    private init() {}

    /// Fotoğraftan metin tanır
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(ScanError.invalidImage))
            return
        }

        isScanning = true
        recognizedText = ""

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isScanning = false

                if let error = error {
                    self.error = error
                    completion(.failure(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(.failure(ScanError.noTextFound))
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")

                self.recognizedText = fullText

                if fullText.isEmpty {
                    completion(.failure(ScanError.noTextFound))
                } else {
                    completion(.success(fullText))
                }
            }
        }

        // Türkçe ve İngilizce dil desteği
        request.recognitionLanguages = ["tr-TR", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.isScanning = false
                self.error = error
                completion(.failure(error))
            }
        }
    }

    /// Fiş/fatura mı kontrol eder (basit heuristik)
    func isReceiptOrInvoice(text: String) -> Bool {
        let lowercased = text.lowercased()

        // Fiş/fatura belirten kelimeler
        let receiptKeywords = [
            "fiş", "fatura", "makbuz", "receipt", "invoice",
            "toplam", "total", "tutar", "amount",
            "kdv", "vat", "tax", "vergi",
            "ödeme", "payment", "ödendi", "paid"
        ]

        let matchCount = receiptKeywords.filter { lowercased.contains($0) }.count

        // En az 2 anahtar kelime varsa fiş/fatura olarak kabul et
        return matchCount >= 2
    }
}

// MARK: - Hata Tipleri
enum ScanError: LocalizedError {
    case invalidImage
    case noTextFound
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Geçersiz görsel. Lütfen başka bir fotoğraf deneyin."
        case .noTextFound:
            return "Fotoğrafta metin bulunamadı. Lütfen daha net bir fotoğraf çekin."
        case .parsingFailed:
            return "Fiş bilgileri okunamadı. Lütfen manuel olarak girin."
        }
    }
}

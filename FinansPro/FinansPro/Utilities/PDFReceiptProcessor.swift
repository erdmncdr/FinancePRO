//
//  PDFReceiptProcessor.swift
//  FinansPro
//
//  PDF fatura/fiş işleyicisi
//  PDFKit kullanarak PDF'lerden metin çıkarır
//

import Foundation
import PDFKit
import UIKit

class PDFReceiptProcessor {
    static let shared = PDFReceiptProcessor()

    private init() {}

    /// PDF'den metin çıkarır
    func extractText(from pdfURL: URL) -> Result<String, Error> {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return .failure(PDFError.invalidPDF)
        }

        var fullText = ""

        // Tüm sayfaları işle
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }

        if fullText.isEmpty {
            return .failure(PDFError.noTextFound)
        }

        return .success(fullText)
    }

    /// PDF'den Data çıkarır
    func extractText(from pdfData: Data) -> Result<String, Error> {
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return .failure(PDFError.invalidPDF)
        }

        var fullText = ""

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }

        if fullText.isEmpty {
            return .failure(PDFError.noTextFound)
        }

        return .success(fullText)
    }

    /// PDF'in ilk sayfasını thumbnail olarak çıkarır (rotasyon düzeltmeli)
    func generateThumbnail(from pdfURL: URL, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        // PDF sayfasının rotasyonunu dikkate al
        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        // Rotation'a göre boyutları ayarla
        var thumbnailSize = size
        if rotation == 90 || rotation == 270 {
            thumbnailSize = CGSize(width: size.height, height: size.width)
        }

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))

            // Context'i doğru şekilde ayarla
            context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)

            // Ölçekleme
            let scaleX = thumbnailSize.width / pageRect.width
            let scaleY = thumbnailSize.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // Merkezleme
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (thumbnailSize.width - scaledWidth) / 2
            let offsetY = (thumbnailSize.height - scaledHeight) / 2

            context.cgContext.translateBy(x: offsetX, y: offsetY)
            context.cgContext.scaleBy(x: scale, y: scale)

            // PDF sayfasını çiz
            firstPage.draw(with: .mediaBox, to: context.cgContext)
        }

        return thumbnail
    }

    /// PDF'in ilk sayfasını Data'dan thumbnail olarak çıkarır (rotasyon düzeltmeli)
    func generateThumbnail(from pdfData: Data, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        // PDF sayfasının rotasyonunu dikkate al
        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        // Rotation'a göre boyutları ayarla
        var thumbnailSize = size
        if rotation == 90 || rotation == 270 {
            thumbnailSize = CGSize(width: size.height, height: size.width)
        }

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))

            // Context'i doğru şekilde ayarla
            context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)

            // Ölçekleme
            let scaleX = thumbnailSize.width / pageRect.width
            let scaleY = thumbnailSize.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // Merkezleme
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (thumbnailSize.width - scaledWidth) / 2
            let offsetY = (thumbnailSize.height - scaledHeight) / 2

            context.cgContext.translateBy(x: offsetX, y: offsetY)
            context.cgContext.scaleBy(x: scale, y: scale)

            // PDF sayfasını çiz
            firstPage.draw(with: .mediaBox, to: context.cgContext)
        }

        return thumbnail
    }
}

// MARK: - PDF Hata Tipleri
enum PDFError: LocalizedError {
    case invalidPDF
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Geçersiz PDF dosyası. Lütfen başka bir dosya deneyin."
        case .noTextFound:
            return "PDF'de metin bulunamadı. Görüntü tabanlı PDF olabilir."
        }
    }
}

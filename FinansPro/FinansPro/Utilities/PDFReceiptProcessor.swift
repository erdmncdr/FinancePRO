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

    /// PDF'in ilk sayfasını thumbnail olarak çıkarır (rotasyon düzeltmeli v2)
    func generateThumbnail(from pdfURL: URL, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        // PDF sayfasının rotasyonunu al
        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        print("🔄 PDF Rotation: \(rotation)°")
        print("📐 PDF Page Rect: \(pageRect)")

        // Rotation'a göre hedef boyut belirle
        var targetSize = size
        if rotation == 90 || rotation == 270 {
            targetSize = CGSize(width: size.height, height: size.width)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: targetSize))

            let ctx = context.cgContext
            ctx.saveGState()

            // Koordinat sistemini ayarla (PDF koordinatları ters)
            ctx.translateBy(x: 0, y: targetSize.height)
            ctx.scaleBy(x: 1.0, y: -1.0)

            // Ölçekleme hesapla
            let scaleX = targetSize.width / pageRect.width
            let scaleY = targetSize.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // Merkezleme hesapla
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (targetSize.width - scaledWidth) / 2
            let offsetY = (targetSize.height - scaledHeight) / 2

            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)

            // Rotation varsa, merkez etrafında döndür
            if rotation != 0 {
                let centerX = pageRect.width / 2
                let centerY = pageRect.height / 2
                ctx.translateBy(x: centerX, y: centerY)
                ctx.rotate(by: CGFloat(rotation) * .pi / 180.0)
                ctx.translateBy(x: -centerX, y: -centerY)
            }

            // PDF sayfasını çiz
            firstPage.draw(with: .mediaBox, to: ctx)

            ctx.restoreGState()
        }

        print("✅ Thumbnail oluşturuldu: \(targetSize)")
        return thumbnail
    }

    /// PDF'in ilk sayfasını Data'dan thumbnail olarak çıkarır (rotasyon düzeltmeli v2)
    func generateThumbnail(from pdfData: Data, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        // PDF sayfasının rotasyonunu al
        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        print("🔄 PDF Rotation: \(rotation)°")
        print("📐 PDF Page Rect: \(pageRect)")

        // Rotation'a göre hedef boyut belirle
        var targetSize = size
        if rotation == 90 || rotation == 270 {
            targetSize = CGSize(width: size.height, height: size.width)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: targetSize))

            let ctx = context.cgContext
            ctx.saveGState()

            // Koordinat sistemini ayarla (PDF koordinatları ters)
            ctx.translateBy(x: 0, y: targetSize.height)
            ctx.scaleBy(x: 1.0, y: -1.0)

            // Ölçekleme hesapla
            let scaleX = targetSize.width / pageRect.width
            let scaleY = targetSize.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // Merkezleme hesapla
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (targetSize.width - scaledWidth) / 2
            let offsetY = (targetSize.height - scaledHeight) / 2

            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)

            // Rotation varsa, merkez etrafında döndür
            if rotation != 0 {
                let centerX = pageRect.width / 2
                let centerY = pageRect.height / 2
                ctx.translateBy(x: centerX, y: centerY)
                ctx.rotate(by: CGFloat(rotation) * .pi / 180.0)
                ctx.translateBy(x: -centerX, y: -centerY)
            }

            // PDF sayfasını çiz
            firstPage.draw(with: .mediaBox, to: ctx)

            ctx.restoreGState()
        }

        print("✅ Thumbnail oluşturuldu: \(targetSize)")
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

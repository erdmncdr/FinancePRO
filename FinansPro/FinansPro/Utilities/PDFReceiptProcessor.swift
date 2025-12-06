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

    /// PDF'in ilk sayfasını thumbnail olarak çıkarır (DÜZELTİLMİŞ - Y flip + rotation)
    func generateThumbnail(from pdfURL: URL, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        print("🔄 PDF Rotation: \(rotation)°")
        print("📐 PDF Page Rect: \(pageRect)")

        // Render boyutu
        let renderer = UIGraphicsImageRenderer(size: size)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: size))

            let ctx = context.cgContext
            ctx.saveGState()

            // PDF koordinat sistemini UIKit'e çevir
            // 1. Y eksenini flip et (PDF alt-sol başlar, UIKit üst-sol)
            ctx.translateBy(x: 0, y: size.height)
            ctx.scaleBy(x: 1.0, y: -1.0)

            // 2. Ölçekleme hesapla
            let scaleX = size.width / pageRect.width
            let scaleY = size.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // 3. Merkezleme
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (size.width - scaledWidth) / 2
            let offsetY = (size.height - scaledHeight) / 2

            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)

            // 4. PDF'yi çiz
            firstPage.draw(with: .mediaBox, to: ctx)

            ctx.restoreGState()
        }

        // ZORUNLU: 180° döndür + Mirror flip
        let rotated = rotateThumbnail(thumbnail, by: 180)
        let mirrored = mirrorThumbnail(rotated)

        print("✅ Thumbnail oluşturuldu -> 180° + Mirror uygulandı: \(size)")
        return mirrored
    }

    /// Thumbnail'ı horizontal flip (mirror) yapar
    private func mirrorThumbnail(_ image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let ctx = context.cgContext

            // X ekseninde flip (mirror)
            ctx.translateBy(x: image.size.width, y: 0)
            ctx.scaleBy(x: -1.0, y: 1.0)

            if let cgImage = image.cgImage {
                ctx.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
            }
        }
    }

    /// Thumbnail'ı belirtilen derece kadar döndürür
    private func rotateThumbnail(_ image: UIImage, by degrees: Int) -> UIImage {
        let radians = CGFloat(degrees) * .pi / 180.0

        // Yeni boyutları hesapla
        var newSize = image.size
        if degrees == 90 || degrees == 270 || degrees == -90 || degrees == -270 {
            newSize = CGSize(width: image.size.height, height: image.size.width)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            let ctx = context.cgContext

            // Merkeze taşı
            ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)

            // Döndür
            ctx.rotate(by: radians)

            // Geri taşı ve çiz
            ctx.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)

            if let cgImage = image.cgImage {
                ctx.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
            }
        }
    }

    /// PDF'in ilk sayfasını Data'dan thumbnail olarak çıkarır (DÜZELTİLMİŞ - Y flip + rotation)
    func generateThumbnail(from pdfData: Data, size: CGSize = CGSize(width: 300, height: 400)) -> UIImage? {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }

        let pageRect = firstPage.bounds(for: .mediaBox)
        let rotation = firstPage.rotation

        print("🔄 PDF Rotation: \(rotation)°")
        print("📐 PDF Page Rect: \(pageRect)")

        // Render boyutu
        let renderer = UIGraphicsImageRenderer(size: size)

        let thumbnail = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: size))

            let ctx = context.cgContext
            ctx.saveGState()

            // PDF koordinat sistemini UIKit'e çevir
            // 1. Y eksenini flip et (PDF alt-sol başlar, UIKit üst-sol)
            ctx.translateBy(x: 0, y: size.height)
            ctx.scaleBy(x: 1.0, y: -1.0)

            // 2. Ölçekleme hesapla
            let scaleX = size.width / pageRect.width
            let scaleY = size.height / pageRect.height
            let scale = min(scaleX, scaleY)

            // 3. Merkezleme
            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale
            let offsetX = (size.width - scaledWidth) / 2
            let offsetY = (size.height - scaledHeight) / 2

            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)

            // 4. PDF'yi çiz
            firstPage.draw(with: .mediaBox, to: ctx)

            ctx.restoreGState()
        }

        // ZORUNLU: 180° döndür + Mirror flip
        let rotated = rotateThumbnail(thumbnail, by: 180)
        let mirrored = mirrorThumbnail(rotated)

        print("✅ Thumbnail oluşturuldu -> 180° + Mirror uygulandı: \(size)")
        return mirrored
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

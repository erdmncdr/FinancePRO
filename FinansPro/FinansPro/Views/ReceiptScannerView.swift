//
//  ReceiptScannerView.swift
//  FinansPro
//
//  Fiş/fatura tarama ekranı
//  Kamera, galeri ve PDF desteği
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var scanner = ReceiptScannerManager.shared

    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPDFPicker = false
    @State private var isProcessing = false
    @State private var parsedReceipt: ParsedReceipt?
    @State private var showingReview = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isPDFMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 30) {
                    // Başlık
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Fiş/Fatura Tara")
                            .font(Theme.largeTitle)
                            .fontWeight(.bold)

                        Text("Kamera veya galeriden fotoğraf seçerek fiş bilgilerinizi otomatik olarak okutun")
                            .font(Theme.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Seçilen fotoğraf önizlemesi
                    if let image = selectedImage {
                        VStack(spacing: 16) {
                            Text("Seçilen Fotoğraf")
                                .font(Theme.headline)
                                .foregroundColor(.secondary)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                                .padding(.horizontal)

                            if isProcessing {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)

                                    Text("Fiş okunuyor...")
                                        .font(Theme.callout)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else {
                                Button(action: processImage) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Fişi Oku")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer()

                    // Butonlar
                    if selectedImage == nil {
                        VStack(spacing: 16) {
                            // Kamera butonu
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                showingCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Kamera ile Çek")
                                            .font(Theme.headline)
                                            .fontWeight(.semibold)

                                        Text("Yeni fiş fotoğrafı çek")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }

                            // Galeri butonu
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 24))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Galeriden Seç")
                                            .font(Theme.headline)
                                            .fontWeight(.semibold)

                                        Text("Mevcut fotoğrafları kullan")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }

                            // PDF butonu
                            Button(action: {
                                HapticManager.shared.impact(style: .medium)
                                showingPDFPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 24))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("PDF Fatura Seç")
                                            .font(Theme.headline)
                                            .fontWeight(.semibold)

                                        Text("PDF dosyasından bilgi oku")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }

                            // Ayraç
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)

                                Text("YA DA")
                                    .font(Theme.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)

                            // Toplu tarama butonu
                            NavigationLink(destination: BatchReceiptScannerView()) {
                                HStack {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, .pink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Toplu Tarama")
                                            .font(Theme.headline)
                                            .fontWeight(.semibold)

                                        Text("Birden fazla fiş/fatura tara")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.1), .pink.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.orange, .pink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    } else {
                        Button(action: {
                            selectedImage = nil
                            parsedReceipt = nil
                        }) {
                            Text("Fotoğrafı Değiştir")
                                .font(Theme.callout)
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPDFPicker) {
                PDFDocumentPicker(onPDFSelected: processPDF)
            }
            .sheet(isPresented: $showingReview) {
                if let receipt = parsedReceipt, let image = selectedImage {
                    ScannedReceiptReviewView(
                        parsedReceipt: receipt,
                        receiptImage: image,
                        onSave: {
                            dismiss()
                        }
                    )
                }
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Bir hata oluştu")
            }
        }
    }

    private func processImage() {
        guard let image = selectedImage else { return }

        isProcessing = true
        HapticManager.shared.impact(style: .medium)

        scanner.recognizeText(from: image) { result in
            isProcessing = false

            switch result {
            case .success(let text):
                // Metin başarıyla tanındı, parse et
                let receipt = ReceiptParser.shared.parse(text: text)

                // Fiş kontrolü
                if !scanner.isReceiptOrInvoice(text: text) {
                    errorMessage = "Bu bir fiş veya fatura gibi görünmüyor. Yine de devam edebilirsiniz."
                    showingError = true
                }

                parsedReceipt = receipt
                HapticManager.shared.success()
                showingReview = true

            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.shared.error()
            }
        }
    }

    private func processPDF(url: URL) {
        isProcessing = true
        isPDFMode = true
        HapticManager.shared.impact(style: .medium)

        DispatchQueue.global(qos: .userInitiated).async {
            // Önce thumbnail oluştur (önizleme için)
            var thumbnail: UIImage?
            if let pdfThumbnail = PDFReceiptProcessor.shared.generateThumbnail(from: url) {
                thumbnail = pdfThumbnail
                DispatchQueue.main.async {
                    self.selectedImage = pdfThumbnail
                }
            }

            // Metin çıkarma
            let textResult = PDFReceiptProcessor.shared.extractText(from: url)

            var finalText = ""

            switch textResult {
            case .success(let text):
                print("✅ PDF'den metin çıkarıldı: \(text.prefix(100))...")
                finalText = text

            case .failure(let error):
                print("⚠️ PDF'den metin çıkarılamadı: \(error.localizedDescription)")

                // Metin yoksa, thumbnail'ı OCR ile oku
                if let thumbnail = thumbnail {
                    print("🔍 OCR ile okuma başlatılıyor...")
                    let semaphore = DispatchSemaphore(value: 0)

                    ReceiptScannerManager.shared.recognizeText(from: thumbnail) { ocrResult in
                        switch ocrResult {
                        case .success(let ocrText):
                            print("✅ OCR başarılı: \(ocrText.prefix(100))...")
                            finalText = ocrText
                        case .failure(let ocrError):
                            print("❌ OCR başarısız: \(ocrError.localizedDescription)")
                        }
                        semaphore.signal()
                    }

                    semaphore.wait()
                }
            }

            DispatchQueue.main.async {
                self.isProcessing = false

                if finalText.isEmpty {
                    self.errorMessage = "PDF'den ve OCR'dan metin çıkarılamadı. Lütfen daha net bir PDF deneyin."
                    self.showingError = true
                    HapticManager.shared.error()
                    return
                }

                // Metni parse et
                let receipt = ReceiptParser.shared.parse(text: finalText)

                self.parsedReceipt = receipt
                HapticManager.shared.success()
                self.showingReview = true
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Görsel yönlendirmesini düzelt
                parent.image = uiImage.fixedOrientation()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - PDF Document Picker
struct PDFDocumentPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var onPDFSelected: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PDFDocumentPicker

        init(_ parent: PDFDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                // Security-scoped resource'a erişim başlat
                guard url.startAccessingSecurityScopedResource() else {
                    parent.dismiss()
                    return
                }

                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                parent.onPDFSelected(url)
            }
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIImage Extension
extension UIImage {
    /// Görsel orientasyonunu düzeltir (EXIF verilerinden)
    func fixedOrientation() -> UIImage {
        // Eğer zaten doğru yönlendirme varsa, aynı görseli döndür
        if imageOrientation == .up {
            return self
        }

        // Görsel context'i oluştur
        guard let cgImage = cgImage else { return self }

        let width = size.width
        let height = size.height

        var transform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: .pi)

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: .pi / 2)

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -.pi / 2)

        case .up, .upMirrored:
            break

        @unknown default:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .up, .down, .left, .right:
            break

        @unknown default:
            break
        }

        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(width),
                height: Int(height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }

        context.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))

        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        guard let newCGImage = context.makeImage() else { return self }

        return UIImage(cgImage: newCGImage)
    }
}

#Preview {
    ReceiptScannerView()
}

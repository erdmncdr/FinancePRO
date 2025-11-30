import SwiftUI
import Vision
import VisionKit
import UniformTypeIdentifiers
import PDFKit
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appearanceManager: AppearanceManager

    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingDocumentPicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isProcessing = false
    @State private var parsed: ParsedReceiptResult? = nil
    @State private var errorMessage: String? = nil
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Duruma göre içerik
                    if let image = capturedImage {
                        // Önizleme
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .cornerRadius(12)
                            .shadow(radius: 6)
                            .padding(.horizontal)
                    } else {
                        // Kamera illüstrasyonu
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryGradient.opacity(0.2))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Theme.primaryGradient)
                            }
                            Text("Fiş veya faturayı fotoğraflayın")
                                .font(Theme.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }

                    if isProcessing {
                        ProgressView("Metinler okunuyor…")
                            .padding()
                    }

                    if let parsed = parsed {
                        ResultCard(parsed: parsed)
                            .padding(.horizontal)
                    }

                    if capturedImage != nil {
                        HStack {
                            Label("Tarih", systemImage: "calendar")
                                .font(Theme.body)
                            Spacer()
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let error = errorMessage {
                        VStack(spacing: 8) {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                            Text("Lütfen tekrar çekin.")
                                .font(Theme.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Alt eylemler: Çek / Kaydet ve alternatif kaynaklar
                    VStack(spacing: 12) {
                        if parsed != nil {
                            Button(action: saveExpense) {
                                HStack { Image(systemName: "checkmark.circle.fill"); Text("Kaydet") }
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                        }

                        // Ortada büyük fotoğraf çek butonu
                        HStack {
                            Spacer(minLength: 0)
                            Button(action: { startCapture() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera")
                                    Text("Fotoğraf Çek")
                                }
                                .frame(maxWidth: 360)
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                            .disabled(isProcessing)
                            Spacer(minLength: 0)
                        }

                        // Galeri ve Dosyalar seçenekleri
                        HStack(spacing: 12) {
                            Button(action: { showingPhotoLibrary = true }) {
                                HStack { Image(systemName: "photo.on.rectangle"); Text("Galeriden Seç") }
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(OutlineGradientButtonStyle())

                            Button(action: { showingDocumentPicker = true }) {
                                HStack { Image(systemName: "doc"); Text("Dosyadan Yükle") }
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(OutlineGradientButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Fiş Tara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .toolbarColorScheme(appearanceManager.colorScheme, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .sheet(isPresented: $showingCamera) {
                StandardCameraPicker { image in
                    showingCamera = false
                    guard let image else { return }
                    self.capturedImage = image
                    recognizeText(in: image)
                }
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker { image in
                    showingPhotoLibrary = false
                    guard let image else { return }
                    self.capturedImage = image
                    recognizeText(in: image)
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentImagePicker { image in
                    showingDocumentPicker = false
                    guard let image else { return }
                    self.capturedImage = image
                    recognizeText(in: image)
                }
            }
        }
        .preferredColorScheme(appearanceManager.colorScheme)
    }

    private func startCapture() {
        errorMessage = nil
        parsed = nil
        capturedImage = nil
        showingCamera = true
    }

    private func recognizeText(in image: UIImage) {
        isProcessing = true
        errorMessage = nil
        parsed = nil

        // Görüntüyü OCR öncesi iyileştir
        let sourceCG = image.cgImage
        let processedCG = preprocessedCGImage(from: image)
        guard let cgImage = processedCG ?? sourceCG else {
            isProcessing = false
            errorMessage = "Görüntü işlenemedi."
            return
        }

        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNRecognizeTextRequest { request, error in
            var observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            var lines: [String] = observations.compactMap { $0.topCandidates(1).first?.string }

            func handleResult() {
                let normalizedFullText = lines.joined(separator: "\n")
                    .precomposedStringWithCanonicalMapping
                    .replacingOccurrences(of: "I\u{0307}", with: "İ")
                    .replacingOccurrences(of: "i\u{0307}", with: "i")

                let amount = ReceiptRegexExtractor.bestAmountString(from: normalizedFullText)
                let date = ReceiptRegexExtractor.firstMatch(in: normalizedFullText, pattern: #"(\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b)"#)
                let title = guessTitle(from: normalizedFullText)
                let category = guessCategory(from: normalizedFullText)

                let result = ParsedReceiptResult(title: title, amountString: amount, dateString: date, rawText: normalizedFullText, suggestedCategory: category)

                DispatchQueue.main.async {
                    self.isProcessing = false
                    if amount == nil { self.errorMessage = "Tutar algılanamadı." } else { self.errorMessage = nil }
                    if let ds = date, let d = self.parseDate(from: ds) { self.selectedDate = d } else { self.selectedDate = Date() }
                    self.parsed = result
                }
            }

            // Eğer zayıf sonuç ise ikinci bir pass dene
            if lines.count < 3 || ReceiptRegexExtractor.bestAmountString(from: lines.joined(separator: "\n")) == nil {
                // Fallback: daha düşük minimum metin yüksekliği ve balanced/fast
                let fallback = VNRecognizeTextRequest { fallbackRequest, _ in
                    observations = (fallbackRequest.results as? [VNRecognizedTextObservation]) ?? []
                    lines = observations.compactMap { $0.topCandidates(1).first?.string }
                    handleResult()
                }
                fallback.recognitionLevel = .fast
                fallback.usesLanguageCorrection = true
                fallback.recognitionLanguages = ["tr-TR", "en-US", "en-GB"]
                fallback.minimumTextHeight = 0.008

                let fallbackHandler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation, options: [:])
                DispatchQueue.global(qos: .userInitiated).async {
                    do { try fallbackHandler.perform([fallback]) } catch {
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            self.errorMessage = "Okuma başlatılamadı."
                        }
                    }
                }
            } else {
                handleResult()
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["tr-TR", "en-US"]
        request.minimumTextHeight = 0.015

        let requests = [request]
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform(requests) } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Okuma başlatılamadı."
                }
            }
        }
    }

    private func parseDate(from string: String) -> Date? {
        let fmts = ["dd.MM.yyyy", "dd/MM/yyyy", "d.M.yyyy", "d/M/yyyy", "yyyy-MM-dd"]
        let df = DateFormatter(); df.locale = Locale(identifier: "tr_TR")
        for f in fmts { df.dateFormat = f; if let d = df.date(from: string) { return d } }
        return nil
    }

    private func guessTitle(from text: String) -> String {
        return text.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "Fiş"
    }

    private func guessCategory(from text: String) -> TransactionCategory {
        let lower = text.lowercased()
        if lower.contains("market") || lower.contains("alışveriş") || lower.contains("kasa") { return .shopping }
        if lower.contains("restoran") || lower.contains("yemek") || lower.contains("cafe") { return .food }
        if lower.contains("fatura") || lower.contains("elektrik") || lower.contains("su ") || lower.contains("doğalgaz") || lower.contains("internet") { return .bills }
        if lower.contains("ulaşım") || lower.contains("metro") || lower.contains("otobüs") || lower.contains("taksi") { return .transport }
        return .other
    }

    // OCR doğruluğunu artırmak için basit ön işlem: gri tonlama + kontrast + keskinleştirme
    private func preprocessedCGImage(from image: UIImage) -> CGImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()

        // 1) Gri tonlama + kontrast
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.contrast = 1.25
        colorControls.brightness = 0.0
        colorControls.saturation = 0.0 // gri tonlama

        // 2) Hafif pozlama düzeltmesi
        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = colorControls.outputImage
        exposure.ev = 0.25

        // 3) Keskinleştirme (OCR için harf kenarlarını belirginleştir)
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = exposure.outputImage
        sharpen.sharpness = 0.6

        guard let output = sharpen.outputImage else { return nil }

        // 4) Ölçek: çok büyük görselleri makul boyuta indir (uzun kenar ~2200px)
        let extent = output.extent
        let maxSide: CGFloat = 2200
        let scale = min(1.0, maxSide / max(extent.width, extent.height))
        let finalImage: CIImage
        if scale < 1.0 {
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            finalImage = output.transformed(by: transform)
        } else {
            finalImage = output
        }

        return context.createCGImage(finalImage, from: finalImage.extent)
    }

    private func makeNote(parsed: ParsedReceiptResult, fallbackDate: Date) -> String {
        var parts: [String] = []
        parts.append(parsed.title)
        if let ds = parsed.dateString, !ds.isEmpty {
            parts.append(ds)
        } else {
            let df = DateFormatter(); df.locale = Locale(identifier: "tr_TR"); df.dateFormat = "dd.MM.yyyy"
            parts.append(df.string(from: fallbackDate))
        }
        if let a = parsed.amountString, !a.isEmpty {
            parts.append("₺" + a)
        }
        return parts.joined(separator: " • ")
    }

    private func saveExpense() {
        guard let parsed, let amountStr = parsed.amountString else { return }
        let normalized = amountStr.replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalized) else { return }

        let date = selectedDate

        let transaction = Transaction(
            title: parsed.title,
            amount: amount,
            type: .expense,
            category: parsed.suggestedCategory,
            date: date,
            note: makeNote(parsed: parsed, fallbackDate: date),
            isPaid: true
        )
        dataManager.addTransaction(transaction)
        HapticManager.shared.success()
        dismiss()
    }
}

// Sonuç modeli ve özet kartı
struct ParsedReceiptResult: Equatable {
    var title: String
    var amountString: String?
    var dateString: String?
    var rawText: String
    var suggestedCategory: TransactionCategory
}

struct ResultCard: View {
    let parsed: ParsedReceiptResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: (parsed.amountString != nil) ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor((parsed.amountString != nil) ? .green : .orange)
                Text((parsed.amountString != nil) ? "Tutar ve kategori bilgisi alındı" : "Tutar algılanamadı")
                    .font(Theme.subheadline)
                    .fontWeight(.semibold)
            }

            HStack {
                Label(parsed.title, systemImage: "doc.text")
                Spacer()
            }
            .font(Theme.body)

            HStack {
                Label(parsed.amountString ?? "—", systemImage: "turkishlirasign.circle")
                Spacer()
                Label(parsed.suggestedCategory.rawValue, systemImage: "tag.fill")
            }
            .font(Theme.body)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct PrimaryGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .foregroundStyle(Color.white)
            .background(
                Theme.primaryGradient
                    .opacity(isEnabled ? 1.0 : 0.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.15), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OutlineGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .foregroundStyle(Theme.primaryGradient.opacity(isEnabled ? 1.0 : 0.5))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.primaryGradient.opacity(isEnabled ? 1.0 : 0.5), lineWidth: 1.5)
            )
            .background(
                Color.primary.opacity(0.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// Fotoğraf kütüphanesi picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onPick(image)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onPick(nil)
        }
    }
}

// Dosyalar'dan görsel veya PDF seçimi
struct DocumentImagePicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [UTType.image, UTType.pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentImagePicker
        init(_ parent: DocumentImagePicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { parent.onPick(nil); return }
            var image: UIImage? = nil
            if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                if type.conforms(to: UTType.image) {
                    if let data = try? Data(contentsOf: url) { image = UIImage(data: data) }
                } else if type.conforms(to: UTType.pdf) {
                    if let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
                        let pageRect = page.bounds(for: .mediaBox)
                        let scale: CGFloat = 2.0
                        let size = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
                        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
                        if let ctx = UIGraphicsGetCurrentContext() {
                            ctx.saveGState()
                            ctx.scaleBy(x: scale, y: scale)
                            UIColor.white.set()
                            ctx.fill(pageRect)
                            page.draw(with: .mediaBox, to: ctx)
                            ctx.restoreGState()
                            image = UIGraphicsGetImageFromCurrentImageContext()
                        }
                        UIGraphicsEndImageContext()
                    }
                }
            }
            parent.onPick(image)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onPick(nil)
        }
    }
}

// Minimal kamera: sadece önizleme + deklanşör (flash/filtre yok)
struct MinimalCamera: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onCapture = onCapture
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage?) -> Void)?

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let shutterButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        setupPreview()
        setupShutter()
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    private func setupShutter() {
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.backgroundColor = .white
        shutterButton.tintColor = .clear
        shutterButton.layer.cornerRadius = 34
        shutterButton.layer.borderWidth = 4
        shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        shutterButton.addTarget(self, action: #selector(capture), for: .touchUpInside)

        view.addSubview(shutterButton)
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            shutterButton.widthAnchor.constraint(equalToConstant: 68),
            shutterButton.heightAnchor.constraint(equalToConstant: 68)
        ])
    }

    @objc private func capture() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { onCapture?(nil); return }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { onCapture?(nil); return }
        onCapture?(image)
    }
}

// Standart iOS kamera: otomatik odak + varsayılan kontroller (flash tuşu sistemin)
struct StandardCameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.showsCameraControls = true // standart iOS kamera arayüzü
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: StandardCameraPicker
        init(_ parent: StandardCameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCapture(nil)
        }
    }
}

// Basit regex yardımcıları
enum ReceiptRegexExtractor {
    static func firstMatch(in text: String, pattern: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        guard group < match.numberOfRanges, let r = Range(match.range(at: group), in: text) else { return nil }
        return String(text[r])
    }

    // Daha akıllı tutar seçimi: bağlam ve puanlama
    static func bestAmountString(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        var best: (value: String, score: Double)? = nil
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let candidates = allAmounts(in: line)
            guard !candidates.isEmpty else { continue }
            let scoreBase = scoreForContext(line: line)
            for candidate in candidates {
                let numeric = normalizeAmount(candidate)
                let magnitudeBonus: Double = (Double(numeric) ?? 0.0) / 1000.0 // büyük tutarlara küçük bir bonus
                var score = scoreBase + magnitudeBonus
                // Satır sonunda geçiyorsa küçük bir bonus
                if line.hasSuffix(candidate) { score += 0.3 }
                // Para birimi içeriyorsa bonus
                let lower = line.lowercased()
                if lower.contains("₺") || lower.contains(" tl") || lower.contains("try") { score += 0.5 }
                if let currentBest = best {
                    if score > currentBest.score { best = (candidate, score) }
                } else {
                    best = (candidate, score)
                }
            }
        }
        // Yedek: hiçbir bağlam bulunamadıysa en büyük tutarı dön
        if best == nil {
            let amounts = allAmounts(in: text)
            let sorted = amounts.sorted { (a, b) in
                (Double(normalizeAmount(a)) ?? 0) > (Double(normalizeAmount(b)) ?? 0)
            }
            return sorted.first
        }
        return best?.value
    }

    // Satırdaki anahtar kelimelere göre puanlama
    private static func scoreForContext(line: String) -> Double {
        let lower = line.lowercased()
        var score: Double = 0
        let positiveKeywords = ["genel toplam", "toplam", "tutar", "odeme", "ödeme", "nakit", "kredi", "kart", "total", "grand total", "sum", "kdv dahil", "kdv dâhil"]
        let negativeKeywords = ["adet", "kg", "koli", "birim", "puan", "miktar", "no:", "urun", "ürün", "stok"]
        for k in positiveKeywords { if lower.contains(k) { score += 2.0 } }
        for k in negativeKeywords { if lower.contains(k) { score -= 1.0 } }
        return score
    }

    // Metindeki tüm tutar adaylarını döndürür (1.234,56 / 1234.56 vs.)
    private static func allAmounts(in text: String) -> [String] {
        let pattern = #"(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*|\d+)[.,]\d{2}(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        return matches.compactMap { m in
            guard let r = Range(m.range, in: text) else { return nil }
            return String(text[r])
        }
    }

    // "1.234,56" -> "1234.56" normalizasyonu
    private static func normalizeAmount(_ s: String) -> String {
        // Önce binlik ayraçlarını kaldır, sonra virgülü noktaya çevir
        var str = s
        // Eğer hem nokta hem virgül varsa; yaygın TR formatı: "." binlik, "," ondalık
        if s.contains(".") && s.contains(",") {
            str = s.replacingOccurrences(of: ".", with: "")
            str = str.replacingOccurrences(of: ",", with: ".")
        } else if s.contains(",") && !s.contains(".") {
            // Sadece virgül varsa ondalık ayırıcı kabul et
            str = s.replacingOccurrences(of: ",", with: ".")
        } else {
            // Sadece nokta varsa olduğu gibi bırak
            str = s
        }
        return str
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

#Preview {
    ReceiptScannerView()
        .environmentObject(DataManager.shared)
}

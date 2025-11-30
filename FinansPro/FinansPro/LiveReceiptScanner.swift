import SwiftUI
import VisionKit

// Basit regex yardımcıları
enum RegexExtractor {
    static func firstMatch(in text: String, pattern: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        let groupIndex = group
        guard groupIndex < match.numberOfRanges,
              let r = Range(match.range(at: groupIndex), in: text) else { return nil }
        return String(text[r])
    }
}

struct ParsedReceipt: Equatable {
    var title: String
    var amountString: String?
    var dateString: String?
    var rawText: String
}

// NOT: Canlı tarama otomatik başlatılmaz. Bu komponent varsayılan akışta kullanılmamalıdır.
struct LiveReceiptScanner: UIViewControllerRepresentable {
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: LiveReceiptScanner
        private var lastEmittedText: String = ""

        init(parent: LiveReceiptScanner) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(allItems: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(allItems: allItems)
        }

        private func handle(allItems: [RecognizedItem]) {
            let allText = allItems.compactMap { item -> String? in
                if case .text(let text) = item { return text.transcript }
                return nil
            }.joined(separator: "\n")

            // Aynı metni tekrar tekrar göndermeyelim
            guard allText.isEmpty == false, allText != lastEmittedText else { return }
            lastEmittedText = allText

            let amount = RegexExtractor.firstMatch(in: allText, pattern: #"([0-9]+[.,][0-9]{2})"#)
            let date = RegexExtractor.firstMatch(in: allText, pattern: #"(\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b)"#)
            let title = guessTitle(from: allText)

            let parsed = ParsedReceipt(title: title, amountString: amount, dateString: date, rawText: allText)
            DispatchQueue.main.async {
                self.parent.onParsed(parsed)
            }
        }

        private func guessTitle(from text: String) -> String {
            // İlk dolu satırı başlık kabul et
            let lines = text.components(separatedBy: .newlines)
            if let first = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                return first.trimmingCharacters(in: .whitespaces)
            }
            return "Fiş"
        }
    }

    var onParsed: (ParsedReceipt) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false, // otomatik çoklu tanıma kapalı
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false // rehber kapalı
        )
        scanner.delegate = context.coordinator
        // Otomatik canlı tarama BAŞLATILMIYOR. Kullanılmayacak veya manuel başlatma gerektirir.
        // try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
}

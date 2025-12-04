//
//  BatchReceiptScannerView.swift
//  FinansPro
//
//  Toplu fiş/fatura tarama ekranı
//  Birden fazla fişi aynı anda işler
//

import SwiftUI
import PhotosUI

struct BatchReceiptItem: Identifiable {
    let id = UUID()
    var image: UIImage
    var parsedReceipt: ParsedReceipt?
    var isProcessing: Bool = false
    var error: String?
}

struct BatchReceiptScannerView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedItems: [BatchReceiptItem] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingPhotoPicker = false
    @State private var isProcessingAll = false
    @State private var processedCount = 0
    @State private var showingSaveConfirmation = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                // Başlık
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Toplu Tarama")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            Text("Birden fazla fiş/faturayı aynı anda işleyin")
                                .font(Theme.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !selectedItems.isEmpty {
                            Text("\(selectedItems.count) fiş")
                                .font(Theme.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                if selectedItems.isEmpty {
                    // Boş durum
                    Spacer()

                    VStack(spacing: 24) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 8) {
                            Text("Fiş/Fatura Seçin")
                                .font(Theme.title2)
                                .fontWeight(.bold)

                            Text("Galeriden birden fazla fiş fotoğrafı seçerek toplu olarak işleyin")
                                .font(Theme.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Fotoğraf Seç")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: 300)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    }

                    Spacer()
                } else {
                    // Fiş listesi
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(selectedItems) { item in
                                BatchReceiptCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Alt butonlar
                    VStack(spacing: 12) {
                        if isProcessingAll {
                            VStack(spacing: 8) {
                                ProgressView(value: Double(processedCount), total: Double(selectedItems.count))
                                    .tint(.orange)

                                Text("İşleniyor: \(processedCount)/\(selectedItems.count)")
                                    .font(Theme.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else {
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingPhotoPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Daha Fazla Ekle")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                }

                                Button(action: processAllReceipts) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Tümünü Oku")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Kapat") {
                    dismiss()
                }
            }

            if !selectedItems.isEmpty && selectedItems.allSatisfy({ $0.parsedReceipt != nil }) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Kaydet") {
                        showingSaveConfirmation = true
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotos, matching: .images)
        .onChange(of: selectedPhotos) { _, newItems in
            loadPhotos(from: newItems)
            selectedPhotos = [] // Reset after loading
        }
        .alert("Fişler Kaydedilsin mi?", isPresented: $showingSaveConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Kaydet") {
                saveAllReceipts()
            }
        } message: {
            Text("\(selectedItems.count) fiş gider olarak kaydedilecek. Devam etmek istiyor musunuz?")
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            // Görsel yönlendirmesini düzelt
                            let correctedImage = image.fixedOrientation()
                            selectedItems.append(BatchReceiptItem(image: correctedImage))
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }

    private func processAllReceipts() {
        isProcessingAll = true
        processedCount = 0

        for index in selectedItems.indices {
            processReceipt(at: index)
        }
    }

    private func processReceipt(at index: Int) {
        guard index < selectedItems.count else { return }

        selectedItems[index].isProcessing = true

        let image = selectedItems[index].image

        ReceiptScannerManager.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                selectedItems[index].isProcessing = false
                processedCount += 1

                switch result {
                case .success(let text):
                    let receipt = ReceiptParser.shared.parse(text: text)
                    selectedItems[index].parsedReceipt = receipt
                case .failure(let error):
                    selectedItems[index].error = error.localizedDescription
                }

                if processedCount == selectedItems.count {
                    isProcessingAll = false
                    HapticManager.shared.success()
                }
            }
        }
    }

    private func saveAllReceipts() {
        for item in selectedItems {
            guard let receipt = item.parsedReceipt else { continue }

            let imageData = item.image.jpegData(compressionQuality: 0.7)

            let transaction = Transaction(
                title: receipt.merchantName ?? "Fiş",
                amount: receipt.totalAmount ?? 0,
                type: .expense,
                category: receipt.suggestedCategory,
                date: receipt.date ?? Date(),
                note: receipt.items.prefix(3).map { $0.name }.joined(separator: ", "),
                receiptImageData: imageData
            )

            dataManager.addTransaction(transaction)
        }

        HapticManager.shared.success()
        dismiss()
    }
}

struct BatchReceiptCard: View {
    let item: BatchReceiptItem

    var body: some View {
        HStack(spacing: 12) {
            // Fotoğraf önizlemesi
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                if item.isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("İşleniyor...")
                            .font(Theme.callout)
                            .foregroundColor(.secondary)
                    }
                } else if let error = item.error {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hata")
                            .font(Theme.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)

                        Text(error)
                            .font(Theme.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else if let receipt = item.parsedReceipt {
                    VStack(alignment: .leading, spacing: 4) {
                        if let name = receipt.merchantName {
                            Text(name)
                                .font(Theme.callout)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }

                        if let amount = receipt.totalAmount {
                            Text(amount.toCurrency())
                                .font(Theme.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        HStack(spacing: 4) {
                            Image(systemName: receipt.suggestedCategory.icon)
                                .font(.caption)
                            Text(receipt.suggestedCategory.rawValue)
                                .font(Theme.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    Text("Bekliyor...")
                        .font(Theme.callout)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Durum ikonu
            if let receipt = item.parsedReceipt, receipt.totalAmount != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        BatchReceiptScannerView()
            .environmentObject(DataManager.shared)
    }
}

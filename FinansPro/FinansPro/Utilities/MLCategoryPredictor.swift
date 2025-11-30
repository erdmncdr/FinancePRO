//
//  MLCategoryPredictor.swift
//  FinansPro
//
//  Makine öğrenimi tabanlı kategori tahmini
//  Kullanıcının geçmiş verilerinden öğrenir
//

import Foundation
import CoreML
import NaturalLanguage

class MLCategoryPredictor {
    static let shared = MLCategoryPredictor()

    private var embedding: NLEmbedding?
    private var categoryModel: [TransactionCategory: [String]] = [:]
    private var learningData: [(text: String, category: TransactionCategory)] = []

    private init() {
        // iOS 16+ için NLEmbedding desteği
        if #available(iOS 16.0, *) {
            embedding = NLEmbedding.sentenceEmbedding(for: .turkish)
        }
        loadTrainingData()
        buildModel()
    }

    /// Geçmiş işlemleri kullanarak modeli eğit
    func trainWithUserData(transactions: [Transaction]) {
        learningData.removeAll()

        // Kullanıcının geçmiş işlemlerinden öğren
        for transaction in transactions {
            let text = transaction.title.lowercased() + " " + transaction.note.lowercased()
            learningData.append((text: text, category: transaction.category))
        }

        buildModel()
    }

    /// Metin tabanlı kategori tahmini yap
    func predictCategory(from text: String, merchantName: String? = nil) -> (category: TransactionCategory, confidence: Double) {
        let fullText = (merchantName ?? "") + " " + text
        let lowercased = fullText.lowercased()

        // 1. Kullanıcının öğrenilmiş verileriyle eşleştir
        if let userPrediction = predictFromUserData(text: lowercased) {
            return userPrediction
        }

        // 2. Keyword bazlı tahmin
        let keywordPrediction = predictFromKeywords(text: lowercased)

        // 3. Semantic similarity (NLEmbedding)
        if let semanticPrediction = predictFromSemanticSimilarity(text: lowercased) {
            // İki tahmini birleştir (weighted average)
            if semanticPrediction.confidence > keywordPrediction.confidence {
                return semanticPrediction
            }
        }

        return keywordPrediction
    }

    // MARK: - Private Methods

    private func loadTrainingData() {
        // Temel kategori kelimeleri
        categoryModel = [
            .food: [
                "market", "migros", "bim", "a101", "şok", "carrefour",
                "restaurant", "restoran", "cafe", "kafe", "yemek", "kahve",
                "pasta", "börek", "kebap", "pizza", "hamburger", "döner",
                "bakkal", "manav", "kasap", "balık", "tavuk"
            ],
            .transport: [
                "benzin", "shell", "opet", "bp", "petrol", "motorin",
                "otopark", "park", "taksi", "uber", "otobüs", "metro",
                "ulaşım", "bilet", "havayolu", "uçak", "tren", "vapur"
            ],
            .shopping: [
                "alışveriş", "giyim", "ayakkabı", "mağaza", "butik",
                "elektronik", "teknosa", "vatan", "media markt",
                "zara", "h&m", "defacto", "lcw", "mango",
                "mobilya", "ikea", "ev", "dekorasyon"
            ],
            .bills: [
                "fatura", "elektrik", "su", "doğalgaz", "gaz",
                "internet", "telefon", "gsm", "turkcell", "vodafone",
                "türk telekom", "kira", "aidat", "apartman"
            ],
            .health: [
                "eczane", "pharmacy", "ilaç", "hastane", "hospital",
                "klinik", "doktor", "dr", "sağlık", "poliklinik",
                "diş", "göz", "muayene", "tahlil", "check up"
            ],
            .entertainment: [
                "sinema", "cinema", "film", "bilet", "ticket",
                "konser", "tiyatro", "müze", "sergi", "etkinlik",
                "eğlence", "parti", "gece", "club", "bar"
            ],
            .education: [
                "kitap", "book", "okul", "üniversite", "kurs",
                "eğitim", "dershane", "özel ders", "kırtasiye",
                "not defteri", "kalem", "çanta", "akademi"
            ],
            .salary: [
                "maaş", "salary", "ücret", "gelir", "income",
                "prim", "bonus", "ikramiye", "ödeme", "serbest"
            ],
            .investment: [
                "yatırım", "investment", "hisse", "borsa", "altın",
                "döviz", "bitcoin", "kripto", "fon", "tahvil"
            ]
        ]
    }

    private func buildModel() {
        // Model zaten keyword tabanlı, ek bir şey yapmaya gerek yok
        // İleride CoreML modeli eklenebilir
    }

    private func predictFromUserData(text: String) -> (category: TransactionCategory, confidence: Double)? {
        guard !learningData.isEmpty else { return nil }

        var scores: [TransactionCategory: Double] = [:]

        for data in learningData {
            let similarity = stringSimilarity(text, data.text)
            if similarity > 0.7 {  // Yüksek benzerlik eşiği
                scores[data.category, default: 0] += similarity
            }
        }

        if let (category, score) = scores.max(by: { $0.value < $1.value }) {
            let confidence = min(score, 1.0)
            if confidence > 0.7 {
                return (category, confidence)
            }
        }

        return nil
    }

    private func predictFromKeywords(text: String) -> (category: TransactionCategory, confidence: Double) {
        var scores: [TransactionCategory: Int] = [:]

        for (category, keywords) in categoryModel {
            let matchCount = keywords.filter { text.contains($0) }.count
            if matchCount > 0 {
                scores[category] = matchCount
            }
        }

        if let (category, matchCount) = scores.max(by: { $0.value < $1.value }) {
            let confidence = min(Double(matchCount) / 3.0, 1.0)  // Max 3 kelime için %100
            return (category, confidence)
        }

        // Hiç eşleşme yoksa shopping döndür (varsayılan)
        return (.shopping, 0.3)
    }

    private func predictFromSemanticSimilarity(text: String) -> (category: TransactionCategory, confidence: Double)? {
        guard let textEmbedding = embedding else { return nil }

        // Kategori başlıklarından embedding oluştur ve karşılaştır
        var bestMatch: (category: TransactionCategory, similarity: Double)?

        for category in TransactionCategory.allCases {
            if let categoryEmbedding = textEmbedding.vector(for: category.rawValue.lowercased()) {
                if let inputVector = textEmbedding.vector(for: text) {
                    let similarity = cosineSimilarity(inputVector, categoryEmbedding)
                    if let current = bestMatch {
                        if similarity > current.similarity {
                            bestMatch = (category, similarity)
                        }
                    } else {
                        bestMatch = (category, similarity)
                    }
                }
            }
        }

        if let match = bestMatch, match.similarity > 0.5 {
            return (match.category, match.similarity)
        }

        return nil
    }

    // MARK: - Helper Methods

    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let words1 = Set(s1.components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(s2.components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count

        guard union > 0 else { return 0 }

        return Double(intersection) / Double(union)
    }

    private func cosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        guard vec1.count == vec2.count else { return 0 }

        var dotProduct = 0.0
        var magnitude1 = 0.0
        var magnitude2 = 0.0

        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
            magnitude1 += vec1[i] * vec1[i]
            magnitude2 += vec2[i] * vec2[i]
        }

        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        guard denominator > 0 else { return 0 }

        return dotProduct / denominator
    }
}

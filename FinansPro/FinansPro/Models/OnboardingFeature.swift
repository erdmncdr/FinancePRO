//
//  OnboardingFeature.swift
//  FinansPro
//
//  Uygulama tanıtım özellikleri
//

import SwiftUI

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]

    static let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "FinansPro'ya Hoş Geldiniz",
            description: "Gelir ve giderlerinizi kolayca takip edin, mali durumunuzu kontrol altında tutun",
            gradient: [.blue, .purple]
        ),

        OnboardingFeature(
            icon: "plus.circle.fill",
            title: "Kolay İşlem Ekleme",
            description: "Gider, gelir, borç ve alacaklarınızı tek dokunuşla kaydedin. Özel kategoriler oluşturun",
            gradient: [.green, .mint]
        ),

        OnboardingFeature(
            icon: "doc.text.viewfinder",
            title: "Akıllı Fiş Tarama",
            description: "Kamera veya galeriden fiş fotoğrafı çekin, yapay zeka otomatik olarak bilgileri okusun",
            gradient: [.orange, .pink]
        ),

        OnboardingFeature(
            icon: "doc.badge.plus",
            title: "PDF & Toplu Tarama",
            description: "E-faturaları PDF olarak okuyun veya birden fazla fişi aynı anda tarayın",
            gradient: [.purple, .pink]
        ),

        OnboardingFeature(
            icon: "brain.head.profile",
            title: "Yapay Zeka Desteği",
            description: "ML tabanlı kategori tahmini ile sistem sizi tanır, alışkanlıklarınızı öğrenir",
            gradient: [.indigo, .blue]
        ),

        OnboardingFeature(
            icon: "creditcard.fill",
            title: "Taksitli Ödemeler",
            description: "Kredi kartı taksitlerini, kredileri ve abonelikleri kolayca takip edin",
            gradient: [.cyan, .blue]
        ),

        OnboardingFeature(
            icon: "chart.bar.fill",
            title: "Detaylı Analizler",
            description: "Harcamalarınızı grafiklerle görün, kategorilere göre analiz edin, bütçe planlayın",
            gradient: [.pink, .red]
        ),

        OnboardingFeature(
            icon: "checkmark.seal.fill",
            title: "Hemen Başlayın!",
            description: "Finansal özgürlüğe giden yolculuğunuz FinansPro ile başlasın",
            gradient: [.green, .blue]
        )
    ]
}

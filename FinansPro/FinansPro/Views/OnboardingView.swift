//
//  OnboardingView.swift
//  FinansPro
//
//  Uygulama tanıtım ekranı
//  İlk kullanıcılar için interaktif rehber
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private let features = OnboardingFeature.features

    var body: some View {
        ZStack {
            // Gradient arka plan
            LinearGradient(
                colors: features[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Atla butonu
                HStack {
                    Spacer()

                    if currentPage < features.count - 1 {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Atla")
                                .font(Theme.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)

                // Sayfa içeriği
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        OnboardingPageView(feature: feature, isLastPage: index == features.count - 1)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newValue in
                    HapticManager.shared.selection()
                }

                // Alt kısım - Progress indicator ve butonlar
                VStack(spacing: 30) {
                    // Page indicator
                    HStack(spacing: 12) {
                        ForEach(0..<features.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 30 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)

                    // Butonlar
                    HStack(spacing: 16) {
                        // Geri butonu
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentPage -= 1
                                }
                                HapticManager.shared.impact(style: .light)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }

                        Spacer()

                        // İleri/Başla butonu
                        Button(action: {
                            if currentPage < features.count - 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentPage += 1
                                }
                                HapticManager.shared.impact(style: .light)
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text(currentPage == features.count - 1 ? "Başla" : "İleri")
                                    .font(Theme.headline)
                                    .fontWeight(.bold)

                                Image(systemName: currentPage == features.count - 1 ? "checkmark" : "chevron.right")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Color(features[currentPage].gradient[0]))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isOnboardingComplete = true
        }

        // UserDefaults'a kaydet
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let feature: OnboardingFeature
    let isLastPage: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            ZStack {
                // Arka plan animasyonlu circle
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .opacity(isAnimating ? 0.3 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Ana icon
                Image(systemName: feature.icon)
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .padding(.bottom, 20)

            // Text content
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text(feature.description)
                    .font(Theme.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 40)
            }

            if isLastPage {
                // Son sayfa için özel içerik
                VStack(spacing: 12) {
                    FeaturePill(icon: "doc.text.viewfinder", text: "Fiş Tarama")
                    FeaturePill(icon: "brain.head.profile", text: "Yapay Zeka")
                    FeaturePill(icon: "chart.bar.fill", text: "Detaylı Raporlar")
                }
                .padding(.top, 20)
            }

            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Feature Pill Component
struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)

            Text(text)
                .font(Theme.callout)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}

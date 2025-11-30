//
//  LockScreenView.swift
//  FinansPro
//
//  Biyometrik kilit ekranı
//

import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var biometricAuth: BiometricAuthManager
    @State private var isUnlocking = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Arka plan blur
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo ve başlık
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }

                    Text("FinansPro")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Uygulamaya erişmek için kimliğinizi doğrulayın")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Kilit açma butonu
                Button {
                    unlock()
                } label: {
                    HStack(spacing: 12) {
                        if isUnlocking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: biometricAuth.biometricType().icon)
                                .font(.system(size: 24))

                            Text("Kilidi Aç")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .disabled(isUnlocking)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
            Button("Tekrar Dene") {
                unlock()
            }
        } message: {
            Text(errorMessage ?? "Kimlik doğrulama başarısız")
        }
        .onAppear {
            // Otomatik olarak kilidi açmayı dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                unlock()
            }
        }
    }

    private func unlock() {
        isUnlocking = true
        HapticManager.shared.impact(style: .medium)

        biometricAuth.authenticate { success, error in
            isUnlocking = false

            if success {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
                errorMessage = error
                showError = true
            }
        }
    }
}

#Preview {
    LockScreenView()
        .environmentObject(BiometricAuthManager.shared)
}

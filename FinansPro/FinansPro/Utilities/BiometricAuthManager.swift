//
//  BiometricAuthManager.swift
//  FinansPro
//
//  Biyometrik kimlik doğrulama yöneticisi
//

import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()

    @Published var isLocked = true
    @Published var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: "BiometricEnabled")
        }
    }

    private init() {
        // Biyometrik kilit ayarını yükle
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "BiometricEnabled")
    }

    /// Biyometrik kimlik doğrulama mevcut mu?
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    /// Kimlik doğrulama başlat
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Biyometrik kimlik doğrulama mevcut mu kontrol et
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(false, error?.localizedDescription ?? "Biyometrik kimlik doğrulama mevcut değil")
            }
            return
        }

        let reason = "Uygulamaya erişmek için kimliğinizi doğrulayın"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.isLocked = false
                    completion(true, nil)
                } else {
                    let message = authError?.localizedDescription ?? "Kimlik doğrulama başarısız"
                    completion(false, message)
                }
            }
        }
    }

    /// Uygulamayı kilitle
    func lockApp() {
        if isBiometricEnabled {
            isLocked = true
        }
    }

    /// Uygulamayı kilidi aç
    func unlockApp() {
        isLocked = false
    }
}

enum BiometricType {
    case none
    case touchID
    case faceID

    var icon: String {
        switch self {
        case .none: return "lock.fill"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        }
    }

    var name: String {
        switch self {
        case .none: return "Mevcut Değil"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
}

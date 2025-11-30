//
//  InstallmentPaymentDetailView.swift
//  FinansPro
//
//  Taksit detayları ve taksit listesi görünümü
//

import SwiftUI

struct InstallmentPaymentDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    let payment: InstallmentPayment
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Üst bilgi kartı
                VStack(spacing: 16) {
                    // İkon ve başlık
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(payment.title)
                                .font(Theme.title2)
                                .fontWeight(.bold)

                            Text(payment.category.rawValue)
                                .font(Theme.callout)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // İlerleme çubuğu
                    VStack(spacing: 8) {
                        HStack {
                            Text("İlerleme")
                                .font(Theme.callout)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(payment.paidCount)/\(payment.installmentCount) taksit")
                                .font(Theme.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.primaryGradient)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray).opacity(0.2))
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * (payment.progressPercentage / 100),
                                        height: 12
                                    )
                            }
                        }
                        .frame(height: 12)

                        HStack {
                            Text("\(Int(payment.progressPercentage))% tamamlandı")
                                .font(Theme.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            if payment.isCompleted {
                                Label("Tamamlandı", systemImage: "checkmark.circle.fill")
                                    .font(Theme.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    Divider()

                    // Özet bilgiler
                    VStack(spacing: 12) {
                        SummaryRow(
                            title: "Toplam Tutar",
                            value: payment.totalAmount.toCurrency(),
                            icon: "turkishlirasign.circle.fill",
                            color: .blue
                        )

                        SummaryRow(
                            title: "Ödenen",
                            value: payment.paidAmount.toCurrency(),
                            icon: "checkmark.circle.fill",
                            color: .green
                        )

                        SummaryRow(
                            title: "Kalan",
                            value: payment.remainingAmount.toCurrency(),
                            icon: "clock.fill",
                            color: .orange
                        )

                        SummaryRow(
                            title: "Taksit Tutarı",
                            value: payment.installmentAmount.toCurrency(),
                            icon: "equal.circle.fill",
                            color: .purple
                        )
                    }

                    // Not varsa göster
                    if !payment.note.isEmpty {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)

                            Text(payment.note)
                                .font(Theme.callout)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)

                // Taksitler listesi
                VStack(alignment: .leading, spacing: 12) {
                    Text("Taksitler")
                        .font(Theme.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(payment.installments) { installment in
                        InstallmentCard(
                            installment: installment,
                            paymentId: payment.id
                        )
                        .padding(.horizontal)
                    }
                }

                // Sil butonu
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Taksitli Ödemeyi Sil")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Taksit Detayları")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Taksitli Ödemeyi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                dataManager.deleteInstallmentPayment(payment)
                HapticManager.shared.success()
                dismiss()
            }
        } message: {
            Text("Bu taksitli ödemeyi ve tüm taksitleri silmek istediğinize emin misiniz?")
        }
    }
}

// Özet satırı bileşeni
struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(Theme.callout)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(Theme.callout)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// Taksit kartı bileşeni
struct InstallmentCard: View {
    @EnvironmentObject var dataManager: DataManager
    let installment: Installment
    let paymentId: UUID

    var body: some View {
        HStack(spacing: 16) {
            // Taksit numarası
            ZStack {
                Circle()
                    .fill(installment.isPaid ? Color.green.opacity(0.2) : statusColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                if installment.isPaid {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(installment.installmentNumber)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(installment.installmentNumber). Taksit")
                        .font(Theme.headline)
                        .foregroundColor(.primary)

                    if installment.isPaid {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if installment.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if installment.isUpcoming {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }

                Label(installment.dueDate.toShortString(), systemImage: "calendar")
                    .font(Theme.caption)
                    .foregroundColor(.secondary)

                if installment.isPaid, let paidDate = installment.paidDate {
                    Label("Ödendi: \(paidDate.toShortString())", systemImage: "checkmark.circle")
                        .font(Theme.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Tutar ve durum
            VStack(alignment: .trailing, spacing: 4) {
                Text(installment.amount.toCurrency())
                    .font(Theme.headline)
                    .fontWeight(.bold)
                    .foregroundColor(installment.isPaid ? .green : statusColor)

                if !installment.isPaid {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        dataManager.markInstallmentAsPaid(paymentId: paymentId, installmentId: installment.id)
                    }) {
                        Text("Ödendi")
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        dataManager.markInstallmentAsUnpaid(paymentId: paymentId, installmentId: installment.id)
                    }) {
                        Text("Geri Al")
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: installment.isOverdue ? 2 : 1)
        )
    }

    private var statusColor: Color {
        if installment.isOverdue {
            return .red
        } else if installment.isUpcoming {
            return .orange
        } else {
            return .blue
        }
    }

    private var borderColor: Color {
        if installment.isPaid {
            return Color.green.opacity(0.3)
        } else if installment.isOverdue {
            return Color.red.opacity(0.6)
        } else if installment.isUpcoming {
            return Color.orange.opacity(0.5)
        } else {
            return Color(.systemGray).opacity(0.3)
        }
    }
}

#Preview {
    NavigationStack {
        InstallmentPaymentDetailView(
            payment: InstallmentPayment(
                title: "iPhone 15 Pro",
                totalAmount: 45000,
                installmentCount: 12,
                category: .shopping,
                startDate: Date(),
                frequency: .monthly,
                note: "24 ay vade farksız"
            )
        )
    }
    .environmentObject(DataManager.shared)
}

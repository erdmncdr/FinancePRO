import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // App Icon / Illustration
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 140, height: 140)

                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)
                }

                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("FinansPro'ya Hoş Geldiniz")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)

                    Text("Giderlerinizi, gelirlerinizi ve yaklaşan ödemelerinizi kolayca yönetin.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Continue button
                Button(action: {
                    isOnboardingComplete = true
                }) {
                    Text("Başlayalım")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}

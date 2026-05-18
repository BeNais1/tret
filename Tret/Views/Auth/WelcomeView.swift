import SwiftUI

struct WelcomeView: View {

    @State private var viewModel = AuthViewModel()
    @State private var showError = false

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                VStack(spacing: 14) {
                    BrandWordmark(size: 64)
                    Text("Соцсеть для программистов")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    featureRow(icon: "curlybraces", title: "Делись кодом", subtitle: "Пиши и публикуй сниппеты с любого языка")
                    featureRow(icon: "person.2.fill", title: "Подписывайся", subtitle: "Следи за разработчиками, которые вдохновляют")
                    featureRow(icon: "sparkles", title: "Открывай новое", subtitle: "Рекомендации под твой стек")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 14) {
                    GlassButton(style: .primary, isLoading: viewModel.isLoading) {
                        Task { await viewModel.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Войти через Google")
                        }
                    }

                    Text("Продолжая, вы соглашаетесь с правилами сообщества и политикой конфиденциальности.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert("Ошибка входа", isPresented: $showError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    WelcomeView()
}

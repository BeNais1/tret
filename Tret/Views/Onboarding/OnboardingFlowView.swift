import SwiftUI

struct OnboardingFlowView: View {

    @Environment(AppState.self) private var appState
    @State private var viewModel: OnboardingViewModel
    @State private var showError = false

    init(pending: AppState.PendingProfile) {
        _viewModel = State(initialValue: OnboardingViewModel(pending: pending))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            BrandBackground().opacity(0.18)

            VStack(spacing: 0) {
                header

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)

                footer
            }
        }
        .onChange(of: viewModel.submitError) { _, value in
            showError = value != nil
        }
        .alert("Не удалось создать профиль", isPresented: $showError, presenting: viewModel.submitError) { _ in
            Button("OK", role: .cancel) { viewModel.submitError = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation(.smooth) { viewModel.goBack() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial, in: Circle())
                }
                .opacity(viewModel.stepIndex == 0 ? 0 : 1)
                .disabled(viewModel.stepIndex == 0)

                Spacer()
                Text("Шаг \(viewModel.stepIndex + 1) из \(viewModel.stepCount)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    appState.signOut()
                } label: {
                    Text("Выйти")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: Double(viewModel.stepIndex + 1), total: Double(viewModel.stepCount))
                .tint(Color("BrandGradientStart"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .usernamePhoto:
            OnboardingStep1UsernamePhoto(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        case .bio:
            OnboardingStep2Bio(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        case .languages:
            OnboardingStep3Languages(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        case .linksHashtags:
            OnboardingStep4LinksHashtags(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        case .preview:
            OnboardingStep5Preview(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            if viewModel.currentStep == .preview {
                GlassButton(
                    style: .primary,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: !viewModel.isSubmitting
                ) {
                    Task { await viewModel.submit(appState: appState) }
                } label: {
                    Text("Создать профиль")
                }
            } else {
                GlassButton(
                    style: .primary,
                    isEnabled: viewModel.canProceed
                ) {
                    withAnimation(.smooth) { viewModel.goNext() }
                } label: {
                    Text("Далее")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

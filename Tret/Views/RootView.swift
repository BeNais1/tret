import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            switch appState.phase {
            case .launching:
                LaunchView()
                    .transition(.opacity)
            case .unauthenticated:
                WelcomeView()
                    .transition(.opacity)
            case .onboarding(let pending):
                OnboardingFlowView(pending: pending)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .ready(let user):
                MainTabView(currentUser: user)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.35), value: phaseAnimationKey)
    }

    private var phaseAnimationKey: String {
        switch appState.phase {
        case .launching: return "launching"
        case .unauthenticated: return "unauthenticated"
        case .onboarding: return "onboarding"
        case .ready: return "ready"
        }
    }
}

#Preview {
    RootView().environment(AppState())
}

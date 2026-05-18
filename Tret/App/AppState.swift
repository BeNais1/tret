import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
@Observable
final class AppState {

    enum Phase: Equatable {
        case launching
        case unauthenticated
        case onboarding(PendingProfile)
        case ready(AppUser)
    }

    struct PendingProfile: Equatable, Sendable {
        let uid: String
        let email: String
        let displayName: String
        let photoURL: URL?
    }

    private(set) var phase: Phase = .launching
    var lastError: String?

    private let authService: AuthServiceProtocol
    private let userService: UserServiceProtocol
    private var authListener: AuthStateDidChangeListenerHandle?

    init(
        authService: AuthServiceProtocol = AuthService.shared,
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.authService = authService
        self.userService = userService
    }

    func bootstrap() {
        guard authListener == nil else { return }
        authListener = authService.addStateListener { [weak self] session in
            guard let self else { return }
            Task { await self.handleAuthChange(session: session) }
        }
    }

    func tearDown() {
        if let authListener {
            authService.removeStateListener(authListener)
            self.authListener = nil
        }
    }

    private func handleAuthChange(session: AuthSession?) async {
        guard let session else {
            phase = .unauthenticated
            return
        }
        do {
            if let user = try await userService.fetchUser(id: session.uid) {
                phase = .ready(user)
            } else {
                phase = .onboarding(PendingProfile(
                    uid: session.uid,
                    email: session.email,
                    displayName: session.displayName,
                    photoURL: session.photoURL
                ))
            }
        } catch {
            lastError = error.localizedDescription
            phase = .unauthenticated
        }
    }

    func completeOnboarding(user: AppUser) {
        phase = .ready(user)
    }

    func signOut() {
        do {
            try authService.signOut()
            phase = .unauthenticated
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Перезагружает профиль из Firestore (используется после редактирования).
    func refreshCurrentUser() async {
        guard case .ready(let current) = phase else { return }
        do {
            if let updated = try await userService.fetchUser(id: current.id) {
                phase = .ready(updated)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

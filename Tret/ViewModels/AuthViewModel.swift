import Foundation
import SwiftUI
import UIKit

@MainActor
@Observable
final class AuthViewModel {

    private(set) var isLoading = false
    var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }

    func signInWithGoogle() async {
        guard !isLoading else { return }
        guard let presenter = topViewController() else {
            errorMessage = "Не удалось открыть окно входа"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await authService.signInWithGoogle(presenter: presenter)
            // Дальнейшее переключение фазы происходит через AppState.bootstrap → listener.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return nil }
        guard let root = scene.keyWindow?.rootViewController ?? scene.windows.first?.rootViewController else { return nil }
        var current = root
        while let presented = current.presentedViewController { current = presented }
        return current
    }
}

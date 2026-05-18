import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var currentFirebaseUID: String? { get }
    func currentSession() -> AuthSession?
    func signInWithGoogle(presenter: UIViewController) async throws -> AuthSession
    func signOut() throws
    func addStateListener(_ listener: @escaping (AuthSession?) -> Void) -> AuthStateDidChangeListenerHandle
    func removeStateListener(_ handle: AuthStateDidChangeListenerHandle)
}

struct AuthSession: Equatable, Sendable {
    let uid: String
    let email: String
    let displayName: String
    let photoURL: URL?
}

@MainActor
final class AuthService: AuthServiceProtocol {

    static let shared = AuthService()

    private init() {}

    var currentFirebaseUID: String? {
        Auth.auth().currentUser?.uid
    }

    func currentSession() -> AuthSession? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthSession(
            uid: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            photoURL: user.photoURL
        )
    }

    private struct GooglePayload: Sendable {
        let idToken: String
        let accessToken: String
        let profileEmail: String?
        let profileName: String?
        let profileImageURL: URL?
    }

    func signInWithGoogle(presenter: UIViewController) async throws -> AuthSession {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw ServiceError.underlying("Firebase clientID не сконфигурирован")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Достаём только Sendable-значения внутри callback, чтобы не передавать
        // не-Sendable `GIDSignInResult` через границу континуации (Swift 6).
        let payload: GooglePayload = try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: ServiceError.underlying("Пустой результат входа Google"))
                    return
                }
                guard let idToken = result.user.idToken?.tokenString else {
                    continuation.resume(throwing: ServiceError.underlying("Google не вернул id_token"))
                    return
                }
                let payload = GooglePayload(
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString,
                    profileEmail: result.user.profile?.email,
                    profileName: result.user.profile?.name,
                    profileImageURL: result.user.profile?.imageURL(withDimension: 256)
                )
                continuation.resume(returning: payload)
            }
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: payload.idToken,
            accessToken: payload.accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        return AuthSession(
            uid: user.uid,
            email: user.email ?? payload.profileEmail ?? "",
            displayName: user.displayName ?? payload.profileName ?? "",
            photoURL: user.photoURL ?? payload.profileImageURL
        )
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    func addStateListener(_ listener: @escaping (AuthSession?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            guard let user else {
                listener(nil)
                return
            }
            let session = AuthSession(
                uid: user.uid,
                email: user.email ?? "",
                displayName: user.displayName ?? "",
                photoURL: user.photoURL
            )
            listener(session)
        }
    }

    func removeStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}

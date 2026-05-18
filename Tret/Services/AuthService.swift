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

    func signInWithGoogle(presenter: UIViewController) async throws -> AuthSession {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw ServiceError.underlying("Firebase clientID не сконфигурирован")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let googleResult: GIDSignInResult = try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: ServiceError.underlying("Пустой результат входа Google"))
                    return
                }
                continuation.resume(returning: result)
            }
        }

        guard let idToken = googleResult.user.idToken?.tokenString else {
            throw ServiceError.underlying("Google не вернул id_token")
        }
        let accessToken = googleResult.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        return AuthSession(
            uid: user.uid,
            email: user.email ?? googleResult.user.profile?.email ?? "",
            displayName: user.displayName ?? googleResult.user.profile?.name ?? "",
            photoURL: user.photoURL ?? googleResult.user.profile?.imageURL(withDimension: 256)
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

import Foundation
@preconcurrency import FirebaseFirestore

protocol UserServiceProtocol: Sendable {
    func fetchUser(id: String) async throws -> AppUser?
    func checkUsernameAvailable(_ username: String) async throws -> Bool
    func searchUsers(query: String, limit: Int) async throws -> [AppUser]
    func createUser(_ user: AppUser) async throws
    func updateUser(_ user: AppUser) async throws
}

final class UserService: UserServiceProtocol, @unchecked Sendable {

    static let shared = UserService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    private var usersCollection: CollectionReference {
        firestore.collection(FirestorePath.users)
    }

    private var usernamesCollection: CollectionReference {
        firestore.collection(FirestorePath.usernames)
    }

    func fetchUser(id: String) async throws -> AppUser? {
        let document = try await usersCollection.document(id).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: AppUser.self)
    }

    func checkUsernameAvailable(_ username: String) async throws -> Bool {
        let lower = username.lowercased()
        guard Validators.validateUsername(username) == .valid else {
            return false
        }
        let document = try await usernamesCollection.document(lower).getDocument()
        return !document.exists
    }

    func searchUsers(query: String, limit: Int = 25) async throws -> [AppUser] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return [] }

        let clampedLimit = max(1, min(limit, 30))
        let end = normalized + "\u{f8ff}"

        let snapshot = try await usersCollection
            .order(by: "usernameLowercase")
            .start(at: [normalized])
            .end(at: [end])
            .limit(to: clampedLimit)
            .getDocuments()

        return try snapshot.documents.compactMap { try $0.data(as: AppUser.self) }
    }

    /// Атомарно создаёт `usernames/{lower}` и `users/{uid}` в одной транзакции.
    /// Если username уже занят — кидает `.usernameAlreadyTaken`.
    func createUser(_ user: AppUser) async throws {
        let usernameRef = usernamesCollection.document(user.usernameLowercase)
        let userRef = usersCollection.document(user.id)

        _ = try await firestore.runTransaction { transaction, errorPointer in
            let existing: DocumentSnapshot
            do {
                existing = try transaction.getDocument(usernameRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            if existing.exists {
                let err = NSError(
                    domain: "TretAuthError",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "Имя пользователя занято"]
                )
                errorPointer?.pointee = err
                return nil
            }

            do {
                try transaction.setData(
                    from: user,
                    forDocument: userRef
                )
                transaction.setData(
                    [
                        "userId": user.id,
                        "createdAt": FieldValue.serverTimestamp()
                    ],
                    forDocument: usernameRef
                )
            } catch let encodeError as NSError {
                errorPointer?.pointee = encodeError
                return nil
            }
            return nil
        }
    }

    func updateUser(_ user: AppUser) async throws {
        var copy = user
        copy.updatedAt = Date()
        try usersCollection.document(user.id).setData(from: copy, merge: true)
    }
}

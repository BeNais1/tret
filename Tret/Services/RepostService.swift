import Foundation
@preconcurrency import FirebaseFirestore

protocol RepostServiceProtocol: Sendable {
    func repost(userId: String, originalPost: Post) async throws
    func removeRepost(userId: String, postId: String) async throws
    func isReposted(userId: String, postId: String) async throws -> Bool
    func fetchReposts(of userId: String, pageSize: Int) async throws -> [Repost]
}

final class RepostService: RepostServiceProtocol, @unchecked Sendable {

    static let shared = RepostService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func repost(userId: String, originalPost: Post) async throws {
        let repost = Repost(userId: userId, originalPost: originalPost)
        let repostsRef = firestore
            .collection(FirestorePath.userReposts(of: userId))
            .document(repost.id)
        let postRef = firestore.collection(FirestorePath.posts).document(originalPost.id)
        let userRef = firestore.collection(FirestorePath.users).document(userId)

        let batch = firestore.batch()
        try batch.setData(from: repost, forDocument: repostsRef)
        batch.updateData(["repostsCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        batch.updateData(["repostsCount": FieldValue.increment(Int64(1))], forDocument: userRef)
        try await batch.commit()
    }

    func removeRepost(userId: String, postId: String) async throws {
        let repostsRef = firestore
            .collection(FirestorePath.userReposts(of: userId))
            .document(postId)
        let postRef = firestore.collection(FirestorePath.posts).document(postId)
        let userRef = firestore.collection(FirestorePath.users).document(userId)

        let batch = firestore.batch()
        batch.deleteDocument(repostsRef)
        batch.updateData(["repostsCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        batch.updateData(["repostsCount": FieldValue.increment(Int64(-1))], forDocument: userRef)
        try await batch.commit()
    }

    func isReposted(userId: String, postId: String) async throws -> Bool {
        let document = try await firestore
            .collection(FirestorePath.userReposts(of: userId))
            .document(postId)
            .getDocument()
        return document.exists
    }

    func fetchReposts(of userId: String, pageSize: Int) async throws -> [Repost] {
        let snapshot = try await firestore
            .collection(FirestorePath.userReposts(of: userId))
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Repost.self) }
    }
}

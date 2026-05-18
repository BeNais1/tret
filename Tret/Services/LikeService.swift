import Foundation
import FirebaseFirestore

protocol LikeServiceProtocol: Sendable {
    func likePost(userId: String, postId: String) async throws
    func unlikePost(userId: String, postId: String) async throws
    func isPostLiked(userId: String, postId: String) async throws -> Bool
    func likeComment(userId: String, postId: String, commentId: String) async throws
    func unlikeComment(userId: String, postId: String, commentId: String) async throws
}

final class LikeService: LikeServiceProtocol {

    static let shared = LikeService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func likePost(userId: String, postId: String) async throws {
        let payload: [String: Any] = ["createdAt": FieldValue.serverTimestamp()]
        let batch = firestore.batch()
        batch.setData(
            payload,
            forDocument: firestore.collection(FirestorePath.postLikes(of: postId)).document(userId)
        )
        batch.setData(
            payload,
            forDocument: firestore.collection(FirestorePath.userLikes(of: userId)).document(postId)
        )
        batch.updateData(
            ["likesCount": FieldValue.increment(Int64(1))],
            forDocument: firestore.collection(FirestorePath.posts).document(postId)
        )
        try await batch.commit()
    }

    func unlikePost(userId: String, postId: String) async throws {
        let batch = firestore.batch()
        batch.deleteDocument(
            firestore.collection(FirestorePath.postLikes(of: postId)).document(userId)
        )
        batch.deleteDocument(
            firestore.collection(FirestorePath.userLikes(of: userId)).document(postId)
        )
        batch.updateData(
            ["likesCount": FieldValue.increment(Int64(-1))],
            forDocument: firestore.collection(FirestorePath.posts).document(postId)
        )
        try await batch.commit()
    }

    func isPostLiked(userId: String, postId: String) async throws -> Bool {
        let document = try await firestore
            .collection(FirestorePath.userLikes(of: userId))
            .document(postId)
            .getDocument()
        return document.exists
    }

    func likeComment(userId: String, postId: String, commentId: String) async throws {
        let likesPath = "\(FirestorePath.postComments(of: postId))/\(commentId)/likes"
        let commentRef = firestore
            .collection(FirestorePath.postComments(of: postId))
            .document(commentId)
        let batch = firestore.batch()
        batch.setData(
            ["createdAt": FieldValue.serverTimestamp()],
            forDocument: firestore.collection(likesPath).document(userId)
        )
        batch.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: commentRef)
        try await batch.commit()
    }

    func unlikeComment(userId: String, postId: String, commentId: String) async throws {
        let likesPath = "\(FirestorePath.postComments(of: postId))/\(commentId)/likes"
        let commentRef = firestore
            .collection(FirestorePath.postComments(of: postId))
            .document(commentId)
        let batch = firestore.batch()
        batch.deleteDocument(firestore.collection(likesPath).document(userId))
        batch.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: commentRef)
        try await batch.commit()
    }
}

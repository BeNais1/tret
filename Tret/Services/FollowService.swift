import Foundation
@preconcurrency import FirebaseFirestore

protocol FollowServiceProtocol: Sendable {
    func follow(currentUserId: String, targetUserId: String) async throws
    func unfollow(currentUserId: String, targetUserId: String) async throws
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool
    func hideFromRecommendations(currentUserId: String, hiddenUserId: String) async throws
    func unhideFromRecommendations(currentUserId: String, hiddenUserId: String) async throws
}

final class FollowService: FollowServiceProtocol, @unchecked Sendable {

    static let shared = FollowService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func follow(currentUserId: String, targetUserId: String) async throws {
        guard currentUserId != targetUserId else {
            throw ServiceError.invalidInput("Нельзя подписаться на самого себя")
        }
        let payload: [String: Any] = ["createdAt": FieldValue.serverTimestamp()]
        let batch = firestore.batch()
        batch.setData(
            payload,
            forDocument: firestore.collection(FirestorePath.following(of: currentUserId)).document(targetUserId)
        )
        batch.setData(
            payload,
            forDocument: firestore.collection(FirestorePath.followers(of: targetUserId)).document(currentUserId)
        )
        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(1))],
            forDocument: firestore.collection(FirestorePath.users).document(currentUserId)
        )
        batch.updateData(
            ["followersCount": FieldValue.increment(Int64(1))],
            forDocument: firestore.collection(FirestorePath.users).document(targetUserId)
        )
        try await batch.commit()
    }

    func unfollow(currentUserId: String, targetUserId: String) async throws {
        let batch = firestore.batch()
        batch.deleteDocument(
            firestore.collection(FirestorePath.following(of: currentUserId)).document(targetUserId)
        )
        batch.deleteDocument(
            firestore.collection(FirestorePath.followers(of: targetUserId)).document(currentUserId)
        )
        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(-1))],
            forDocument: firestore.collection(FirestorePath.users).document(currentUserId)
        )
        batch.updateData(
            ["followersCount": FieldValue.increment(Int64(-1))],
            forDocument: firestore.collection(FirestorePath.users).document(targetUserId)
        )
        try await batch.commit()
    }

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        let document = try await firestore
            .collection(FirestorePath.following(of: currentUserId))
            .document(targetUserId)
            .getDocument()
        return document.exists
    }

    func hideFromRecommendations(currentUserId: String, hiddenUserId: String) async throws {
        let payload: [String: Any] = ["createdAt": FieldValue.serverTimestamp()]
        try await firestore
            .collection(FirestorePath.hiddenRecommended(of: currentUserId))
            .document(hiddenUserId)
            .setData(payload)
    }

    func unhideFromRecommendations(currentUserId: String, hiddenUserId: String) async throws {
        try await firestore
            .collection(FirestorePath.hiddenRecommended(of: currentUserId))
            .document(hiddenUserId)
            .delete()
    }
}

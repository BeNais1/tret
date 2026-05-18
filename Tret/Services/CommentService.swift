import Foundation
@preconcurrency import FirebaseFirestore

protocol CommentServiceProtocol: Sendable {
    func create(_ comment: Comment) async throws
    func delete(commentId: String, postId: String) async throws
    func fetchByPost(postId: String, sortedByLikes: Bool, pageSize: Int) async throws -> [Comment]
}

final class CommentService: CommentServiceProtocol, @unchecked Sendable {

    static let shared = CommentService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func create(_ comment: Comment) async throws {
        let path = FirestorePath.postComments(of: comment.postId)
        let commentRef = firestore.collection(path).document(comment.id)
        let postRef = firestore.collection(FirestorePath.posts).document(comment.postId)
        let batch = firestore.batch()
        try batch.setData(from: comment, forDocument: commentRef)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        try await batch.commit()
    }

    func delete(commentId: String, postId: String) async throws {
        let path = FirestorePath.postComments(of: postId)
        let commentRef = firestore.collection(path).document(commentId)
        let postRef = firestore.collection(FirestorePath.posts).document(postId)
        let batch = firestore.batch()
        batch.deleteDocument(commentRef)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        try await batch.commit()
    }

    func fetchByPost(
        postId: String,
        sortedByLikes: Bool,
        pageSize: Int
    ) async throws -> [Comment] {
        let path = FirestorePath.postComments(of: postId)
        let query: Query = firestore.collection(path)
            .order(by: sortedByLikes ? "likesCount" : "createdAt", descending: true)
            .limit(to: pageSize)
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Comment.self) }
    }
}

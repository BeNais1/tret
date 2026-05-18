import Foundation
@preconcurrency import FirebaseFirestore

protocol PostServiceProtocol: Sendable {
    func create(_ post: Post) async throws
    func fetch(id: String) async throws -> Post?
    func update(_ post: Post) async throws
    func delete(id: String, authorId: String) async throws
    func fetchByAuthor(authorId: String, pageSize: Int, after lastDocument: DocumentSnapshot?) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?)
}

final class PostService: PostServiceProtocol, @unchecked Sendable {

    static let shared = PostService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func create(_ post: Post) async throws {
        let postRef = firestore.collection(FirestorePath.posts).document(post.id)
        let userRef = firestore.collection(FirestorePath.users).document(post.authorId)
        let batch = firestore.batch()
        let postData = try Firestore.Encoder().encode(post)

        batch.setData(postData, forDocument: postRef)
        batch.updateData(
            [
                "postsCount": FieldValue.increment(Int64(1)),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: userRef
        )
        try await batch.commit()
    }

    func fetch(id: String) async throws -> Post? {
        let snapshot = try await firestore.collection(FirestorePath.posts).document(id).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Post.self)
    }

    func update(_ post: Post) async throws {
        var copy = post
        copy.updatedAt = Date()
        try firestore.collection(FirestorePath.posts).document(post.id).setData(from: copy, merge: true)
    }

    func delete(id: String, authorId: String) async throws {
        try await firestore.collection(FirestorePath.posts).document(id).delete()
    }

    func fetchByAuthor(
        authorId: String,
        pageSize: Int,
        after lastDocument: DocumentSnapshot?
    ) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?) {
        var query: Query = firestore.collection(FirestorePath.posts)
            .whereField("authorId", isEqualTo: authorId)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)

        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
        return (posts, snapshot.documents.last)
    }
}

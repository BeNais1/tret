import Foundation
import FirebaseFirestore

enum FeedKind: String, Sendable {
    case recommended
    case following
}

struct FeedPage: Sendable {
    var posts: [Post]
    var lastDocument: DocumentSnapshot?
}

protocol FeedServiceProtocol: Sendable {
    func fetchRecommended(after lastDocument: DocumentSnapshot?, currentUserId: String, hiddenUserIds: Set<String>) async throws -> FeedPage
    func fetchFollowing(after lastDocument: DocumentSnapshot?, currentUserId: String, followingUserIds: Set<String>) async throws -> FeedPage
    func fetchHiddenUserIds(of userId: String) async throws -> Set<String>
    func fetchFollowingUserIds(of userId: String) async throws -> Set<String>
}

/// Stage 3: реализуем алгоритм рекомендаций (для MVP — просто по `createdAt desc`).
final class FeedService: FeedServiceProtocol {

    static let shared = FeedService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func fetchRecommended(
        after lastDocument: DocumentSnapshot?,
        currentUserId: String,
        hiddenUserIds: Set<String>
    ) async throws -> FeedPage {
        var query: Query = firestore.collection(FirestorePath.posts)
            .order(by: "createdAt", descending: true)
            .limit(to: AppConstants.feedPageSize)

        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents
            .compactMap { try $0.data(as: Post.self) }
            .filter { !hiddenUserIds.contains($0.authorId) }

        return FeedPage(posts: posts, lastDocument: snapshot.documents.last)
    }

    func fetchFollowing(
        after lastDocument: DocumentSnapshot?,
        currentUserId: String,
        followingUserIds: Set<String>
    ) async throws -> FeedPage {
        guard !followingUserIds.isEmpty else {
            return FeedPage(posts: [], lastDocument: nil)
        }

        // Firestore `in` поддерживает только 30 значений. Если подписок больше — потребуется батчинг.
        let authorIds = Array(followingUserIds.prefix(30))

        var query: Query = firestore.collection(FirestorePath.posts)
            .whereField("authorId", in: authorIds)
            .order(by: "createdAt", descending: true)
            .limit(to: AppConstants.feedPageSize)

        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
        return FeedPage(posts: posts, lastDocument: snapshot.documents.last)
    }

    func fetchHiddenUserIds(of userId: String) async throws -> Set<String> {
        let snapshot = try await firestore
            .collection(FirestorePath.hiddenRecommended(of: userId))
            .getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func fetchFollowingUserIds(of userId: String) async throws -> Set<String> {
        let snapshot = try await firestore
            .collection(FirestorePath.following(of: userId))
            .getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }
}

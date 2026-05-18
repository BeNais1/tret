import Foundation

struct Repost: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var userId: String
    var originalPostId: String
    var originalPostSnapshot: Post
    var createdAt: Date

    init(
        userId: String,
        originalPost: Post,
        createdAt: Date = Date()
    ) {
        self.id = originalPost.id
        self.userId = userId
        self.originalPostId = originalPost.id
        self.originalPostSnapshot = originalPost
        self.createdAt = createdAt
    }
}

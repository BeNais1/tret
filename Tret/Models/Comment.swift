import Foundation

struct Comment: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var postId: String
    var authorId: String
    var authorUsername: String
    var authorAvatarURL: String?
    var text: String
    var likesCount: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        postId: String,
        authorId: String,
        authorUsername: String,
        authorAvatarURL: String? = nil,
        text: String,
        likesCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorAvatarURL = authorAvatarURL
        self.text = text
        self.likesCount = likesCount
        self.createdAt = createdAt
    }
}

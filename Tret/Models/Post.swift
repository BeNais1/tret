import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var authorId: String
    var authorUsername: String
    var authorAvatarURL: String?
    var text: String?
    var code: String?
    var codeLineCount: Int
    var programmingLanguage: String?
    var imageURLs: [String]
    var likesCount: Int
    var commentsCount: Int
    var repostsCount: Int
    var createdAt: Date
    var updatedAt: Date?
    var topCommentPreview: TopCommentPreview?

    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorUsername: String,
        authorAvatarURL: String? = nil,
        text: String? = nil,
        code: String? = nil,
        codeLineCount: Int = 0,
        programmingLanguage: String? = nil,
        imageURLs: [String] = [],
        likesCount: Int = 0,
        commentsCount: Int = 0,
        repostsCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        topCommentPreview: TopCommentPreview? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorAvatarURL = authorAvatarURL
        self.text = text
        self.code = code
        self.codeLineCount = codeLineCount
        self.programmingLanguage = programmingLanguage
        self.imageURLs = imageURLs
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.repostsCount = repostsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.topCommentPreview = topCommentPreview
    }
}

struct TopCommentPreview: Codable, Hashable, Sendable {
    var commentId: String
    var authorUsername: String
    var text: String
    var likesCount: Int
}

extension Post {
    var hasText: Bool { (text?.isEmpty == false) }
    var hasCode: Bool { (code?.isEmpty == false) }
    var hasImages: Bool { !imageURLs.isEmpty }
    var isEmpty: Bool { !hasText && !hasCode && !hasImages }
}

import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var email: String
    var displayName: String
    var username: String
    var usernameLowercase: String
    var avatarURL: String?
    var bio: String
    var programmingLanguages: [String]
    var githubURL: String?
    var websiteURL: String?
    var hashtags: [String]
    var followersCount: Int
    var followingCount: Int
    var postsCount: Int
    var repostsCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        email: String,
        displayName: String,
        username: String,
        avatarURL: String? = nil,
        bio: String = "",
        programmingLanguages: [String] = [],
        githubURL: String? = nil,
        websiteURL: String? = nil,
        hashtags: [String] = [],
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        repostsCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.usernameLowercase = username.lowercased()
        self.avatarURL = avatarURL
        self.bio = bio
        self.programmingLanguages = programmingLanguages
        self.githubURL = githubURL
        self.websiteURL = websiteURL
        self.hashtags = hashtags
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.repostsCount = repostsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension AppUser {
    static let preview = AppUser(
        id: "preview-uid",
        email: "demo@tret.app",
        displayName: "Demo Developer",
        username: "demo_dev",
        avatarURL: nil,
        bio: "Senior iOS developer who loves Swift and clean architecture. Building Tret in spare time.",
        programmingLanguages: ["swift", "kotlin", "typescript"],
        githubURL: "https://github.com/demo",
        websiteURL: "https://demo.dev",
        hashtags: ["iosdev", "swiftui", "indiedev"],
        followersCount: 128,
        followingCount: 64,
        postsCount: 12,
        repostsCount: 3
    )
}

import Foundation

enum AppConstants {
    static let appName = "Tret"

    // Profile limits
    static let maxBioCharacters = 400
    static let maxProgrammingLanguages = 5
    static let maxHashtags = 3
    static let minUsernameLength = 3
    static let maxUsernameLength = 20

    // Post limits
    static let maxImagesPerPost = 10
    static let maxPostTextCharacters = 2000
    static let maxCodeLines = 1000

    // Feed
    static let feedPageSize = 20

    // Image upload
    static let maxAvatarBytes = 5 * 1024 * 1024
    static let maxImageBytes = 10 * 1024 * 1024

    // Validation
    static let usernameDebounceMilliseconds = 400
}

enum FirestorePath {
    static let users = "users"
    static let usernames = "usernames"
    static let posts = "posts"
    static let usernameChangeRequests = "usernameChangeRequests"

    static func user(_ uid: String) -> String { "\(users)/\(uid)" }
    static func username(_ lower: String) -> String { "\(usernames)/\(lower)" }
    static func post(_ id: String) -> String { "\(posts)/\(id)" }
    static func usernameChangeRequest(_ id: String) -> String { "\(usernameChangeRequests)/\(id)" }

    static func followers(of uid: String) -> String { "\(users)/\(uid)/followers" }
    static func following(of uid: String) -> String { "\(users)/\(uid)/following" }
    static func hiddenRecommended(of uid: String) -> String { "\(users)/\(uid)/hiddenRecommendedUsers" }
    static func userLikes(of uid: String) -> String { "\(users)/\(uid)/likes" }
    static func userReposts(of uid: String) -> String { "\(users)/\(uid)/reposts" }

    static func postLikes(of postId: String) -> String { "\(posts)/\(postId)/likes" }
    static func postComments(of postId: String) -> String { "\(posts)/\(postId)/comments" }
}

enum StoragePath {
    static func avatar(uid: String, filename: String) -> String { "avatars/\(uid)/\(filename)" }
    static func postImage(uid: String, postId: String, filename: String) -> String {
        "posts/\(uid)/\(postId)/\(filename)"
    }
}

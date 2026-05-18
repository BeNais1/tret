import Foundation

struct UsernameChangeRequest: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var userId: String
    var currentUsername: String
    var requestedUsername: String
    var reason: String
    var status: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        currentUsername: String,
        requestedUsername: String,
        reason: String,
        status: String = "pending",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.currentUsername = currentUsername
        self.requestedUsername = requestedUsername
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

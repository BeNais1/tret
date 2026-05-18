import Foundation
@preconcurrency import FirebaseFirestore

protocol UsernameChangeRequestServiceProtocol: Sendable {
    func create(_ request: UsernameChangeRequest) async throws
}

final class UsernameChangeRequestService: UsernameChangeRequestServiceProtocol, @unchecked Sendable {

    static let shared = UsernameChangeRequestService()

    private let firestore: Firestore

    private init() {
        self.firestore = Firestore.firestore()
    }

    func create(_ request: UsernameChangeRequest) async throws {
        try firestore
            .collection(FirestorePath.usernameChangeRequests)
            .document(request.id)
            .setData(from: request)
    }
}

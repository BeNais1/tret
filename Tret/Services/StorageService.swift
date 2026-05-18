import Foundation
import UIKit
import FirebaseStorage

protocol StorageServiceProtocol: Sendable {
    func uploadAvatar(userId: String, imageData: Data) async throws -> URL
    func uploadPostImage(userId: String, postId: String, index: Int, imageData: Data) async throws -> URL
}

final class StorageService: StorageServiceProtocol {

    static let shared = StorageService()

    private let storage: Storage

    private init() {
        self.storage = Storage.storage()
    }

    func uploadAvatar(userId: String, imageData: Data) async throws -> URL {
        guard imageData.count <= AppConstants.maxAvatarBytes else {
            throw ServiceError.uploadFailed("Слишком большой файл аватара")
        }
        let filename = "avatar_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = StoragePath.avatar(uid: userId, filename: filename)
        return try await upload(path: path, data: imageData, contentType: "image/jpeg")
    }

    func uploadPostImage(userId: String, postId: String, index: Int, imageData: Data) async throws -> URL {
        guard imageData.count <= AppConstants.maxImageBytes else {
            throw ServiceError.uploadFailed("Слишком большое изображение")
        }
        let filename = "img_\(index)_\(Int(Date().timeIntervalSince1970)).jpg"
        let path = StoragePath.postImage(uid: userId, postId: postId, filename: filename)
        return try await upload(path: path, data: imageData, contentType: "image/jpeg")
    }

    private func upload(path: String, data: Data, contentType: String) async throws -> URL {
        let ref = storage.reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }
}

extension UIImage {
    /// Сжимает изображение для аватара/превью с сохранением пропорций.
    func resized(maxDimension: CGFloat, jpegQuality: CGFloat = 0.85) -> Data? {
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1.0
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage.jpegData(compressionQuality: jpegQuality)
    }
}

import Foundation

enum ServiceError: Error, LocalizedError, Sendable {
    case notAuthenticated
    case userNotFound
    case usernameAlreadyTaken
    case invalidInput(String)
    case uploadFailed(String)
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Не выполнен вход"
        case .userNotFound: return "Пользователь не найден"
        case .usernameAlreadyTaken: return "Имя пользователя уже занято"
        case .invalidInput(let message): return message
        case .uploadFailed(let message): return "Ошибка загрузки: \(message)"
        case .underlying(let message): return message
        }
    }
}

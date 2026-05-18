import Foundation

enum UsernameValidationResult: Equatable {
    case empty
    case tooShort
    case tooLong
    case invalidCharacters
    case startsOrEndsWithUnderscore
    case valid
}

enum BioValidationResult: Equatable {
    case tooLong
    case valid
}

enum HashtagValidationResult: Equatable {
    case empty
    case invalidCharacters
    case tooShort
    case tooLong
    case valid
}

enum Validators {

    private static let usernameAllowed: CharacterSet = {
        CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
    }()

    static func validateUsername(_ raw: String) -> UsernameValidationResult {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.count < AppConstants.minUsernameLength { return .tooShort }
        if trimmed.count > AppConstants.maxUsernameLength { return .tooLong }
        if trimmed.unicodeScalars.contains(where: { !usernameAllowed.contains($0) }) {
            return .invalidCharacters
        }
        if trimmed.first == "_" || trimmed.last == "_" {
            return .startsOrEndsWithUnderscore
        }
        return .valid
    }

    static func validateBio(_ raw: String) -> BioValidationResult {
        raw.count > AppConstants.maxBioCharacters ? .tooLong : .valid
    }

    static func normalizeHashtag(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasPrefix("#") { s.removeFirst() }
        return s.lowercased()
    }

    static func validateHashtag(_ raw: String) -> HashtagValidationResult {
        let s = normalizeHashtag(raw)
        if s.isEmpty { return .empty }
        if s.count < 2 { return .tooShort }
        if s.count > 24 { return .tooLong }
        let allowed = CharacterSet.alphanumerics
        if s.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return .invalidCharacters
        }
        return .valid
    }
}

extension UsernameValidationResult {
    var userMessage: String? {
        switch self {
        case .valid: return nil
        case .empty: return "Введите имя пользователя"
        case .tooShort: return "Минимум \(AppConstants.minUsernameLength) символа"
        case .tooLong: return "Максимум \(AppConstants.maxUsernameLength) символов"
        case .invalidCharacters: return "Разрешены только строчные латинские буквы, цифры и _"
        case .startsOrEndsWithUnderscore: return "Не может начинаться или заканчиваться на _"
        }
    }
}

extension HashtagValidationResult {
    var userMessage: String? {
        switch self {
        case .valid: return nil
        case .empty: return "Введите хэштег"
        case .tooShort: return "Слишком короткий"
        case .tooLong: return "Слишком длинный"
        case .invalidCharacters: return "Только буквы и цифры"
        }
    }
}

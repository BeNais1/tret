import Foundation

enum UsernameGenerator {

    static func slugify(_ raw: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        let lowered = raw.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) { return Character(scalar) }
            return "_"
        }
        var result = String(scalars)
        while result.contains("__") {
            result = result.replacingOccurrences(of: "__", with: "_")
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return result
    }

    /// Возвращает список подсказок имени пользователя на основе displayName и email.
    /// Гарантирует валидность по `Validators.validateUsername`.
    static func suggestions(displayName: String?, email: String?, count: Int = 5) -> [String] {
        var seeds: [String] = []

        if let displayName, !displayName.isEmpty {
            let slug = slugify(displayName)
            if !slug.isEmpty { seeds.append(slug) }
            let parts = displayName.split(separator: " ").map { String($0).lowercased() }
            if let first = parts.first, !first.isEmpty {
                seeds.append(slugify(first))
            }
            if parts.count >= 2 {
                let initials = parts.prefix(2).map { $0.prefix(1) }.joined()
                seeds.append(slugify(initials + (parts.last ?? "")))
            }
        }

        if let email, let prefix = email.split(separator: "@").first {
            seeds.append(slugify(String(prefix)))
        }

        if seeds.isEmpty { seeds = ["dev"] }

        var result: [String] = []
        var used = Set<String>()
        for seed in seeds {
            for candidate in candidates(from: seed) {
                guard Validators.validateUsername(candidate) == .valid else { continue }
                if used.insert(candidate).inserted {
                    result.append(candidate)
                    if result.count >= count { return result }
                }
            }
        }
        return result
    }

    private static func candidates(from seed: String) -> [String] {
        let trimmed = seed
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
            .prefix(AppConstants.maxUsernameLength)
        let base = String(trimmed)
        guard base.count >= AppConstants.minUsernameLength else {
            return []
        }
        var out: [String] = [base]
        for suffix in ["dev", "ios", "code"] {
            let candidate = (base + "_" + suffix).prefix(AppConstants.maxUsernameLength)
            out.append(String(candidate))
        }
        for _ in 0..<3 {
            let n = Int.random(in: 10...9999)
            let candidate = (base + "_\(n)").prefix(AppConstants.maxUsernameLength)
            out.append(String(candidate))
        }
        return out
    }
}

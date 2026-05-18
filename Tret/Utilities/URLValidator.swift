import Foundation

enum URLValidator {

    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var candidate = trimmed
        if !candidate.lowercased().hasPrefix("http://") &&
           !candidate.lowercased().hasPrefix("https://") {
            candidate = "https://" + candidate
        }

        guard let url = URL(string: candidate),
              let host = url.host,
              host.contains(".") else {
            return nil
        }
        return candidate
    }

    static func isValid(_ raw: String) -> Bool {
        normalize(raw) != nil
    }

    static func isValidGitHub(_ raw: String) -> Bool {
        guard let normalized = normalize(raw),
              let url = URL(string: normalized),
              let host = url.host?.lowercased() else { return false }
        return host == "github.com" || host == "www.github.com"
    }
}

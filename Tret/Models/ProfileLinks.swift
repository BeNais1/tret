import Foundation

struct ProfileLinks: Hashable, Sendable {
    var github: String?
    var website: String?

    init(github: String? = nil, website: String? = nil) {
        self.github = github?.nilIfEmpty
        self.website = website?.nilIfEmpty
    }

    var hasAny: Bool { github != nil || website != nil }

    static func display(github: String?) -> String? {
        guard let github, let url = URL(string: github) else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty ? url.host : "@\(path)"
    }

    static func display(website: String?) -> String? {
        guard let website, let url = URL(string: website) else { return nil }
        return url.host?.replacingOccurrences(of: "www.", with: "")
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

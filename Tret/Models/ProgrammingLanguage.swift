import Foundation
import SwiftUI

struct ProgrammingLanguage: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let colorHex: String
    let aliases: [String]

    var color: Color { Color(hex: colorHex) ?? .accentColor }

    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        if displayName.lowercased().contains(q) { return true }
        if id.lowercased().contains(q) { return true }
        return aliases.contains { $0.lowercased().contains(q) }
    }
}

extension ProgrammingLanguage {
    static let all: [ProgrammingLanguage] = [
        .init(id: "swift",      displayName: "Swift",       colorHex: "#F05138", aliases: ["swiftui", "ios"]),
        .init(id: "kotlin",     displayName: "Kotlin",      colorHex: "#7F52FF", aliases: ["android"]),
        .init(id: "javascript", displayName: "JavaScript",  colorHex: "#F7DF1E", aliases: ["js", "node"]),
        .init(id: "typescript", displayName: "TypeScript",  colorHex: "#3178C6", aliases: ["ts"]),
        .init(id: "python",     displayName: "Python",      colorHex: "#3776AB", aliases: ["py"]),
        .init(id: "java",       displayName: "Java",        colorHex: "#B07219", aliases: []),
        .init(id: "c",          displayName: "C",           colorHex: "#555555", aliases: []),
        .init(id: "cpp",        displayName: "C++",         colorHex: "#F34B7D", aliases: ["c++", "cplusplus"]),
        .init(id: "csharp",     displayName: "C#",          colorHex: "#178600", aliases: ["c#", "dotnet"]),
        .init(id: "go",         displayName: "Go",          colorHex: "#00ADD8", aliases: ["golang"]),
        .init(id: "rust",       displayName: "Rust",        colorHex: "#DEA584", aliases: []),
        .init(id: "php",        displayName: "PHP",         colorHex: "#4F5D95", aliases: []),
        .init(id: "ruby",       displayName: "Ruby",        colorHex: "#701516", aliases: ["rails"]),
        .init(id: "sql",        displayName: "SQL",         colorHex: "#E38C00", aliases: ["postgres", "mysql", "sqlite"]),
        .init(id: "dart",       displayName: "Dart",        colorHex: "#00B4AB", aliases: ["flutter"]),
        .init(id: "lua",        displayName: "Lua",         colorHex: "#000080", aliases: []),
        .init(id: "robloxlua",  displayName: "Roblox Lua",  colorHex: "#E2231A", aliases: ["roblox", "luau"]),
        .init(id: "html_css",   displayName: "HTML/CSS",    colorHex: "#E34F26", aliases: ["html", "css", "web"]),
        .init(id: "scala",      displayName: "Scala",       colorHex: "#C22D40", aliases: []),
        .init(id: "shell",      displayName: "Shell",       colorHex: "#89E051", aliases: ["bash", "zsh", "sh"]),
        .init(id: "powershell", displayName: "PowerShell",  colorHex: "#012456", aliases: ["pwsh"]),
        .init(id: "objc",       displayName: "Objective-C", colorHex: "#438EFF", aliases: ["objective-c"]),
        .init(id: "elixir",     displayName: "Elixir",      colorHex: "#6E4A7E", aliases: []),
        .init(id: "erlang",     displayName: "Erlang",      colorHex: "#B83998", aliases: []),
        .init(id: "haskell",    displayName: "Haskell",     colorHex: "#5E5086", aliases: []),
        .init(id: "ocaml",      displayName: "OCaml",       colorHex: "#3BE133", aliases: []),
        .init(id: "perl",       displayName: "Perl",        colorHex: "#0298C3", aliases: []),
        .init(id: "r",          displayName: "R",           colorHex: "#198CE7", aliases: []),
        .init(id: "matlab",     displayName: "MATLAB",      colorHex: "#E16737", aliases: []),
        .init(id: "solidity",   displayName: "Solidity",    colorHex: "#AA6746", aliases: ["web3", "eth"]),
        .init(id: "zig",        displayName: "Zig",         colorHex: "#EC915C", aliases: []),
        .init(id: "nim",        displayName: "Nim",         colorHex: "#FFE953", aliases: []),
        .init(id: "yaml",       displayName: "YAML",        colorHex: "#CB171E", aliases: []),
        .init(id: "json",       displayName: "JSON",        colorHex: "#292929", aliases: []),
        .init(id: "other",      displayName: "Other",       colorHex: "#888888", aliases: [])
    ]

    static func find(id: String?) -> ProgrammingLanguage? {
        guard let id, !id.isEmpty else { return nil }
        return all.first { $0.id == id }
    }

    static func search(_ query: String) -> [ProgrammingLanguage] {
        all.filter { $0.matches(query: query) }
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

import SwiftUI

struct CodeRenderInput: Sendable {
    let source: String
    let languageId: String?
    let fontSize: CGFloat
}

protocol CodeRenderer: Sendable {
    func attributed(_ input: CodeRenderInput) -> AttributedString
}

struct PlainCodeRenderer: CodeRenderer {
    func attributed(_ input: CodeRenderInput) -> AttributedString {
        var string = AttributedString(input.source)
        string.font = .system(size: input.fontSize, design: .monospaced)
        string.foregroundColor = .primary
        return string
    }
}

/// Точка подмены реализации рендерера.
/// Для будущего syntax highlighting достаточно записать сюда другой `CodeRenderer`
/// до показа первой `CodeSnippetPreviewView`/`FullCodeViewerView` —
/// сами вьюхи не меняются.
enum CodeRendererProvider {
    nonisolated(unsafe) static var shared: any CodeRenderer = PlainCodeRenderer()
}

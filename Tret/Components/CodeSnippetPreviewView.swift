import SwiftUI

struct CodeSnippetPreviewView: View {
    let code: String
    let languageId: String?
    let lineCount: Int

    @State private var showFullViewer = false

    private static let previewLineLimit = 10
    private static let previewMaxHeight: CGFloat = 220
    private static let previewFontSize: CGFloat = 13

    private var renderer: any CodeRenderer { CodeRendererProvider.shared }

    private var language: ProgrammingLanguage? {
        ProgrammingLanguage.find(id: languageId)
    }

    private var needsTruncation: Bool {
        lineCount > Self.previewLineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(renderer.attributed(input))
                        .textSelection(.disabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: needsTruncation ? Self.previewMaxHeight : nil, alignment: .top)
                .clipped()
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(alignment: .bottom) {
                    if needsTruncation {
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemGroupedBackground).opacity(0),
                                Color(.secondarySystemGroupedBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 48)
                        .allowsHitTesting(false)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                }

                if let language {
                    LanguageBadgeView(language: language, isSelected: true)
                        .padding(8)
                }
            }

            if needsTruncation {
                Button {
                    showFullViewer = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Открыть код целиком")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color("BrandGradientStart"))
                }
                .buttonStyle(.plain)
            }
        }
        .fullScreenCover(isPresented: $showFullViewer) {
            FullCodeViewerView(code: code, languageId: languageId)
        }
    }

    private var input: CodeRenderInput {
        CodeRenderInput(
            source: code,
            languageId: languageId,
            fontSize: Self.previewFontSize
        )
    }
}

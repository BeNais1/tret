import SwiftUI
import UIKit

struct FullCodeViewerView: View {
    let code: String
    let languageId: String?

    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    private static let fontSize: CGFloat = 14

    private var renderer: any CodeRenderer { CodeRendererProvider.shared }

    private var language: ProgrammingLanguage? {
        ProgrammingLanguage.find(id: languageId)
    }

    var body: some View {
        NavigationStack {
            ScrollView([.vertical, .horizontal]) {
                Text(renderer.attributed(input))
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(language?.displayName ?? "Код")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation(.easeInOut(duration: 0.15)) { didCopy = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.2)) { didCopy = false }
                            }
                        }
                    } label: {
                        if didCopy {
                            Label("Скопировано", systemImage: "checkmark")
                        } else {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                    }
                }
                if let language {
                    ToolbarItem(placement: .principal) {
                        LanguageBadgeView(language: language, isSelected: true)
                    }
                }
            }
        }
    }

    private var input: CodeRenderInput {
        CodeRenderInput(
            source: code,
            languageId: languageId,
            fontSize: Self.fontSize
        )
    }
}

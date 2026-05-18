import SwiftUI

struct LanguageBadgeView: View {
    let language: ProgrammingLanguage
    let isSelected: Bool
    let onTap: (() -> Void)?
    let onRemove: (() -> Void)?

    init(
        language: ProgrammingLanguage,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.language = language
        self.isSelected = isSelected
        self.onTap = onTap
        self.onRemove = onRemove
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(language.color)
                    .frame(width: 8, height: 8)

                Text(language.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                if let onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(4)
                            .background(.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? language.color.opacity(0.18) : Color.primary.opacity(0.05))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? language.color.opacity(0.6) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

#Preview {
    let lang = ProgrammingLanguage.all.first!
    return HStack {
        LanguageBadgeView(language: lang, isSelected: true) { }
        LanguageBadgeView(language: lang, isSelected: false, onTap: {}, onRemove: {})
    }
    .padding()
}

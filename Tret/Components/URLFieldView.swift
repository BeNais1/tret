import SwiftUI

struct URLFieldView: View {
    enum Mode: Sendable {
        case generic
        case github
    }

    let title: String
    let placeholder: String
    let icon: String
    let mode: Mode
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    .keyboardType(.URL)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isInvalid ? .red.opacity(0.5) : .clear, lineWidth: 1)
            )

            if isInvalid {
                Text(invalidMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    var isInvalid: Bool {
        guard !text.isEmpty else { return false }
        switch mode {
        case .generic: return !URLValidator.isValid(text)
        case .github:  return !URLValidator.isValidGitHub(text)
        }
    }

    private var invalidMessage: String {
        switch mode {
        case .generic: return "Введите корректную ссылку"
        case .github:  return "Введите корректную ссылку на GitHub"
        }
    }
}

import SwiftUI

struct OnboardingStep4LinksHashtags: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(
                    title: "Ссылки и интересы",
                    subtitle: "Покажи, где тебя можно найти и о чём ты пишешь."
                )

                inputField(
                    title: "GitHub",
                    placeholder: "github.com/username",
                    icon: "chevron.left.forwardslash.chevron.right",
                    text: Binding(
                        get: { viewModel.githubRaw },
                        set: { viewModel.githubRaw = $0 }
                    ),
                    isInvalid: !viewModel.githubRaw.isEmpty && !URLValidator.isValidGitHub(viewModel.githubRaw),
                    invalidMessage: "Введите корректную ссылку на GitHub"
                )

                inputField(
                    title: "Личный сайт",
                    placeholder: "https://example.dev",
                    icon: "globe",
                    text: Binding(
                        get: { viewModel.websiteRaw },
                        set: { viewModel.websiteRaw = $0 }
                    ),
                    isInvalid: !viewModel.websiteRaw.isEmpty && !URLValidator.isValid(viewModel.websiteRaw),
                    invalidMessage: "Введите корректную ссылку"
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Хэштеги")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(viewModel.hashtags.count)/\(AppConstants.maxHashtags)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("#").foregroundStyle(.secondary)
                        TextField("iosdev, backend, gamedev", text: $viewModel.hashtagInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit { viewModel.addHashtag() }
                            .disabled(!viewModel.canAddMoreHashtags)

                        Button {
                            viewModel.addHashtag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.accent)
                        }
                        .disabled(!viewModel.canAddMoreHashtags || viewModel.hashtagInput.isEmpty)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if !viewModel.hashtags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.hashtags, id: \.self) { tag in
                                HashtagChipView(hashtag: tag, onRemove: { viewModel.removeHashtag(tag) })
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func inputField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>,
        isInvalid: Bool,
        invalidMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(.secondary)
                TextField(placeholder, text: text)
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
}

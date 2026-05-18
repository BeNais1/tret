import SwiftUI

struct OnboardingStep5Preview: View {

    @Bindable var viewModel: OnboardingViewModel

    private var previewUser: AppUser {
        AppUser(
            id: viewModel.pending.uid,
            email: viewModel.pending.email,
            displayName: viewModel.pending.displayName.isEmpty ? viewModel.username : viewModel.pending.displayName,
            username: viewModel.username,
            avatarURL: viewModel.pending.photoURL?.absoluteString,
            bio: viewModel.bio,
            programmingLanguages: viewModel.selectedLanguages,
            githubURL: URLValidator.normalize(viewModel.githubRaw),
            websiteURL: URLValidator.normalize(viewModel.websiteRaw),
            hashtags: viewModel.hashtags
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(
                    title: "Готово?",
                    subtitle: "Вот как твой профиль увидят другие. Можно вернуться назад и поправить."
                )

                ProfilePreviewCard(user: previewUser)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

struct ProfilePreviewCard: View {
    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                ProfileAvatarView(
                    urlString: user.avatarURL,
                    size: 64,
                    initials: ProfileAvatarView.initials(from: user.displayName)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName.isEmpty ? "@\(user.username)" : user.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !user.programmingLanguages.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(user.programmingLanguages, id: \.self) { id in
                        if let lang = ProgrammingLanguage.find(id: id) {
                            LanguageBadgeView(language: lang, isSelected: true)
                        }
                    }
                }
            }

            if !user.hashtags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(user.hashtags, id: \.self) { tag in
                        HashtagChipView(hashtag: tag)
                    }
                }
            }

            if user.githubURL != nil || user.websiteURL != nil {
                VStack(alignment: .leading, spacing: 6) {
                    if let github = user.githubURL {
                        linkRow(icon: "chevron.left.forwardslash.chevron.right",
                                text: ProfileLinks.display(github: github) ?? github)
                    }
                    if let website = user.websiteURL {
                        linkRow(icon: "globe",
                                text: ProfileLinks.display(website: website) ?? website)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func linkRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.secondary)
    }
}

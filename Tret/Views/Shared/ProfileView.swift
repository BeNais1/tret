import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    let user: AppUser
    let viewerUserId: String
    var hidesTabBar = false

    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showUsernameRequest = false
    @State private var recentPosts: [Post] = []
    @State private var isLoadingPosts = false
    @State private var postsErrorMessage: String?
    @State private var isFollowing: Bool?
    @State private var isFollowBusy = false
    @State private var followersCountOverride: Int?
    @State private var followErrorMessage: String?

    private let postService: PostServiceProtocol = PostService.shared
    private let followService: FollowServiceProtocol = FollowService.shared

    private var isOwnProfile: Bool {
        user.id == viewerUserId
    }

    private var followersDisplayCount: Int {
        followersCountOverride ?? user.followersCount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfilePreviewCard(user: user)

                profileActionButton

                statsSection
                recentPostsSection
            }
            .padding(20)
        }
        .navigationTitle("Профиль")
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isOwnProfile ? "Профиль" : "@\(user.username)")
        .toolbar(hidesTabBar ? .hidden : .visible, for: .tabBar)
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Настройки")
            }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ProfileSettingsView(user: user)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(user: user)
            }
        }
        .task(id: user.id) {
            await loadRecentPosts()
            await loadFollowState()
        }
        .refreshable {
            await loadRecentPosts()
            await loadFollowState()
        }
        .alert("Не удалось загрузить посты", isPresented: postsErrorBinding) {
            Button("OK", role: .cancel) { postsErrorMessage = nil }
        } message: {
            Text(postsErrorMessage ?? "")
        }
        .alert("Не удалось обновить подписку", isPresented: followErrorBinding) {
            Button("OK", role: .cancel) { followErrorMessage = nil }
        } message: {
            Text(followErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var profileActionButton: some View {
        if isOwnProfile {
            GlassButton(style: .secondary) {
                showEditProfile = true
            } label: {
                Label("Редактировать профиль", systemImage: "pencil")
            }
        } else {
            switch isFollowing {
            case .some(true):
                GlassButton(
                    style: .secondary,
                    isLoading: isFollowBusy
                ) {
                    Task { await toggleFollow(currentlyFollowing: true) }
                } label: {
                    Label("Вы подписаны", systemImage: "checkmark")
                }
            case .some(false):
                GlassButton(
                    style: .primary,
                    isLoading: isFollowBusy
                ) {
                    Task { await toggleFollow(currentlyFollowing: false) }
                } label: {
                    Label("Подписаться", systemImage: "person.fill.badge.plus")
                }
            case .none:
                GlassButton(
                    style: .secondary,
                    isLoading: true,
                    isEnabled: false
                ) {
                    // no-op: state still loading
                } label: {
                    Text("")
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Статистика")
                .font(.headline)

            HStack(spacing: 12) {
                statColumn(title: "Посты", value: user.postsCount)
                statColumn(title: "Подписчики", value: followersDisplayCount)
                statColumn(title: "Подписки", value: user.followingCount)
            }
        }
    }

    private var followErrorBinding: Binding<Bool> {
        Binding(
            get: { followErrorMessage != nil },
            set: { isPresented in
                if !isPresented { followErrorMessage = nil }
            }
        )
    }

    @MainActor
    private func loadFollowState() async {
        guard !isOwnProfile else { return }
        do {
            let following = try await followService.isFollowing(
                currentUserId: viewerUserId,
                targetUserId: user.id
            )
            isFollowing = following
        } catch {
            followErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func toggleFollow(currentlyFollowing: Bool) async {
        guard !isFollowBusy else { return }
        isFollowBusy = true
        defer { isFollowBusy = false }

        let baseCount = followersDisplayCount

        do {
            if currentlyFollowing {
                followersCountOverride = max(0, baseCount - 1)
                try await followService.unfollow(
                    currentUserId: viewerUserId,
                    targetUserId: user.id
                )
                isFollowing = false
            } else {
                followersCountOverride = baseCount + 1
                try await followService.follow(
                    currentUserId: viewerUserId,
                    targetUserId: user.id
                )
                isFollowing = true
            }
        } catch {
            followersCountOverride = baseCount
            followErrorMessage = error.localizedDescription
        }
    }

    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Недавние посты")
                .font(.headline)

            if isLoadingPosts && recentPosts.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 10)
            } else if recentPosts.isEmpty {
                Text("Пока нет постов.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(recentPosts) { post in
                        NavigationLink {
                            ProfilePostDetailsView(post: post)
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            ProfilePostRow(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var postsErrorBinding: Binding<Bool> {
        Binding(
            get: { postsErrorMessage != nil },
            set: { isPresented in
                if !isPresented { postsErrorMessage = nil }
            }
        )
    }

    @MainActor
    private func loadRecentPosts() async {
        guard !isLoadingPosts else { return }
        isLoadingPosts = true
        defer { isLoadingPosts = false }

        do {
            let result = try await postService.fetchByAuthor(
                authorId: user.id,
                pageSize: 20,
                after: nil
            )
            recentPosts = result.posts
        } catch {
            postsErrorMessage = error.localizedDescription
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Аккаунт")
                .font(.headline)

            Button {
                showUsernameRequest = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "at")
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color("BrandGradientStart"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("@\(user.username)")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Сменить username можно через запрос админам")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func statColumn(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProfilePostRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateFormatterHelper.shortRelative(from: post.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            if let text = post.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 14))
                    .lineLimit(3)
            } else if let code = post.code, !code.isEmpty {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(3)
            } else if !post.imageURLs.isEmpty {
                Text("Пост с изображениями")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                Label("\(post.likesCount)", systemImage: "heart")
                Label("\(post.commentsCount)", systemImage: "message")
                Label("\(post.repostsCount)", systemImage: "arrow.2.squarepath")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProfilePostDetailsView: View {
    let post: Post

    @State private var lightboxStartIndex = 0
    @State private var isLightboxPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("@\(post.authorUsername)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let text = post.text, !text.isEmpty {
                    ExpandableTextView(text: text, font: .system(size: 16))
                }

                if let code = post.code, !code.isEmpty {
                    CodeSnippetPreviewView(
                        code: code,
                        languageId: post.programmingLanguage,
                        lineCount: post.codeLineCount
                    )
                } else if let language = ProgrammingLanguage.find(id: post.programmingLanguage) {
                    HStack {
                        LanguageBadgeView(language: language, isSelected: true)
                        Spacer()
                    }
                }

                if !post.imageURLs.isEmpty {
                    PostImageGallery(urls: post.imageURLs) { index in
                        lightboxStartIndex = index
                        isLightboxPresented = true
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Статистика")
                        .font(.headline)

                    HStack(spacing: 14) {
                        Label("\(post.likesCount)", systemImage: "heart.fill")
                        Label("\(post.commentsCount)", systemImage: "message.fill")
                        Label("\(post.repostsCount)", systemImage: "arrow.2.squarepath")
                    }
                    .font(.subheadline)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(16)
        }
        .navigationTitle("Пост")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $isLightboxPresented) {
            ImageLightboxView(urls: post.imageURLs, startIndex: lightboxStartIndex)
        }
    }
}

private struct ProfileSettingsView: View {
    let user: AppUser

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tret.appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @State private var showUsernameRequest = false

    var body: some View {
        Form {
            Section("Тема") {
                Picker("Оформление", selection: $appThemeRaw) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.title, systemImage: theme.icon)
                            .tag(theme.rawValue)
                    }
                }
            }

            Section("Аккаунт") {
                Button {
                    showUsernameRequest = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Сменить username")
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    appState.signOut()
                    dismiss()
                } label: {
                    Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUsernameRequest) {
            NavigationStack {
                UsernameChangeRequestView(user: user)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") { dismiss() }
            }
        }
    }
}

private struct EditProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let user: AppUser

    @State private var displayName: String
    @State private var bio: String
    @State private var selectedLanguages: [String]
    @State private var githubRaw: String
    @State private var websiteRaw: String
    @State private var hashtags: [String]
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var selectedAvatarImage: UIImage?
    @State private var selectedAvatarData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let userService: UserServiceProtocol = UserService.shared
    private let storageService: StorageServiceProtocol = StorageService.shared

    init(user: AppUser) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _bio = State(initialValue: user.bio)
        _selectedLanguages = State(initialValue: user.programmingLanguages)
        _githubRaw = State(initialValue: user.githubURL ?? "")
        _websiteRaw = State(initialValue: user.websiteURL ?? "")
        _hashtags = State(initialValue: user.hashtags)
    }

    private var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var githubInvalid: Bool {
        !githubRaw.isEmpty && !URLValidator.isValidGitHub(githubRaw)
    }

    private var websiteInvalid: Bool {
        !websiteRaw.isEmpty && !URLValidator.isValid(websiteRaw)
    }

    private var bioTooLong: Bool {
        Validators.validateBio(bio) == .tooLong
    }

    private var canSave: Bool {
        !isSaving
            && !trimmedDisplayName.isEmpty
            && !bioTooLong
            && !githubInvalid
            && !websiteInvalid
            && selectedLanguages.count <= AppConstants.maxProgrammingLanguages
            && hashtags.count <= AppConstants.maxHashtags
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                avatarEditor
                displayNameSection
                bioSection
                languagesSection
                linksSection
                hashtagsSection
                usernameLockedSection
            }
            .padding(20)
        }
        .navigationTitle("Редактировать")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Сохранить").fontWeight(.semibold)
                    }
                }
                .disabled(!canSave)
            }
        }
        .onChange(of: selectedAvatarItem) { _, newItem in
            Task { await loadAvatar(from: newItem) }
        }
        .alert("Не удалось сохранить", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Имя аккаунта")
                .font(.subheadline.weight(.semibold))

            TextField("Имя", text: $displayName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Био")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(bio.count) / \(AppConstants.maxBioCharacters)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(bioTooLong ? .red : .secondary)
            }

            ZStack(alignment: .topLeading) {
                if bio.isEmpty {
                    Text("Расскажи о себе, своих проектах и интересах…")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $bio)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(bioTooLong ? .red.opacity(0.5) : .clear, lineWidth: 1)
            )

            if bioTooLong {
                Text("Био не должно превышать \(AppConstants.maxBioCharacters) символов.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Языки программирования")
                .font(.subheadline.weight(.semibold))

            LanguagePickerView(selected: $selectedLanguages)
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            URLFieldView(
                title: "GitHub",
                placeholder: "github.com/username",
                icon: "chevron.left.forwardslash.chevron.right",
                mode: .github,
                text: $githubRaw
            )

            URLFieldView(
                title: "Личный сайт",
                placeholder: "https://example.dev",
                icon: "globe",
                mode: .generic,
                text: $websiteRaw
            )
        }
    }

    private var hashtagsSection: some View {
        HashtagPickerView(hashtags: $hashtags)
    }

    private var usernameLockedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.subheadline.weight(.semibold))

            HStack {
                Text("@\(user.username)")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Username меняется отдельно — через запрос админам.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var avatarEditor: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                avatarPreview
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())

                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color("BrandGradientStart"), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Фото профиля")
                    .font(.headline)
                Text("Новое фото сохранится после кнопки «Сохранить».")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let selectedAvatarImage {
            Image(uiImage: selectedAvatarImage)
                .resizable()
                .scaledToFill()
        } else {
            ProfileAvatarView(
                urlString: user.avatarURL,
                size: 92,
                initials: ProfileAvatarView.initials(from: displayName)
            )
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
    }

    @MainActor
    private func loadAvatar(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let rawData = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: rawData),
              let resizedData = image.resized(maxDimension: 1024, jpegQuality: 0.86),
              let resizedImage = UIImage(data: resizedData)
        else {
            errorMessage = "Не удалось открыть выбранное изображение."
            return
        }
        selectedAvatarImage = resizedImage
        selectedAvatarData = resizedData
    }

    @MainActor
    private func save() async {
        guard canSave else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            var updated = user
            updated.displayName = trimmedDisplayName
            updated.bio = bio
            updated.programmingLanguages = selectedLanguages
            updated.githubURL = githubRaw.isEmpty ? nil : URLValidator.normalize(githubRaw)
            updated.websiteURL = websiteRaw.isEmpty ? nil : URLValidator.normalize(websiteRaw)
            updated.hashtags = hashtags

            if let selectedAvatarData {
                let url = try await storageService.uploadAvatar(userId: user.id, imageData: selectedAvatarData)
                updated.avatarURL = url.absoluteString
            }

            try await userService.updateUser(updated)
            await appState.refreshCurrentUser()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct UsernameChangeRequestView: View {
    @Environment(\.dismiss) private var dismiss

    let user: AppUser

    @State private var requestedUsername = ""
    @State private var reason = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private let requestService: UsernameChangeRequestServiceProtocol = UsernameChangeRequestService.shared
    private let userService: UserServiceProtocol = UserService.shared

    var body: some View {
        ScrollView {
            requestForm
            .padding(20)
        }
        .navigationTitle("Смена username")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await submit() } } label: { submitButtonLabel }
                .disabled(!canSubmit || isSubmitting)
            }
        }
        .alert("Не удалось отправить", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Запрос отправлен", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Username останется прежним, пока админы не одобрят смену.")
        }
    }

    private var requestForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            UsernameChangeCurrentSection(username: user.username)
            UsernameChangeRequestedUsernameSection(
                username: Binding(
                    get: { requestedUsername },
                    set: { requestedUsername = $0.lowercased() }
                ),
                message: usernameMessage,
                messageColor: usernameMessageColor,
                borderColor: usernameBorderColor
            )
            UsernameChangeReasonSection(
                reason: Binding(
                    get: { reason },
                    set: { reason = String($0.prefix(600)) }
                ),
                isValid: reasonIsValid
            )
        }
    }

    @ViewBuilder
    private var submitButtonLabel: some View {
        if isSubmitting {
            ProgressView()
        } else {
            Text("Отправить").fontWeight(.semibold)
        }
    }

    private var normalizedUsername: String {
        requestedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var usernameValidation: UsernameValidationResult {
        Validators.validateUsername(normalizedUsername)
    }

    private var reasonIsValid: Bool {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12
    }

    private var canSubmit: Bool {
        usernameValidation == .valid
        && normalizedUsername.lowercased() != user.usernameLowercase
        && reasonIsValid
    }

    private var usernameMessage: String? {
        if normalizedUsername.isEmpty { return nil }
        if normalizedUsername.lowercased() == user.usernameLowercase {
            return "Это уже твой текущий username"
        }
        return usernameValidation.userMessage
    }

    private var usernameMessageColor: Color {
        usernameValidation == .valid ? .secondary : .red
    }

    private var usernameBorderColor: Color {
        guard !normalizedUsername.isEmpty else { return .clear }
        return usernameValidation == .valid ? .primary.opacity(0.06) : .red.opacity(0.45)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
    }

    @MainActor
    private func submit() async {
        guard canSubmit, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let username = normalizedUsername.lowercased()
            let available = try await userService.checkUsernameAvailable(username)
            guard available else {
                errorMessage = "Этот username уже занят."
                return
            }

            let request = UsernameChangeRequest(
                userId: user.id,
                currentUsername: user.username,
                requestedUsername: username,
                reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try await requestService.create(request)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct UsernameChangeCurrentSection: View {
    let username: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Текущий username")
                .font(.subheadline.weight(.semibold))
            Text("@\(username)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
    }
}

private struct UsernameChangeRequestedUsernameSection: View {
    @Binding var username: String
    let message: String?
    let messageColor: Color
    let borderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Новый username")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Text("@")
                    .foregroundStyle(.secondary)
                TextField("new_username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(messageColor)
            }
        }
    }
}

private struct UsernameChangeReasonSection: View {
    @Binding var reason: String
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Причина")
                .font(.subheadline.weight(.semibold))

            editor

            HStack {
                Text("Минимум 12 символов")
                    .font(.caption)
                    .foregroundStyle(isValid ? Color.secondary : Color.red)
                Spacer()
                Text("\(reason.count) / 600")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if reason.isEmpty {
                Text("Опиши, почему username нужно изменить. Запрос увидят админы.")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $reason)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

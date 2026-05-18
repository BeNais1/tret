import SwiftUI
import FirebaseFirestore

struct HomeFeedView: View {
    let currentUser: AppUser
    let refreshToken: Int

    @State private var feedKind: FeedKind = .recommended
    @State private var posts: [Post] = []
    @State private var lastDocument: DocumentSnapshot?
    @State private var hiddenUserIds: Set<String> = []
    @State private var followingUserIds: Set<String> = []
    @State private var followStateCache: [String: Bool] = [:]
    @State private var topCommentCache: [String: TopCommentPreview?] = [:]
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var canLoadMore = true
    @State private var errorMessage: String?

    private let feedService: FeedServiceProtocol = FeedService.shared
    private let followService: FollowServiceProtocol = FollowService.shared

    var body: some View {
        VStack(spacing: 0) {
            Picker("Лента", selection: $feedKind) {
                Text("Рекомендации").tag(FeedKind.recommended)
                Text("Подписки").tag(FeedKind.following)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Group {
                if isLoading && posts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if posts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                FeedPostCard(
                                    post: post,
                                    currentUser: currentUser,
                                    followStateCache: $followStateCache,
                                    topCommentCache: $topCommentCache,
                                    onHide: { Task { await hideAuthor(authorId: post.authorId) } }
                                )
                                .onAppear {
                                    Task { await loadMoreIfNeeded(currentPost: post) }
                                }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Лента")
        .background(Color(.systemGroupedBackground))
        .task(id: refreshToken) { await reload() }
        .refreshable { await reload() }
        .onChange(of: feedKind) { _, _ in
            Task { await switchFeed() }
        }
        .alert("Не удалось загрузить ленту", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch feedKind {
        case .recommended:
            ContentUnavailableView(
                "Пока нет постов",
                systemImage: "newspaper",
                description: Text("Опубликуй первый пост или потяни экран вниз для обновления.")
            )
        case .following:
            ContentUnavailableView(
                "Ничего от твоих подписок",
                systemImage: "person.2",
                description: Text("Подпишись на других программистов — здесь появятся их посты.")
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
    private func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let hiddenTask = feedService.fetchHiddenUserIds(of: currentUser.id)
            async let followingTask = feedService.fetchFollowingUserIds(of: currentUser.id)
            hiddenUserIds = try await hiddenTask
            followingUserIds = try await followingTask

            for id in followingUserIds {
                followStateCache[id] = true
            }

            let page = try await fetchPage(after: nil)
            posts = page.posts
            lastDocument = page.lastDocument
            canLoadMore = page.lastDocument != nil && !page.posts.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func switchFeed() async {
        posts = []
        lastDocument = nil
        canLoadMore = true
        await reload()
    }

    @MainActor
    private func loadMoreIfNeeded(currentPost: Post) async {
        guard canLoadMore,
              !isLoading,
              !isLoadingMore,
              currentPost.id == posts.last?.id
        else {
            return
        }

        guard let lastDocument else {
            canLoadMore = false
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchPage(after: lastDocument)
            posts.append(contentsOf: page.posts)
            self.lastDocument = page.lastDocument
            canLoadMore = page.lastDocument != nil && !page.posts.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(after document: DocumentSnapshot?) async throws -> FeedPage {
        switch feedKind {
        case .recommended:
            return try await feedService.fetchRecommended(
                after: document,
                currentUserId: currentUser.id,
                hiddenUserIds: hiddenUserIds
            )
        case .following:
            // TODO(stage-A+): batch fetchFollowing past 30 authors (Firestore `in` limit).
            return try await feedService.fetchFollowing(
                after: document,
                currentUserId: currentUser.id,
                followingUserIds: followingUserIds
            )
        }
    }

    @MainActor
    private func hideAuthor(authorId: String) async {
        do {
            try await followService.hideFromRecommendations(
                currentUserId: currentUser.id,
                hiddenUserId: authorId
            )
            hiddenUserIds.insert(authorId)
            posts.removeAll { $0.authorId == authorId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FeedPostCard: View {
    let post: Post
    let currentUser: AppUser
    @Binding var followStateCache: [String: Bool]
    @Binding var topCommentCache: [String: TopCommentPreview?]
    let onHide: () -> Void

    @State private var displayedPost: Post
    @State private var isLiked = false
    @State private var isReposted = false
    @State private var isLikeBusy = false
    @State private var isRepostBusy = false
    @State private var showComments = false
    @State private var errorMessage: String?
    @State private var didLoadInteractionState = false
    @State private var lightboxStartIndex = 0
    @State private var isLightboxPresented = false

    private let likeService: LikeServiceProtocol = LikeService.shared
    private let repostService: RepostServiceProtocol = RepostService.shared
    private let followService: FollowServiceProtocol = FollowService.shared
    private let commentService: CommentServiceProtocol = CommentService.shared

    init(
        post: Post,
        currentUser: AppUser,
        followStateCache: Binding<[String: Bool]>,
        topCommentCache: Binding<[String: TopCommentPreview?]>,
        onHide: @escaping () -> Void
    ) {
        self.post = post
        self.currentUser = currentUser
        self._followStateCache = followStateCache
        self._topCommentCache = topCommentCache
        self.onHide = onHide
        _displayedPost = State(initialValue: post)
    }

    private var followBinding: Binding<Bool?> {
        Binding(
            get: { followStateCache[displayedPost.authorId] },
            set: { newValue in
                if let newValue {
                    followStateCache[displayedPost.authorId] = newValue
                } else {
                    followStateCache.removeValue(forKey: displayedPost.authorId)
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    RemoteProfileView(
                        userId: displayedPost.authorId,
                        viewerUserId: currentUser.id
                    )
                    .toolbar(.hidden, for: .tabBar)
                } label: {
                    HStack(spacing: 10) {
                        ProfileAvatarView(
                            urlString: displayedPost.authorAvatarURL,
                            size: 38,
                            initials: ProfileAvatarView.initials(from: displayedPost.authorUsername)
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(displayedPost.authorUsername)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(DateFormatterHelper.shortRelative(from: displayedPost.createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                PostMoreMenu(
                    authorId: displayedPost.authorId,
                    currentUserId: currentUser.id,
                    isFollowing: followBinding,
                    onHide: onHide,
                    onError: { errorMessage = $0.localizedDescription }
                )
            }

            if let text = displayedPost.text, !text.isEmpty {
                ExpandableTextView(text: text)
            }

            if let code = displayedPost.code, !code.isEmpty {
                CodeSnippetPreviewView(
                    code: code,
                    languageId: displayedPost.programmingLanguage,
                    lineCount: displayedPost.codeLineCount
                )
            } else if let language = ProgrammingLanguage.find(id: displayedPost.programmingLanguage) {
                HStack {
                    LanguageBadgeView(language: language, isSelected: true)
                    Spacer()
                }
            }

            if !displayedPost.imageURLs.isEmpty {
                PostImageGallery(urls: displayedPost.imageURLs) { index in
                    lightboxStartIndex = index
                    isLightboxPresented = true
                }
            }

            if let preview = displayedPost.topCommentPreview {
                TopCommentPreviewView(preview: preview) {
                    showComments = true
                }
            }

            HStack(spacing: 8) {
                FeedActionButton(
                    title: "\(displayedPost.likesCount)",
                    icon: isLiked ? "heart.fill" : "heart",
                    tint: isLiked ? .red : .secondary,
                    isBusy: isLikeBusy
                ) {
                    Task { await toggleLike() }
                }

                FeedActionButton(
                    title: "\(displayedPost.commentsCount)",
                    icon: "message",
                    tint: .secondary
                ) {
                    showComments = true
                }

                FeedActionButton(
                    title: "\(displayedPost.repostsCount)",
                    icon: isReposted ? "arrow.2.squarepath.circle.fill" : "arrow.2.squarepath",
                    tint: isReposted ? Color("BrandGradientStart") : .secondary,
                    isBusy: isRepostBusy
                ) {
                    Task { await toggleRepost() }
                }
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task { await ensureInteractionStateLoaded() }
        .sheet(isPresented: $showComments) {
            NavigationStack {
                PostCommentsSheet(post: displayedPost, currentUser: currentUser) { delta in
                    displayedPost.commentsCount = max(0, displayedPost.commentsCount + delta)
                }
            }
        }
        .fullScreenCover(isPresented: $isLightboxPresented) {
            ImageLightboxView(
                urls: displayedPost.imageURLs,
                startIndex: lightboxStartIndex
            )
        }
        .alert("Ошибка действия", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
    private func ensureInteractionStateLoaded() async {
        guard !didLoadInteractionState else { return }
        didLoadInteractionState = true

        do {
            async let liked = likeService.isPostLiked(userId: currentUser.id, postId: displayedPost.id)
            async let reposted = repostService.isReposted(userId: currentUser.id, postId: displayedPost.id)
            isLiked = try await liked
            isReposted = try await reposted
        } catch {
            errorMessage = error.localizedDescription
        }

        if displayedPost.authorId != currentUser.id,
           followStateCache[displayedPost.authorId] == nil {
            do {
                let following = try await followService.isFollowing(
                    currentUserId: currentUser.id,
                    targetUserId: displayedPost.authorId
                )
                followStateCache[displayedPost.authorId] = following
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        await loadTopCommentIfNeeded()
    }

    @MainActor
    private func loadTopCommentIfNeeded() async {
        guard displayedPost.commentsCount > 0 else {
            displayedPost.topCommentPreview = nil
            return
        }

        if let cached = topCommentCache[displayedPost.id] {
            displayedPost.topCommentPreview = cached
            return
        }

        do {
            let topComment = try await commentService.fetchByPost(
                postId: displayedPost.id,
                sortedByLikes: true,
                pageSize: 1
            ).first

            let preview = topComment.map {
                TopCommentPreview(
                    commentId: $0.id,
                    authorUsername: $0.authorUsername,
                    text: $0.text,
                    likesCount: $0.likesCount
                )
            }
            topCommentCache[displayedPost.id] = preview
            displayedPost.topCommentPreview = preview
        } catch {
            // тихо игнорируем — ленте не критично, превью просто не появится
        }
    }

    @MainActor
    private func toggleLike() async {
        guard !isLikeBusy else { return }
        isLikeBusy = true
        defer { isLikeBusy = false }

        do {
            if isLiked {
                try await likeService.unlikePost(userId: currentUser.id, postId: displayedPost.id)
                isLiked = false
                displayedPost.likesCount = max(0, displayedPost.likesCount - 1)
            } else {
                try await likeService.likePost(userId: currentUser.id, postId: displayedPost.id)
                isLiked = true
                displayedPost.likesCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func toggleRepost() async {
        guard !isRepostBusy else { return }
        isRepostBusy = true
        defer { isRepostBusy = false }

        do {
            if isReposted {
                try await repostService.removeRepost(userId: currentUser.id, postId: displayedPost.id)
                isReposted = false
                displayedPost.repostsCount = max(0, displayedPost.repostsCount - 1)
            } else {
                try await repostService.repost(userId: currentUser.id, originalPost: displayedPost)
                isReposted = true
                displayedPost.repostsCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FeedActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    var isBusy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isBusy {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}

private struct PostCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let post: Post
    let currentUser: AppUser
    let onCountChanged: (Int) -> Void

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var sortByLikes = true

    private let commentService: CommentServiceProtocol = CommentService.shared

    var body: some View {
        List {
            Section {
                Picker("Сортировка", selection: $sortByLikes) {
                    Text("Топ").tag(true)
                    Text("Новые").tag(false)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 6, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if isLoading && comments.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if comments.isEmpty {
                ContentUnavailableView(
                    "Комментариев пока нет",
                    systemImage: "message",
                    description: Text("Будь первым, кто оставит комментарий.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if comment.authorId == currentUser.id {
                                Button("Удалить", role: .destructive) {
                                    Task { await delete(comment: comment) }
                                }
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Комментарии")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            composer
        }
        .task { await loadComments() }
        .onChange(of: sortByLikes) { _, _ in
            Task { await loadComments() }
        }
        .alert("Ошибка комментариев", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Написать комментарий...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                Task { await submitComment() }
            } label: {
                if isSubmitting {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .disabled(trimmedCommentText.isEmpty || isSubmitting)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var trimmedCommentText: String {
        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
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
    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            comments = try await commentService.fetchByPost(
                postId: post.id,
                sortedByLikes: sortByLikes,
                pageSize: 100
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func submitComment() async {
        let text = trimmedCommentText
        guard !text.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let comment = Comment(
                postId: post.id,
                authorId: currentUser.id,
                authorUsername: currentUser.username,
                authorAvatarURL: currentUser.avatarURL,
                text: text
            )
            try await commentService.create(comment)
            comments.insert(comment, at: 0)
            newCommentText = ""
            onCountChanged(1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func delete(comment: Comment) async {
        do {
            try await commentService.delete(commentId: comment.id, postId: post.id)
            comments.removeAll { $0.id == comment.id }
            onCountChanged(-1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ProfileAvatarView(
                urlString: comment.authorAvatarURL,
                size: 34,
                initials: ProfileAvatarView.initials(from: comment.authorUsername)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.authorUsername)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(DateFormatterHelper.shortRelative(from: comment.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }
}

enum UserSearchKind: String, Hashable, CaseIterable, Sendable {
    case username
    case hashtag
    case language

    var title: String {
        switch self {
        case .username: return "Username"
        case .hashtag:  return "Хэштег"
        case .language: return "Язык"
        }
    }

    var prompt: String {
        switch self {
        case .username: return "username"
        case .hashtag:  return "хэштег"
        case .language: return "swift, python, go…"
        }
    }

    var emptyHint: String {
        switch self {
        case .username: return "Введи username, чтобы найти аккаунт."
        case .hashtag:  return "Введи хэштег без # — найдём, кто пишет на эту тему."
        case .language: return "Введи название языка — найдём авторов, которые на нём пишут."
        }
    }
}

struct UserSearchView: View {
    let currentUser: AppUser

    @State private var searchText = ""
    @State private var searchKind: UserSearchKind = .username
    @State private var results: [AppUser] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private let userService: UserServiceProtocol = UserService.shared

    var body: some View {
        List {
            Section {
                Picker("Поиск по", selection: $searchKind) {
                    ForEach(UserSearchKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "Поиск пользователей",
                    systemImage: "magnifyingglass",
                    description: Text(searchKind.emptyHint)
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if results.isEmpty {
                ContentUnavailableView(
                    "Ничего не найдено",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("Попробуй другой запрос или переключи режим поиска.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(results) { user in
                    NavigationLink {
                        ProfileView(
                            user: user,
                            viewerUserId: currentUser.id,
                            hidesTabBar: true
                        )
                    } label: {
                        SearchUserRow(user: user)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Поиск")
        .searchable(text: $searchText, prompt: searchKind.prompt)
        .onChange(of: searchText) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .onChange(of: searchKind) { _, _ in
            scheduleSearch(for: searchText)
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .alert("Ошибка поиска", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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

    private func scheduleSearch(for rawQuery: String) {
        searchTask?.cancel()
        errorMessage = nil

        let normalized = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            isSearching = false
            results = []
            return
        }

        let kind = searchKind
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: normalized, kind: kind)
        }
    }

    @MainActor
    private func performSearch(query: String, kind: UserSearchKind) async {
        isSearching = true
        defer { isSearching = false }

        do {
            let users = try await fetchResults(query: query, kind: kind)
            results = users.filter { $0.id != currentUser.id }
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
    }

    private func fetchResults(query: String, kind: UserSearchKind) async throws -> [AppUser] {
        switch kind {
        case .username:
            return try await userService.searchUsers(query: query.lowercased(), limit: 25)
        case .hashtag:
            return try await userService.searchUsersByHashtag(query, limit: 25)
        case .language:
            guard let language = ProgrammingLanguage.search(query).first else { return [] }
            return try await userService.searchUsersByLanguage(language.id, limit: 25)
        }
    }
}

private struct SearchUserRow: View {
    let user: AppUser

    var body: some View {
        HStack(spacing: 12) {
            ProfileAvatarView(
                urlString: user.avatarURL,
                size: 42,
                initials: ProfileAvatarView.initials(from: user.displayName)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? "@\(user.username)" : user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

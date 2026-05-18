import SwiftUI
import FirebaseFirestore
import Kingfisher

struct HomeFeedView: View {
    let currentUser: AppUser
    let refreshToken: Int

    @State private var posts: [Post] = []
    @State private var lastDocument: DocumentSnapshot?
    @State private var hiddenUserIds: Set<String> = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var canLoadMore = true
    @State private var errorMessage: String?

    private let feedService: FeedServiceProtocol = FeedService.shared

    var body: some View {
        Group {
            if isLoading && posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if posts.isEmpty {
                ContentUnavailableView(
                    "Пока нет постов",
                    systemImage: "newspaper",
                    description: Text("Опубликуй первый пост или потяни экран вниз для обновления.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(posts) { post in
                            FeedPostCard(post: post, currentUser: currentUser)
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
        .navigationTitle("Лента")
        .background(Color(.systemGroupedBackground))
        .task(id: refreshToken) { await reload() }
        .refreshable { await reload() }
        .alert("Не удалось загрузить ленту", isPresented: errorBinding) {
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
    private func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            hiddenUserIds = try await feedService.fetchHiddenUserIds(of: currentUser.id)
            let page = try await feedService.fetchRecommended(
                after: nil,
                currentUserId: currentUser.id,
                hiddenUserIds: hiddenUserIds
            )
            posts = page.posts
            lastDocument = page.lastDocument
            canLoadMore = page.lastDocument != nil && !page.posts.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
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
            let page = try await feedService.fetchRecommended(
                after: lastDocument,
                currentUserId: currentUser.id,
                hiddenUserIds: hiddenUserIds
            )

            posts.append(contentsOf: page.posts)
            self.lastDocument = page.lastDocument
            canLoadMore = page.lastDocument != nil && !page.posts.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FeedPostCard: View {
    let post: Post
    let currentUser: AppUser

    @State private var displayedPost: Post
    @State private var isLiked = false
    @State private var isReposted = false
    @State private var isLikeBusy = false
    @State private var isRepostBusy = false
    @State private var showComments = false
    @State private var errorMessage: String?
    @State private var didLoadInteractionState = false

    private let likeService: LikeServiceProtocol = LikeService.shared
    private let repostService: RepostServiceProtocol = RepostService.shared

    init(post: Post, currentUser: AppUser) {
        self.post = post
        self.currentUser = currentUser
        _displayedPost = State(initialValue: post)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProfileAvatarView(
                    urlString: displayedPost.authorAvatarURL,
                    size: 38,
                    initials: ProfileAvatarView.initials(from: displayedPost.authorUsername)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(displayedPost.authorUsername)")
                        .font(.system(size: 15, weight: .semibold))
                    Text(DateFormatterHelper.shortRelative(from: displayedPost.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let text = displayedPost.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let code = displayedPost.code, !code.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if let firstImageURL = displayedPost.imageURLs.first, let imageURL = URL(string: firstImageURL) {
                ZStack(alignment: .topTrailing) {
                    KFImage(imageURL)
                        .placeholder {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.thinMaterial)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if displayedPost.imageURLs.count > 1 {
                        Text("+\(displayedPost.imageURLs.count - 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(8)
                    }
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

    private let commentService: CommentServiceProtocol = CommentService.shared

    var body: some View {
        List {
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
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            comments = try await commentService.fetchByPost(
                postId: post.id,
                sortedByLikes: false,
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

struct UserSearchView: View {
    let currentUser: AppUser

    @State private var searchText = ""
    @State private var results: [AppUser] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private let userService: UserServiceProtocol = UserService.shared

    var body: some View {
        List {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "Поиск пользователей",
                    systemImage: "magnifyingglass",
                    description: Text("Введи username, чтобы найти аккаунт.")
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
                    description: Text("Проверь написание username и попробуй снова.")
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
        .searchable(text: $searchText, prompt: "username")
        .onChange(of: searchText) { _, newValue in
            scheduleSearch(for: newValue)
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

        let normalized = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            isSearching = false
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: normalized)
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            let users = try await userService.searchUsers(query: query, limit: 25)
            results = users.filter { $0.id != currentUser.id }
        } catch {
            results = []
            errorMessage = error.localizedDescription
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

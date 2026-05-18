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
                            FeedPostCard(post: post)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProfileAvatarView(
                    urlString: post.authorAvatarURL,
                    size: 38,
                    initials: ProfileAvatarView.initials(from: post.authorUsername)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.authorUsername)")
                        .font(.system(size: 15, weight: .semibold))
                    Text(DateFormatterHelper.shortRelative(from: post.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let text = post.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let code = post.code, !code.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if let firstImageURL = post.imageURLs.first, let imageURL = URL(string: firstImageURL) {
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

                    if post.imageURLs.count > 1 {
                        Text("+\(post.imageURLs.count - 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(8)
                    }
                }
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
                        ProfileView(user: user)
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

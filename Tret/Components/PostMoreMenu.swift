import SwiftUI

struct PostMoreMenu: View {
    let authorId: String
    let currentUserId: String
    @Binding var isFollowing: Bool?
    let onHide: () -> Void
    let onDelete: (() -> Void)?
    let onError: (Error) -> Void

    @State private var isBusy = false
    @State private var showDeleteConfirmation = false

    private let followService: FollowServiceProtocol = FollowService.shared

    private var isOwnPost: Bool { authorId == currentUserId }

    private var hasAnyAction: Bool {
        if isOwnPost { return onDelete != nil }
        return true
    }

    init(
        authorId: String,
        currentUserId: String,
        isFollowing: Binding<Bool?>,
        onHide: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onError: @escaping (Error) -> Void
    ) {
        self.authorId = authorId
        self.currentUserId = currentUserId
        self._isFollowing = isFollowing
        self.onHide = onHide
        self.onDelete = onDelete
        self.onError = onError
    }

    var body: some View {
        Menu {
            if isOwnPost {
                if onDelete != nil {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Удалить пост", systemImage: "trash")
                    }
                }
            } else {
                followToggleButton
                Button(role: .destructive) {
                    onHide()
                } label: {
                    Label("Не показывать в рекомендациях", systemImage: "eye.slash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .disabled(isBusy)
        .accessibilityLabel("Действия с постом")
        .opacity(hasAnyAction ? 1 : 0)
        .allowsHitTesting(hasAnyAction)
        .confirmationDialog(
            "Удалить пост?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                onDelete?()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Действие необратимо: пост и его комментарии будут удалены.")
        }
    }

    @ViewBuilder
    private var followToggleButton: some View {
        switch isFollowing {
        case .some(true):
            Button(role: .destructive) {
                Task { await toggleFollow(currentlyFollowing: true) }
            } label: {
                Label("Отписаться", systemImage: "person.fill.xmark")
            }
        case .some(false):
            Button {
                Task { await toggleFollow(currentlyFollowing: false) }
            } label: {
                Label("Подписаться", systemImage: "person.fill.badge.plus")
            }
        case .none:
            Button {} label: {
                Label("Загрузка…", systemImage: "hourglass")
            }
            .disabled(true)
        }
    }

    @MainActor
    private func toggleFollow(currentlyFollowing: Bool) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            if currentlyFollowing {
                try await followService.unfollow(currentUserId: currentUserId, targetUserId: authorId)
                isFollowing = false
            } else {
                try await followService.follow(currentUserId: currentUserId, targetUserId: authorId)
                isFollowing = true
            }
        } catch {
            onError(error)
        }
    }
}

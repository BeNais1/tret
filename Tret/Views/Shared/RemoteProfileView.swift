import SwiftUI

/// Открывает `ProfileView` по userId: подгружает `AppUser` из Firestore и
/// прокидывает viewerUserId. Используется когда у нас есть только authorId
/// (например, при тапе на автора в ленте поста).
struct RemoteProfileView: View {
    let userId: String
    let viewerUserId: String
    var hidesTabBar: Bool = true

    @State private var user: AppUser?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let userService: UserServiceProtocol = UserService.shared

    var body: some View {
        Group {
            if let user {
                ProfileView(
                    user: user,
                    viewerUserId: viewerUserId,
                    hidesTabBar: hidesTabBar
                )
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    "Профиль недоступен",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(errorMessage ?? "Не удалось загрузить пользователя.")
                )
            }
        }
        .task(id: userId) { await load() }
    }

    @MainActor
    private func load() async {
        guard user == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await userService.fetchUser(id: userId)
            if user == nil {
                errorMessage = "Пользователь не найден."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

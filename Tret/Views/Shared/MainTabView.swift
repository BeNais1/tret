import SwiftUI

enum MainTab: Hashable {
    case home, create, search, profile
}

struct MainTabView: View {

    let currentUser: AppUser

    @State private var selection: MainTab = .home
    @State private var postDraft = PostDraft()
    @State private var feedRefreshToken = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("Лента", systemImage: "house.fill", value: MainTab.home) {
                NavigationStack {
                    HomeFeedView(currentUser: currentUser, refreshToken: feedRefreshToken)
                }
            }

            Tab("Создать", systemImage: "plus.circle.fill", value: MainTab.create) {
                NavigationStack {
                    CreatePostView(
                        currentUser: currentUser,
                        draft: $postDraft
                    ) {
                        selection = .home
                        feedRefreshToken += 1
                    }
                }
            }

            Tab(value: MainTab.search, role: .search) {
                NavigationStack {
                    UserSearchView(currentUser: currentUser)
                }
            } label: {
                Label("Поиск", systemImage: "magnifyingglass")
            }

            Tab("Профиль", systemImage: "person.circle.fill", value: MainTab.profile) {
                NavigationStack {
                    ProfileView(user: currentUser, viewerUserId: currentUser.id)
                }
            }
        }
        .tint(Color("BrandGradientStart"))
    }
}

// MARK: - Placeholders (Stage 2+ заменят полноценными экранами)

private struct HomeFeedPlaceholder: View {
    var body: some View {
        ComingSoonScreen(
            icon: "house",
            title: "Лента",
            subtitle: "Скоро здесь появятся рекомендации и посты подписок."
        )
        .navigationTitle("Лента")
    }
}

private struct SearchPlaceholder: View {
    var body: some View {
        ComingSoonScreen(
            icon: "magnifyingglass",
            title: "Поиск",
            subtitle: "Ищи разработчиков по нику и хэштегам — открываем в следующем апдейте."
        )
        .navigationTitle("Поиск")
    }
}

struct ComingSoonScreen: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

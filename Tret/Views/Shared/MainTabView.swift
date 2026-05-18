import SwiftUI

struct MainTabView: View {

    let currentUser: AppUser

    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, search, create, profile
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Лента", systemImage: "house.fill", value: Tab.home) {
                NavigationStack { HomeFeedPlaceholder() }
            }

            Tab("Создать", systemImage: "plus.circle.fill", value: Tab.create) {
                NavigationStack { CreatePostPlaceholder() }
            }

            Tab(value: Tab.search, role: .search) {
                NavigationStack { SearchPlaceholder() }
            } label: {
                Label("Поиск", systemImage: "magnifyingglass")
            }

            Tab("Профиль", systemImage: "person.circle.fill", value: Tab.profile) {
                NavigationStack { ProfilePlaceholder(user: currentUser) }
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

private struct CreatePostPlaceholder: View {
    var body: some View {
        ComingSoonScreen(
            icon: "square.and.pencil",
            title: "Новый пост",
            subtitle: "Редактор кода с подсветкой, картинки и теги — на подходе."
        )
        .navigationTitle("Создать")
    }
}

private struct ProfilePlaceholder: View {
    @Environment(AppState.self) private var appState
    let user: AppUser

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfilePreviewCard(user: user)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Статистика")
                        .font(.headline)
                    HStack(spacing: 20) {
                        statColumn(title: "Посты", value: user.postsCount)
                        statColumn(title: "Подписчики", value: user.followersCount)
                        statColumn(title: "Подписки", value: user.followingCount)
                    }
                }
                .padding(.horizontal, 4)

                GlassButton(style: .secondary) {
                    appState.signOut()
                } label: {
                    Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .padding(20)
        }
        .navigationTitle("Профиль")
        .background(Color(.systemGroupedBackground))
    }

    private func statColumn(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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

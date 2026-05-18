import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    let user: AppUser

    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showUsernameRequest = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProfilePreviewCard(user: user)

                GlassButton(style: .secondary) {
                    showEditProfile = true
                } label: {
                    Label("Редактировать профиль", systemImage: "pencil")
                }

                statsSection
                usernameSection
            }
            .padding(20)
        }
        .navigationTitle("Профиль")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Настройки")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ProfileSettingsView()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(user: user)
            }
        }
        .sheet(isPresented: $showUsernameRequest) {
            NavigationStack {
                UsernameChangeRequestView(user: user)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Статистика")
                .font(.headline)

            HStack(spacing: 12) {
                statColumn(title: "Посты", value: user.postsCount)
                statColumn(title: "Подписчики", value: user.followersCount)
                statColumn(title: "Подписки", value: user.followingCount)
            }
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

private struct ProfileSettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tret.appTheme") private var appThemeRaw = AppTheme.system.rawValue

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
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                avatarEditor

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

                    Text("Username не меняется при редактировании профиля.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: selectedAvatarItem == nil) { _, _ in
            let item = selectedAvatarItem
            Task { await loadAvatar(from: item) }
        }
        .alert("Не удалось сохранить", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
                Text("Можно выбрать новое фото из галереи. Оно сохранится после кнопки «Сохранить».")
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
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            var updated = user
            updated.displayName = trimmedName

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

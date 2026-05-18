import SwiftUI

struct OnboardingStep1UsernamePhoto: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                StepHeader(
                    title: "Расскажи, кто ты",
                    subtitle: "Выбери уникальный username: строчные английские буквы, цифры и подчёркивание. Аватар возьмём из твоего Google-аккаунта."
                )

                // Avatar (read-only: используем фото из Google).
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        avatarPreview
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))

                        Text("Сменить фото можно позже")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }

                // Username field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Имя пользователя")
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 8) {
                        Text("@")
                            .foregroundStyle(.secondary)
                        TextField("например, swift_dev", text: Binding(
                            get: { viewModel.username },
                            set: { viewModel.usernameChanged($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)

                        statusIcon
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )

                    if let message = statusMessage {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(statusColor)
                    }
                }

                // Suggestions
                if !viewModel.usernameSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Подсказки")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.usernameSuggestions, id: \.self) { suggestion in
                                Button {
                                    viewModel.applySuggestion(suggestion)
                                } label: {
                                    Text("@\(suggestion)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(Color.primary.opacity(0.06))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarPreview: some View {
        if let photoURL = viewModel.pending.photoURL {
            ProfileAvatarView(
                url: photoURL,
                size: 110,
                initials: ProfileAvatarView.initials(from: viewModel.pending.displayName)
            )
        } else {
            ProfileAvatarView(
                urlString: nil,
                size: 110,
                initials: ProfileAvatarView.initials(from: viewModel.pending.displayName.isEmpty ? viewModel.username : viewModel.pending.displayName)
            )
        }
    }

    // MARK: - Status helpers

    private var statusIcon: some View {
        Group {
            switch viewModel.usernameStatus {
            case .validating:
                ProgressView().controlSize(.small)
            case .available:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .taken, .invalid:
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
        }
    }

    private var statusMessage: String? {
        switch viewModel.usernameStatus {
        case .available: return "Свободно"
        case .taken: return "Уже занято"
        case .validating: return "Проверяем доступность…"
        case .invalid(let m): return m
        case .idle: return nil
        }
    }

    private var statusColor: Color {
        switch viewModel.usernameStatus {
        case .available: return .green
        case .taken, .invalid: return .red
        default: return .secondary
        }
    }

    private var borderColor: Color {
        switch viewModel.usernameStatus {
        case .available: return .green.opacity(0.4)
        case .taken, .invalid: return .red.opacity(0.4)
        default: return .clear
        }
    }
}

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }
}

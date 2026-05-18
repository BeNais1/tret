import PhotosUI
import SwiftUI
import UIKit

struct PostDraft {
    var text = ""
    var code = ""
    var programmingLanguageId: String?
    var imageDatas: [Data] = []

    mutating func clear() {
        text = ""
        code = ""
        programmingLanguageId = nil
        imageDatas = []
    }
}

struct CreatePostView: View {
    @Environment(AppState.self) private var appState

    let currentUser: AppUser
    @Binding var draft: PostDraft
    let onPublished: () -> Void

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isPublishing = false
    @State private var publishError: String?

    private let postService: PostServiceProtocol = PostService.shared
    private let storageService: StorageServiceProtocol = StorageService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                authorHeader
                textSection
                codeSection
                languageSection
                imageSection
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Создать")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await publish() }
                } label: {
                    Text("Опубликовать")
                        .fontWeight(.semibold)
                }
                .disabled(!canPublish || isPublishing)
            }
        }
        .onChange(of: selectedPhotoItems.count) { _, _ in
            let items = selectedPhotoItems
            Task { await appendImages(from: items) }
        }
        .alert("Не удалось опубликовать", isPresented: publishErrorBinding) {
            Button("OK", role: .cancel) { publishError = nil }
        } message: {
            Text(publishError ?? "")
        }
    }

    private var authorHeader: some View {
        HStack(spacing: 12) {
            ProfileAvatarView(
                urlString: currentUser.avatarURL,
                size: 42,
                initials: ProfileAvatarView.initials(from: currentUser.displayName)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(currentUser.displayName.isEmpty ? "@\(currentUser.username)" : currentUser.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("@\(currentUser.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Текст поста", icon: "text.alignleft")

            ZStack(alignment: .topLeading) {
                if draft.text.isEmpty {
                    Text("Что хочешь рассказать?")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $draft.text)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onChange(of: draft.text) { _, value in
                        if value.count > AppConstants.maxPostTextCharacters {
                            draft.text = String(value.prefix(AppConstants.maxPostTextCharacters))
                        }
                    }
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            )

            HStack {
                Spacer()
                Text("\(draft.text.count) / \(AppConstants.maxPostTextCharacters)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Код", icon: "chevron.left.forwardslash.chevron.right")

            ZStack(alignment: .topLeading) {
                if draft.code.isEmpty {
                    Text("Вставь код, если пост про разбор, ошибку или идею.")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $draft.code)
                    .font(.system(size: 14, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(codeLineCount > AppConstants.maxCodeLines ? .red.opacity(0.45) : .primary.opacity(0.06), lineWidth: 1)
            )

            HStack {
                Text("Строк: \(codeLineCount) / \(AppConstants.maxCodeLines)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(codeLineCount > AppConstants.maxCodeLines ? .red : .secondary)
                Spacer()
                if !draft.code.isEmpty {
                    Button {
                        draft.code = ""
                    } label: {
                        Label("Очистить", systemImage: "xmark.circle")
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Язык", icon: "tag")

            Menu {
                Button {
                    draft.programmingLanguageId = nil
                } label: {
                    Label("Без языка", systemImage: draft.programmingLanguageId == nil ? "checkmark" : "circle")
                }

                ForEach(ProgrammingLanguage.all) { language in
                    Button {
                        draft.programmingLanguageId = language.id
                    } label: {
                        Label(
                            language.displayName,
                            systemImage: draft.programmingLanguageId == language.id ? "checkmark" : "circle"
                        )
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if let language = ProgrammingLanguage.find(id: draft.programmingLanguageId) {
                        Circle()
                            .fill(language.color)
                            .frame(width: 10, height: 10)
                        Text(language.displayName)
                    } else {
                        Image(systemName: "tag")
                            .foregroundStyle(.secondary)
                        Text("Выбрать язык")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Изображения", icon: "photo")
                Spacer()
                Text("\(draft.imageDatas.count)/\(AppConstants.maxImagesPerPost)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: max(AppConstants.maxImagesPerPost - draft.imageDatas.count, 0),
                matching: .images
            ) {
                Label("Добавить фото", systemImage: "photo.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(draft.imageDatas.count >= AppConstants.maxImagesPerPost)
            .opacity(draft.imageDatas.count >= AppConstants.maxImagesPerPost ? 0.5 : 1)

            if !draft.imageDatas.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                    ForEach(Array(draft.imageDatas.enumerated()), id: \.offset) { index, data in
                        imagePreview(data: data, index: index)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func imagePreview(data: Data, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .frame(height: 96)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            Button {
                guard draft.imageDatas.indices.contains(index) else { return }
                draft.imageDatas.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(.black.opacity(0.65), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }

    private var canPublish: Bool {
        hasDraft && codeLineCount <= AppConstants.maxCodeLines
    }

    private var hasDraft: Bool {
        !draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !draft.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !draft.imageDatas.isEmpty
    }

    private var codeLineCount: Int {
        let trimmed = draft.code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .newlines).count
    }

    private var publishErrorBinding: Binding<Bool> {
        Binding(
            get: { publishError != nil },
            set: { isPresented in
                if !isPresented { publishError = nil }
            }
        )
    }

    @MainActor
    private func appendImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for item in items {
            guard draft.imageDatas.count < AppConstants.maxImagesPerPost else { break }
            guard let rawData = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: rawData),
                  let resized = image.resized(maxDimension: 1600, jpegQuality: 0.86)
            else {
                continue
            }
            draft.imageDatas.append(resized)
        }

        selectedPhotoItems = []
    }

    @MainActor
    private func publish() async {
        guard canPublish, !isPublishing else { return }
        isPublishing = true
        defer { isPublishing = false }

        do {
            let postId = UUID().uuidString
            var imageURLs: [String] = []

            for (index, data) in draft.imageDatas.enumerated() {
                let url = try await storageService.uploadPostImage(
                    userId: currentUser.id,
                    postId: postId,
                    index: index,
                    imageData: data
                )
                imageURLs.append(url.absoluteString)
            }

            let text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let code = draft.code.trimmingCharacters(in: .whitespacesAndNewlines)
            let post = Post(
                id: postId,
                authorId: currentUser.id,
                authorUsername: currentUser.username,
                authorAvatarURL: currentUser.avatarURL,
                text: text.isEmpty ? nil : text,
                code: code.isEmpty ? nil : code,
                codeLineCount: codeLineCount,
                programmingLanguage: draft.programmingLanguageId,
                imageURLs: imageURLs
            )

            try await postService.create(post)
            draft.clear()
            await appState.refreshCurrentUser()
            onPublished()
        } catch {
            publishError = error.localizedDescription
        }
    }
}

import SwiftUI

struct HashtagPickerView: View {
    @Binding var hashtags: [String]
    var maxCount: Int = AppConstants.maxHashtags

    @State private var draft = ""

    private var canAddMore: Bool { hashtags.count < maxCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Хэштеги")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(hashtags.count)/\(maxCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("#").foregroundStyle(.secondary)
                TextField("iosdev, backend, gamedev", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { submit() }
                    .disabled(!canAddMore)

                Button {
                    submit()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(!canAddMore || draft.isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !hashtags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(hashtags, id: \.self) { tag in
                        HashtagChipView(hashtag: tag, onRemove: { remove(tag) })
                    }
                }
            }
        }
    }

    private func submit() {
        guard canAddMore else { return }
        let normalized = Validators.normalizeHashtag(draft)
        guard Validators.validateHashtag(normalized) == .valid,
              !hashtags.contains(normalized) else {
            return
        }
        hashtags.append(normalized)
        draft = ""
    }

    private func remove(_ tag: String) {
        hashtags.removeAll { $0 == tag }
    }
}

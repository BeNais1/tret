import SwiftUI

struct HashtagChipView: View {
    let hashtag: String
    let onRemove: (() -> Void)?

    init(hashtag: String, onRemove: (() -> Void)? = nil) {
        self.hashtag = hashtag
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("#\(hashtag)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(.secondary.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous).fill(Color.accentColor.opacity(0.10))
        )
        .overlay(
            Capsule(style: .continuous).strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    HStack {
        HashtagChipView(hashtag: "iosdev")
        HashtagChipView(hashtag: "swiftui", onRemove: {})
    }
    .padding()
}

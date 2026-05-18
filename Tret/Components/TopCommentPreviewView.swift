import SwiftUI

struct TopCommentPreviewView: View {
    let preview: TopCommentPreview
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Топ-комментарий")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if preview.likesCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                            Text("\(preview.likesCount)")
                                .monospacedDigit()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }

                (
                    Text("@\(preview.authorUsername) ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    + Text(preview.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                )
                .lineLimit(2)
                .multilineTextAlignment(.leading)

                Text("Читать далее")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("BrandGradientStart"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                Color.primary.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

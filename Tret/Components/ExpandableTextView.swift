import SwiftUI

struct ExpandableTextView: View {
    let text: String
    var collapsedLineLimit: Int = 6
    var characterThreshold: Int = 280
    var font: Font = .system(size: 15)

    @State private var isExpanded = false

    private var needsToggle: Bool {
        text.count > characterThreshold
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(font)
                .lineLimit(isExpanded || !needsToggle ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            if needsToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Свернуть" : "Читать далее")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("BrandGradientStart"))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

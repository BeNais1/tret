import SwiftUI
import Kingfisher

struct PostImageGallery: View {
    let urls: [String]
    let onTap: (Int) -> Void

    var body: some View {
        switch urls.count {
        case 0:
            EmptyView()
        case 1:
            singleImage
        case 2:
            HStack(spacing: 6) { rowImages(indices: [0, 1], height: 190) }
        case 3:
            HStack(spacing: 6) { rowImages(indices: [0, 1, 2], height: 160) }
        case 4:
            gridImages(indices: [0, 1, 2, 3])
        default:
            carouselImages
        }
    }

    @ViewBuilder
    private var singleImage: some View {
        if let url = URL(string: urls[0]) {
            thumbnail(url: url, index: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func rowImages(indices: [Int], height: CGFloat) -> some View {
        ForEach(indices, id: \.self) { idx in
            if let url = URL(string: urls[idx]) {
                thumbnail(url: url, index: idx)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func gridImages(indices: [Int]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
            spacing: 6
        ) {
            ForEach(indices, id: \.self) { idx in
                if let url = URL(string: urls[idx]) {
                    thumbnail(url: url, index: idx)
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var carouselImages: some View {
        TabView {
            ForEach(Array(urls.enumerated()), id: \.offset) { offset, urlString in
                if let url = URL(string: urlString) {
                    thumbnail(url: url, index: offset)
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 2)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 260)
    }

    private func thumbnail(url: URL, index: Int) -> some View {
        Button {
            onTap(index)
        } label: {
            KFImage(url)
                .placeholder {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                        .overlay {
                            ProgressView()
                        }
                }
                .resizable()
                .scaledToFill()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

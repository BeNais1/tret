import SwiftUI
import Kingfisher

struct ProfileAvatarView: View {
    let url: URL?
    let size: CGFloat
    let initials: String?

    init(urlString: String?, size: CGFloat = 44, initials: String? = nil) {
        self.url = urlString.flatMap(URL.init(string:))
        self.size = size
        self.initials = initials
    }

    init(url: URL?, size: CGFloat = 44, initials: String? = nil) {
        self.url = url
        self.size = size
        self.initials = initials
    }

    var body: some View {
        ZStack {
            if let url {
                KFImage(url)
                    .placeholder { placeholder }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BrandGradientStart"), Color("BrandGradientEnd")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let initials, !initials.isEmpty {
                Text(initials.prefix(2).uppercased())
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}

extension ProfileAvatarView {
    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1))
        }
        return String(name.prefix(2))
    }
}

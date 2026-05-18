import SwiftUI

enum GlassButtonStyle {
    case primary
    case secondary
    case ghost
}

struct GlassButton<Label: View>: View {
    let style: GlassButtonStyle
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        style: GlassButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(textColor)
                } else {
                    label()
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 18)
            .background {
                background
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: shadowColor, radius: 18, y: 8)
            .opacity((isEnabled && !isLoading) ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            ZStack {
                LinearGradient(
                    colors: [Color("BrandGradientStart"), Color("BrandGradientEnd")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Color.white.opacity(0.04)
            }
        case .secondary:
            Rectangle().fill(.ultraThinMaterial)
        case .ghost:
            Rectangle().fill(.clear)
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .ghost: return .primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .white.opacity(0.18)
        case .secondary: return .primary.opacity(0.06)
        case .ghost: return .primary.opacity(0.12)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary: return Color("BrandGradientStart").opacity(0.35)
        case .secondary: return .black.opacity(0.08)
        case .ghost: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton(style: .primary, action: {}) {
            Label("Continue with Google", systemImage: "g.circle.fill")
        }
        GlassButton(style: .secondary, action: {}) { Text("Назад") }
        GlassButton(style: .ghost, action: {}) { Text("Пропустить") }
    }
    .padding(24)
    .background(BrandBackground().opacity(0.4))
}

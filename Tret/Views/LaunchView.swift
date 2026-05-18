import SwiftUI

struct LaunchView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 18) {
                BrandWordmark(size: 56)
                    .scaleEffect(animate ? 1.0 : 0.94)
                    .opacity(animate ? 1.0 : 0.6)

                ProgressView()
                    .controlSize(.regular)
                    .tint(.white.opacity(0.8))
                    .opacity(animate ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.6)) { animate = true }
        }
        .accessibilityIdentifier("LaunchView")
    }
}

struct BrandBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("BrandGradientStart"), Color("BrandGradientEnd")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -120, y: -260)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 140, y: 320)
        }
    }
}

struct BrandWordmark: View {
    var size: CGFloat = 48

    var body: some View {
        Text("Tret")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .accessibilityLabel("Tret")
    }
}

#Preview { LaunchView() }

import SwiftUI

struct OverlayView: View {
    var holdProgress: Double = 0

    var body: some View {
        ZStack {
            // Soft graphite wash over the desktop
            Color(red: 0.18, green: 0.19, blue: 0.21)
                .opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color(red: 0.35, green: 0.72, blue: 0.70))
                    .accessibilityHidden(true)

                Text("Hold Option for 5 seconds to exit Clean Mode")
                    .font(.system(size: 34, weight: .semibold, design: .default))
                    .foregroundStyle(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                ProgressView(value: holdProgress, total: 1)
                    .progressViewStyle(.linear)
                    .tint(Color(red: 0.35, green: 0.72, blue: 0.70))
                    .frame(maxWidth: 280)
                    .opacity(holdProgress > 0 ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: holdProgress)

                Text("Auto-unlocks after 10 minutes")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 0.78, green: 0.80, blue: 0.82))
            }
            .frame(maxWidth: 720)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OverlayView(holdProgress: 0.4)
        .frame(width: 900, height: 600)
}

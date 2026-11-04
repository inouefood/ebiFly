import SwiftUI

/// A hand gripping an iPhone that acts out the move the player should make.
/// `.shake` jiggles it quickly (the sauce step), `.tilt` rocks it slowly left and right (the flight),
/// `.drag` is a finger sliding sideways (debug builds without motion sensors only).
struct MotionHint: View {
    enum Kind { case shake, tilt, drag }

    let kind: Kind
    /// Height of the hand art in design points.
    var height: CGFloat = 76
    @Environment(\.uiScale) private var s
    /// Flips once on appear; repeatForever then animates back and forth between the two poses,
    /// so everything that should move must be expressed as a function of `on`.
    @State private var on = false

    var body: some View {
        content
            .frame(width: height * 1.25 * s, height: height * s)
            .onAppear {
                let a: Animation = kind == .shake ? .easeInOut(duration: 0.12) : .easeInOut(duration: 0.7)
                withAnimation(a.repeatForever(autoreverses: true)) { on = true }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .shake:
            ZStack {
                // motion marks on both sides, pulsing with the shake
                Image(systemName: "wave.3.left").offset(x: -height * 0.52 * s, y: -height * 0.18 * s)
                Image(systemName: "wave.3.right").offset(x: height * 0.52 * s, y: -height * 0.18 * s)
            }
            .font(.system(size: height * 0.2 * s, weight: .bold))
            .foregroundStyle(Palette.ink)
            .opacity(on ? 1 : 0.35)
            .overlay {
                hand
                    .rotationEffect(.degrees(on ? 9 : -9), anchor: .bottom)
                    .offset(y: on ? -height * 0.07 * s : height * 0.05 * s)
            }
        case .tilt:
            ZStack {
                arrow("arrowtriangle.left.fill", lit: !on).offset(x: -height * 0.56 * s)
                arrow("arrowtriangle.right.fill", lit: on).offset(x: height * 0.56 * s)
                hand.rotationEffect(.degrees(on ? 22 : -22), anchor: .bottom)
            }
        case .drag:
            ZStack {
                arrow("arrowtriangle.left.fill", lit: !on).offset(x: -height * 0.5 * s)
                arrow("arrowtriangle.right.fill", lit: on).offset(x: height * 0.5 * s)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: height * 0.4 * s, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Palette.ink, radius: 0, x: 1.5, y: 1.5)
                    .offset(x: on ? height * 0.18 * s : -height * 0.18 * s)
            }
        }
    }

    private var hand: some View {
        Image("hand-phone").resizable().scaledToFit().frame(height: height * s)
    }

    /// Which way the shrimp goes: the arrow on the side it's leaning to lights up.
    private func arrow(_ name: String, lit: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: height * 0.16 * s, weight: .black))
            .foregroundStyle(Palette.gold)
            .shadow(color: Palette.ink, radius: 0, x: 1, y: 1)
            .opacity(lit ? 1 : 0.25)
    }
}

#if DEBUG
#Preview("操作の案内") {
    HStack(spacing: 24) {
        MotionHint(kind: .shake)
        MotionHint(kind: .tilt)
        MotionHint(kind: .drag)
    }
    .padding()
    .background(Color(hex: 0x8FD8FF))
}
#endif

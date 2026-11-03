import CoreText
import SwiftUI
import UIKit

enum Palette {
    static let ink = Color(hex: 0x3A2418)
    static let accent = Color(hex: 0xE8553A)
    static let gold = Color(hex: 0xF6C445)
    static let cream = Color(hex: 0xFFF1C9)
    static let paper = Color(hex: 0xFFFAF0)
    static let muted = Color(hex: 0x7A5A40)
    static let line = Color(hex: 0xD9C49A)
    static let green = Color(hex: 0x2E9B5B)
    static let letterbox = Color(hex: 0x1C120B)
    static let resultBg = Color(hex: 0xFFEAB0)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    /// Linear blend between two colors.
    func mixed(with other: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = min(max(t, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }
}

enum AppFont {
    static let displayName = "DelaGothicOne-Regular"
    static let boldName = "ZenMaruGothic-Bold"
    static let blackName = "ZenMaruGothic-Black"

    static func display(_ size: CGFloat) -> Font { .custom(displayName, size: size) }
    static func body(_ size: CGFloat) -> Font { .custom(boldName, size: size) }
    static func black(_ size: CGFloat) -> Font { .custom(blackName, size: size) }

    /// Registers the bundled OFL fonts (Dela Gothic One, Zen Maru Gothic) for SwiftUI and SpriteKit.
    static func register() {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// Scale factor relative to the 300pt-wide design, provided by RootView.
private struct UIScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var uiScale: CGFloat {
        get { self[UIScaleKey.self] }
        set { self[UIScaleKey.self] = newValue }
    }
}

struct GameButtonStyle: ButtonStyle {
    enum Kind { case primary, ghost }
    var kind: Kind = .primary
    var wide = false
    var size: CGFloat = 20
    @Environment(\.uiScale) private var s
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(AppFont.display(size * s))
            .foregroundStyle(kind == .primary ? Color.white : Palette.ink)
            .padding(.vertical, 10 * s)
            .padding(.horizontal, 24 * s)
            .frame(maxWidth: wide ? .infinity : nil)
            .background(Capsule().fill(kind == .primary ? Palette.accent : Color.white))
            .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
            .offset(y: pressed ? 3 : 0)
            .background(Capsule().fill(Palette.ink).offset(y: 5))
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.easeOut(duration: 0.06), value: pressed)
    }
}

/// Text with a thick ink outline and optional drop shadow, like the logo in the design.
struct OutlinedText: View {
    let text: String
    let font: Font
    var fill: Color = Palette.gold
    var stroke: Color = Palette.ink
    var width: CGFloat = 3
    var shadow: CGFloat = 0

    var body: some View {
        ZStack {
            if shadow > 0 { outline.offset(y: shadow) }
            outline
            Text(text).font(font).foregroundStyle(fill)
        }
        .fixedSize()
    }

    private var outline: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let a = Double(i) / 16 * 2 * .pi
                Text(text).font(font).foregroundStyle(stroke)
                    .offset(x: cos(a) * width, y: sin(a) * width)
            }
        }
    }
}

struct StepsBar: View {
    static let names = ["つくる", "衣", "揚げる", "ソース", "とばす"]
    let current: Int
    var dark = false
    @Environment(\.uiScale) private var s
    /// Starts one step behind and advances on appear, so moving on to the next step is visible.
    @State private var shown: Int?
    @State private var pop = false

    private var step: Int { shown ?? max(current - 1, 0) }

    var body: some View {
        HStack(spacing: 4 * s) {
            ForEach(Self.names.indices, id: \.self) { i in
                HStack(spacing: 2 * s) {
                    if i < step {
                        Image(systemName: "checkmark").font(.system(size: 8 * s, weight: .black))
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(Self.names[i])
                }
                .font(AppFont.black(10 * s))
                .padding(.horizontal, 7 * s)
                .padding(.vertical, 1)
                .foregroundStyle(foreground(i))
                .background(Capsule().fill(background(i)))
                .overlay(Capsule().stroke(Palette.accent, lineWidth: 2).opacity(i == step && pop ? 1 : 0))
                .scaleEffect(i == step && pop ? 1.3 : 1)
                .zIndex(i == step ? 1 : 0)
            }
        }
        .onAppear {
            guard current > 0, shown == nil else { shown = current; return }
            // wait for the screen cross-fade, then move the highlight over with a pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    shown = current
                    pop = true
                }
                Haptics.light()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { pop = false }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ステップ \(current + 1)/\(Self.names.count) \(Self.names[current])")
    }

    private func background(_ i: Int) -> Color {
        if i == step { return dark ? .white : Palette.ink }
        if i < step { return Palette.gold }
        return dark ? Color.white.opacity(0.15) : Palette.ink.opacity(0.12)
    }

    private func foreground(_ i: Int) -> Color {
        if i == step { return dark ? Color(hex: 0x2F4A4F) : .white }
        if i < step { return Palette.ink }
        return dark ? Color.white.opacity(0.7) : Palette.ink.opacity(0.6)
    }
}

struct Pill: View {
    let label: String
    let value: String
    var unit = ""
    @Environment(\.uiScale) private var s

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(label).font(AppFont.black(13 * s))
            Text(value).font(AppFont.display(17 * s)).monospacedDigit()
            if !unit.isEmpty { Text(unit).font(AppFont.black(13 * s)) }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12 * s)
        .padding(.vertical, 3 * s)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
    }
}

struct Toast: View {
    let text: String
    var sub: String?
    @Environment(\.uiScale) private var s

    var body: some View {
        VStack(spacing: 2) {
            Text(text).font(AppFont.black(14 * s))
            if let sub { Text(sub).font(AppFont.body(11 * s)).opacity(0.85) }
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.ink.opacity(0.85)))
    }
}

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

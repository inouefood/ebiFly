import SpriteKit
import SwiftUI

struct FryView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene: FryScene
    @State private var verdict: String?

    init(tail: TailKind, bodyCount: Int) {
        _scene = StateObject(wrappedValue: FryScene(tail: tail, bodyCount: bodyCount))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 0) {
                StepsBar(current: 2, dark: true)
                Text("揚げる").font(AppFont.display(24 * s)).foregroundStyle(.white).padding(.top, 4)
                meter.padding(.top, 14 * s)
                Spacer()
                Group {
                    if let verdict {
                        OutlinedText(text: verdict, font: AppFont.display(26 * s), width: 2.5)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("メーターがきつね色のときに止めよう")
                            .font(AppFont.black(13 * s)).foregroundStyle(.white)
                    }
                }
                .frame(height: 48 * s)
                Button("あげる！") { stop() }
                    .buttonStyle(GameButtonStyle(wide: true))
                    .disabled(verdict != nil)
            }
            .padding(.horizontal, 18 * s)
            .padding(.top, 8)
            .padding(.bottom, 20 * s)
        }
        .backdrop(.tiles(Color(hex: 0x2F4A4F)))
    }

    private var meter: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: [
                            .init(color: Color(hex: 0xF6E7BD), location: 0),
                            .init(color: Color(hex: 0xEFA53A), location: 0.5),
                            .init(color: Color(hex: 0x5E3216), location: 0.85),
                            .init(color: Color(hex: 0x2A140A), location: 1),
                        ], startPoint: .leading, endPoint: .trailing))
                        .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                        .frame(width: w * 0.16)
                        .offset(x: w * 0.42)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.ink, lineWidth: 2.5))
                        .frame(width: 7, height: 44 * s)
                        .offset(x: w * scene.value - 3.5)
                }
            }
            .frame(height: 28 * s)
            HStack {
                Text("なま"); Spacer(); Text("きつね色"); Spacer(); Text("こげ")
            }
            .font(AppFont.black(11 * s))
            .foregroundStyle(.white)
            .padding(.top, 6 * s)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("揚げ加減メーター")
    }

    private func stop() {
        let v = scene.stop()
        let (label, mult) = Scoring.fryVerdict(v)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            verdict = "\(label) ×\(mult.formatted())"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { game.finishFry(v) }
    }
}

final class FryScene: GameScene, ObservableObject {
    /// Fry level 0 (raw) ... 1 (burnt), swinging back and forth until stopped.
    @Published private(set) var value: Double = 0
    @Published private(set) var stopped = false

    private let tail: TailKind
    private let bodyCount: Int
    private var shrimp: ShrimpNode!
    private var t0: TimeInterval?
    private var lastBubble: TimeInterval = 0
    private var oilSurface = CGPoint.zero
    private var oilHalfWidth: CGFloat = 0

    init(tail: TailKind, bodyCount: Int) {
        self.tail = tail
        self.bodyCount = bodyCount
        super.init()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        let bg = SKSpriteNode(texture: Tex.tiles(size, bg: UIColor(hex: 0x2F4A4F), line: UIColor(white: 1, alpha: 0.07), spacing: 36 * u))
        bg.size = size
        bg.anchorPoint = .zero
        bg.zPosition = -10
        addChild(bg)

        // pot artwork: 340 x 180 design units, oil surface at (150, 30) from its top-left corner (-20, -10)
        let potWidth = 280 * u
        let k = potWidth / 340
        let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
        for (name, z) in [("pot-back", 0.0), ("pot-front", 10.0)] as [(String, CGFloat)] {
            let pot = SKSpriteNode(asset: name, width: potWidth)
            pot.position = center
            pot.zPosition = z
            addChild(pot)
        }
        oilSurface = CGPoint(x: center.x + (170 - 170) * k, y: center.y + (90 - 40) * k)
        oilHalfWidth = 110 * k

        shrimp = ShrimpNode(tail: tail, count: bodyCount, skin: SegmentSkin.fry(0), unit: 0.62 * k)
        shrimp.zRotation = -.pi / 2  // lying down, tail to the right
        shrimp.position = CGPoint(x: oilSurface.x - shrimp.centerOffset, y: oilSurface.y - 6 * k)
        shrimp.zPosition = 5
        addChild(shrimp)
    }

    func stop() -> Double {
        guard !stopped else { return value }
        stopped = true
        Haptics.medium()
        return value
    }

    override func update(_ currentTime: TimeInterval) {
        guard isLaidOut else { return }
        if currentTime - lastBubble > 0.12 {
            lastBubble = currentTime
            let b = SKShapeNode(circleOfRadius: .random(in: 3...7) * u)
            b.strokeColor = UIColor(white: 1, alpha: 0.85)
            b.lineWidth = 2
            b.fillColor = UIColor(white: 1, alpha: 0.2)
            b.position = CGPoint(x: oilSurface.x + .random(in: -oilHalfWidth...oilHalfWidth), y: oilSurface.y)
            b.zPosition = 6
            addChild(b)
            b.run(.sequence([.group([.moveBy(x: 0, y: 70 * u, duration: 1.2), .fadeOut(withDuration: 1.2)]), .removeFromParent()]))
        }
        guard !stopped else { return }
        if t0 == nil { t0 = currentTime }
        let phase = ((currentTime - (t0 ?? currentTime)) / 1.5).truncatingRemainder(dividingBy: 2)
        value = phase < 1 ? phase : 2 - phase
        shrimp.setSkin(SegmentSkin.fry(value))
    }
}

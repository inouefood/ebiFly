import SpriteKit
import SwiftUI

struct BatterView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene: BatterScene

    init(tail: TailKind, bodyCount: Int) {
        _scene = StateObject(wrappedValue: BatterScene(tail: tail, bodyCount: bodyCount))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 6) {
                StepsBar(current: 1)
                HStack {
                    Pill(label: "のこり", value: "\(scene.timeLeft)", unit: "秒")
                    Spacer()
                    Pill(label: "パン粉", value: "\(scene.count)")
                }
                Spacer()
                if !scene.started {
                    Toast(text: "えびを左右にうごかしてパン粉をキャッチ", sub: "金のパン粉は3こぶん。水てきに当たると3こ落ちる")
                }
            }
            .padding(.horizontal, 18 * s)
            .padding(.top, 8)
            .padding(.bottom, 24 * s)
            .allowsHitTesting(false)

            if scene.finished {
                FinishOverlay(lead: "パン粉", big: "\(scene.count)こ", trail: "ゲット！", button: "揚げる") {
                    game.finishBatter(crumbs: scene.count)
                }
            }
        }
        .backdrop(.dots(Color(hex: 0xF6DC95), dot: Color(hex: 0xE9C06A)))
    }
}

/// Big result card shown at the end of a step.
struct FinishOverlay: View {
    let lead: String
    let big: String
    let trail: String
    let button: String
    let action: () -> Void
    @Environment(\.uiScale) private var s
    @State private var shown = false

    var body: some View {
        ZStack {
            Color(hex: 0xFFF6DC, alpha: 0.86).ignoresSafeArea()
            VStack(spacing: 14 * s) {
                Text(lead).font(AppFont.black(15 * s))
                OutlinedText(text: big, font: AppFont.display(46 * s), fill: Palette.accent, width: 2.5)
                Text(trail).font(AppFont.black(15 * s))
                Button(button, action: action).buttonStyle(GameButtonStyle())
            }
            .foregroundStyle(Palette.ink)
            .scaleEffect(shown ? 1 : 0.5)
            .opacity(shown ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { shown = true } }
    }
}

/// Crumbs rain down and the shrimp, dragged left and right along the bottom, catches them.
/// Gold crumbs count triple; water drops knock crumbs back off. It speeds up as time runs out.
final class BatterScene: GameScene, ObservableObject {
    @Published private(set) var timeLeft = Int(Scoring.batterSeconds)
    @Published private(set) var count = 0
    @Published private(set) var started = false
    @Published private(set) var finished = false

    private enum Kind { case crumb, gold, water }
    private struct Falling {
        let node: SKSpriteNode
        let kind: Kind
        let speed: CGFloat   // px/s at u = 1
    }

    /// Crumbs at which the batter looks fully coated.
    static let fullCoat = 180
    private static let waterPenalty = 3

    private let tail: TailKind
    private let bodyCount: Int
    private var shrimp: ShrimpNode!
    private var falling: [Falling] = []
    private var lastTouch: CGPoint?
    private var startTime: TimeInterval?
    private var lastTime: TimeInterval?
    private var lastSpawn: TimeInterval = 0
    private var lastBurst: TimeInterval = 0
    private var lastExtra: TimeInterval = 0
    private var tilt: CGFloat = 0

    init(tail: TailKind, bodyCount: Int) {
        self.tail = tail
        self.bodyCount = bodyCount
        super.init()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        let bg = SKSpriteNode(texture: Tex.dots(size, bg: UIColor(hex: 0xF6DC95), dot: UIColor(hex: 0xE9C06A), spacing: 14 * u, radius: 1.8 * u))
        bg.size = size
        bg.anchorPoint = .zero
        bg.zPosition = -10
        addChild(bg)

        shrimp = ShrimpNode(tail: tail, count: bodyCount, skin: SegmentSkin.batter(0), unit: 62 * u / ShrimpGeometry.width)
        shrimp.position = CGPoint(x: size.width / 2, y: shrimp.bottomExtent + 120 * u)
        shrimp.zPosition = 5
        shrimp.startWiggle()
        addChild(shrimp)
        #if DEBUG
        // `-startScreen batter` starts the timer right away so it can be checked without touching
        if UserDefaults.standard.string(forKey: "startScreen") == "batter" { started = true }
        #endif
    }

    /// A heap of plain crumbs dumped around one spot.
    private func spawnBurst(progress t: CGFloat) {
        let cx = CGFloat.random(in: 50 * u...(size.width - 50 * u))
        for i in 0..<Int.random(in: 5...8) {
            spawn(progress: t, kind: .crumb, x: cx + .random(in: -40...40) * u, lift: CGFloat(i) * 14 * u)
        }
    }

    private func spawn(progress t: CGFloat, kind forced: Kind? = nil, x: CGFloat? = nil, lift: CGFloat = 0) {
        let r = Double.random(in: 0..<1)
        let kind: Kind = forced ?? (r < 0.04 ? .gold : r < 0.04 + 0.18 + 0.12 * Double(t) ? .water : .crumb)
        let node: SKSpriteNode
        switch kind {
        case .crumb:
            node = SKSpriteNode(asset: "crumb", width: 22 * u)
        case .gold:
            node = SKSpriteNode(asset: "crumb", width: 24 * u)
            node.color = UIColor(hex: 0xFFC21A)
            node.colorBlendFactor = 0.65
            let glow = SKShapeNode(circleOfRadius: 17 * u)
            glow.fillColor = UIColor(hex: 0xFFF3B0).withAlphaComponent(0.7)
            glow.strokeColor = UIColor(hex: 0xF2B632)
            glow.lineWidth = 2 * u
            glow.zPosition = -0.1
            node.addChild(glow)
        case .water:
            node = SKSpriteNode(asset: "water-drop", width: 22 * u)
        }
        let px = x ?? .random(in: 24 * u...(size.width - 24 * u))
        node.position = CGPoint(x: min(max(px, 16 * u), size.width - 16 * u), y: size.height + 20 * u + lift)
        if kind != .water { node.zRotation = .random(in: 0...(2 * .pi)) }
        node.zPosition = kind == .water ? 3 : 2
        addChild(node)
        // everything falls faster as the timer runs down; gold is quickest
        let base: CGFloat = 170 + 170 * t
        let speed = base * (kind == .gold ? 1.35 : kind == .water ? 1.1 : 1) * .random(in: 0.85...1.15)
        falling.append(Falling(node: node, kind: kind, speed: speed))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let t = touches.first else { return }
        lastTouch = t.location(in: self)
        if !started { started = true }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let t = touches.first, let last = lastTouch else { return }
        let p = t.location(in: self)
        let dx = p.x - last.x
        lastTouch = p
        shrimp.position.x = min(max(shrimp.position.x + dx, 30 * u), size.width - 30 * u)
        tilt = min(max(tilt - dx * 0.8, -24), 24)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }

    override func update(_ currentTime: TimeInterval) {
        guard isLaidOut else { return }
        tilt *= 0.9
        shrimp.zRotation = tilt * .pi / 180
        let dt = CGFloat(min(0.05, currentTime - (lastTime ?? currentTime)))
        lastTime = currentTime
        guard started, !finished else { return }
        if startTime == nil { startTime = currentTime }
        let elapsed = currentTime - (startTime ?? currentTime)
        let progress = CGFloat(min(1, elapsed / Scoring.batterSeconds))
        let left = max(0, Int(ceil(Scoring.batterSeconds - elapsed)))
        if left != timeLeft { timeLeft = left }

        let interval = 0.13 - 0.06 * Double(progress)
        if currentTime - lastSpawn > interval {
            lastSpawn = currentTime
            spawn(progress: progress)
        }
        // extra plain crumbs: crumbs fall at 3x the rate of the mixed stream (water drops stay as they are)
        if currentTime - lastExtra > interval / 2 {
            lastExtra = currentTime
            spawn(progress: progress, kind: .crumb)
        }
        if currentTime - lastBurst > 1.4 / 3 {
            lastBurst = currentTime
            spawnBurst(progress: progress)
        }

        // the body (not the tail) catches things
        let p = shrimp.position
        let half = 26 * u
        let top = p.y + 50 * shrimp.unit, bottom = p.y - shrimp.bottomExtent
        var gained = 0, lost = 0
        falling.removeAll { f in
            f.node.position.y -= f.speed * u * dt
            let pos = f.node.position
            if abs(pos.x - p.x) < half && pos.y < top && pos.y > bottom {
                switch f.kind {
                case .crumb: gained += 1
                case .gold: gained += 3
                case .water: lost += Self.waterPenalty
                }
                f.node.run(.sequence([.group([.scale(to: 0.2, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                return true
            }
            if pos.y < -30 * u {
                f.node.removeFromParent()
                return true
            }
            return false
        }
        if gained > 0 {
            count += gained
            Haptics.light()
            popup("+\(gained)", color: gained >= 3 ? UIColor(hex: 0xE0A000) : UIColor(hex: 0x3A2418))
        }
        if lost > 0 {
            let actual = min(lost, count)
            count -= actual
            Haptics.heavy()
            popup(actual > 0 ? "-\(actual)" : "びしょっ", color: UIColor(hex: 0x2F7FD0))
            shrimp.run(.sequence([.moveBy(x: -5 * u, y: 0, duration: 0.03), .moveBy(x: 10 * u, y: 0, duration: 0.06), .moveBy(x: -5 * u, y: 0, duration: 0.03)]))
        }
        if gained > 0 || lost > 0 {
            shrimp.setSkin(SegmentSkin.batter(Double(count) / Double(Self.fullCoat)))
        }

        if elapsed >= Scoring.batterSeconds {
            finished = true
            lastTouch = nil
            for f in falling { f.node.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])) }
            falling.removeAll()
            Haptics.success()
        }
    }

    private func popup(_ text: String, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontName = AppFont.displayName
        label.fontSize = 22 * u
        label.fontColor = color
        label.position = CGPoint(x: shrimp.position.x + 34 * u, y: shrimp.position.y + 40 * u)
        label.zPosition = 20
        addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 36 * u, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
    }
}

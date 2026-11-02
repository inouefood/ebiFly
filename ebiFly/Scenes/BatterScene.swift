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
                    Toast(text: "えびをドラッグしてパン粉をあつめよう", sub: "10秒間でたくさんつけるほど遠くへ飛ぶ")
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

final class BatterScene: GameScene, ObservableObject {
    @Published private(set) var timeLeft = Int(Scoring.batterSeconds)
    @Published private(set) var count = 0
    @Published private(set) var started = false
    @Published private(set) var finished = false

    private let tail: TailKind
    private let bodyCount: Int
    private var shrimp: ShrimpNode!
    private var crumbs: [SKSpriteNode] = []
    private var lastTouch: CGPoint?
    private var startTime: TimeInterval?
    private var lastSpawn: TimeInterval = 0
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
        shrimp.position = CGPoint(x: size.width / 2, y: size.height - 170 * u)
        shrimp.zPosition = 5
        shrimp.startWiggle()
        addChild(shrimp)

        for _ in 0..<28 { spawnCrumb(animated: false) }
    }

    private var playArea: CGRect {
        CGRect(x: 20 * u, y: 80 * u, width: size.width - 40 * u, height: size.height - 220 * u)
    }

    private func spawnCrumb(animated: Bool) {
        let c = SKSpriteNode(asset: "crumb", width: 22 * u)
        let a = playArea
        c.position = CGPoint(x: .random(in: a.minX...a.maxX), y: .random(in: a.minY...a.maxY))
        c.zRotation = .random(in: 0...(2 * .pi))
        c.zPosition = 1
        if animated {
            c.setScale(0.1)
            c.run(.scale(to: 1, duration: 0.2))
        }
        addChild(c)
        crumbs.append(c)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let t = touches.first else { return }
        lastTouch = t.location(in: self)
        if !started { started = true }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let t = touches.first, let last = lastTouch else { return }
        let p = t.location(in: self)
        let dx = p.x - last.x, dy = p.y - last.y
        lastTouch = p
        shrimp.position.x = min(max(shrimp.position.x + dx, 30 * u), size.width - 30 * u)
        shrimp.position.y = min(max(shrimp.position.y + dy, shrimp.bottomExtent + 10 * u), size.height - 110 * u)
        tilt = min(max(tilt - dx * 0.8, -24), 24)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }

    override func update(_ currentTime: TimeInterval) {
        guard isLaidOut else { return }
        tilt *= 0.9
        shrimp.zRotation = tilt * .pi / 180
        guard started, !finished else { return }
        if startTime == nil { startTime = currentTime }
        let elapsed = currentTime - (startTime ?? currentTime)
        let left = max(0, Int(ceil(Scoring.batterSeconds - elapsed)))
        if left != timeLeft { timeLeft = left }

        if currentTime - lastSpawn > 0.25, crumbs.count < 24 {
            lastSpawn = currentTime
            spawnCrumb(animated: true)
        }

        // the body (not the tail) picks up crumbs
        let p = shrimp.position
        let half = 30 * u
        let top = p.y + 50 * shrimp.unit, bottom = p.y - shrimp.bottomExtent
        var got = 0
        crumbs.removeAll { c in
            let hit = abs(c.position.x - p.x) < half && c.position.y < top && c.position.y > bottom
            if hit {
                got += 1
                c.run(.sequence([.group([.scale(to: 0.2, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
            }
            return hit
        }
        if got > 0 {
            count += got
            Haptics.light()
            shrimp.setSkin(SegmentSkin.batter(Double(count) / 25))
        }

        if elapsed >= Scoring.batterSeconds {
            finished = true
            lastTouch = nil
            Haptics.success()
        }
    }
}

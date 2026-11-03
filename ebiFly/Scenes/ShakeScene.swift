import SpriteKit
import SwiftUI

struct ShakeView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene: ShakeScene

    init(tail: TailKind, bodyCount: Int, fry: Double) {
        _scene = StateObject(wrappedValue: ShakeScene(tail: tail, bodyCount: bodyCount, fry: fry))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 0) {
                StepsBar(current: 3)
                Text("ソースをかける").font(AppFont.display(24 * s)).foregroundStyle(Palette.ink).padding(.top, 4)
                Pill(label: "のこり", value: "\(scene.timeLeft)", unit: "秒")
                    .padding(.top, 6 * s)
                    .opacity(scene.started ? 1 : 0.5)
                Spacer()
                gauge
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("シェイク").font(AppFont.black(13 * s))
                    Text("\(scene.shakes)").font(AppFont.display(20 * s)).monospacedDigit()
                    Text("回").font(AppFont.black(13 * s))
                }
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 8 * s)
                Group {
                    if scene.finished {
                        Color.clear
                    } else if scene.started {
                        Toast(text: "もっとふって！")
                    } else {
                        Toast(text: "iPhoneをふってソースをかけよう", sub: "ふった回数で飛ぶ高さと上昇スピードがアップ（画面タップでもOK）")
                    }
                }
                .frame(minHeight: 56 * s)
            }
            .padding(.horizontal, 18 * s)
            .padding(.top, 8)
            .padding(.bottom, 20 * s)
            .allowsHitTesting(false)

            if scene.finished {
                FinishOverlay(lead: "シェイク", big: "\(scene.shakes)回",
                              trail: "ソース「\(Scoring.sauceLabel(shakes: scene.shakes))」", button: "とばす！") {
                    game.finishShake(scene.shakes)
                }
            }
        }
        .backdrop(.counter(wall: Color(hex: 0xFFE0D2), wallLow: Color(UIColor(hex: 0xFFE0D2).mixed(with: .white, 0.5)), counter: Color(hex: 0xE8C79A), edge: 0.52))
    }

    private var gauge: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white)
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0xF2B632), Palette.accent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(1, CGFloat(scene.shakes) / 30))
                    .animation(.easeOut(duration: 0.1), value: scene.shakes)
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
        }
        .frame(height: 22 * s)
        .accessibilityLabel("パワー")
        .accessibilityValue("\(scene.shakes)回")
    }
}

final class ShakeScene: GameScene, ObservableObject {
    @Published private(set) var shakes = 0
    @Published private(set) var timeLeft = Int(Scoring.shakeSeconds)
    @Published private(set) var started = false
    @Published private(set) var finished = false

    private let tail: TailKind
    private let bodyCount: Int
    private let fry: Double
    private let motion = MotionService()
    private var bottle: SKSpriteNode!
    private var shrimp: ShrimpNode!

    init(tail: TailKind, bodyCount: Int, fry: Double) {
        self.tail = tail
        self.bodyCount = bodyCount
        self.fry = fry
        super.init()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        let bg = SKSpriteNode(texture: Tex.gradient(size, top: UIColor(hex: 0xFFE0D2), bottom: UIColor(hex: 0xE8C79A), split: 0.52))
        bg.size = size
        bg.anchorPoint = .zero
        bg.zPosition = -10
        addChild(bg)

        let edge = SKShapeNode(rect: CGRect(x: 0, y: size.height * 0.48 - 2, width: size.width, height: 4))
        edge.fillColor = UIColor(hex: 0x3A2418)
        edge.lineWidth = 0
        edge.zPosition = -9
        addChild(edge)

        shrimp = ShrimpNode(tail: tail, count: bodyCount, skin: SegmentSkin.fry(fry), unit: 54 * u / ShrimpGeometry.width)
        shrimp.zRotation = -.pi / 2
        shrimp.position = CGPoint(x: size.width / 2 - shrimp.centerOffset, y: size.height * 0.42)
        shrimp.zPosition = 2
        addChild(shrimp)

        bottle = SKSpriteNode(asset: "sauce", width: 76 * u)
        bottle.position = CGPoint(x: size.width * 0.6, y: size.height * 0.66)
        bottle.zRotation = 150 * .pi / 180
        bottle.zPosition = 5
        addChild(bottle)

        motion.startShakeDetection { [weak self] in self?.registerShake() }
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        motion.stop()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        registerShake()
    }

    private func registerShake() {
        guard isLaidOut, !finished else { return }
        if !started {
            started = true
            let tick = SKAction.sequence([.wait(forDuration: 1), .run { [weak self] in
                guard let self else { return }
                self.timeLeft = max(0, self.timeLeft - 1)
            }])
            run(.repeat(tick, count: Int(Scoring.shakeSeconds)))
            run(.sequence([.wait(forDuration: Scoring.shakeSeconds), .run { [weak self] in self?.finish() }]))
        }
        shakes += 1
        Haptics.light()

        bottle.removeAction(forKey: "shake")
        let base = 150 * CGFloat.pi / 180
        bottle.run(.sequence([.rotate(toAngle: base + 0.25, duration: 0.05), .rotate(toAngle: base, duration: 0.07)]), withKey: "shake")

        // spout is the top of the bottle, rotated with it
        let h = bottle.size.height / 2
        let spout = CGPoint(x: bottle.position.x - sin(bottle.zRotation) * h * 0.9, y: bottle.position.y + cos(bottle.zRotation) * h * 0.9)
        let drop = SKSpriteNode(asset: "sauce-drop", width: 14 * u)
        drop.position = CGPoint(x: spout.x + .random(in: -8...8) * u, y: spout.y)
        drop.zPosition = 4
        addChild(drop)
        let fall = SKAction.moveTo(y: shrimp.position.y + 10 * u, duration: 0.45)
        fall.timingMode = .easeIn
        drop.run(.sequence([fall, .group([.scaleX(to: 1.6, y: 0.4, duration: 0.15), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
    }

    private func finish() {
        timeLeft = 0
        finished = true
        motion.stop()
        Haptics.success()
    }
}

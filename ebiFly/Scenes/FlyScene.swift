import SpriteKit
import SwiftUI

struct FlyView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene: FlyScene
    @State private var showHint = true

    init(tail: TailKind, bodyCount: Int, fry: Double, maxDistance: Int) {
        _scene = StateObject(wrappedValue: FlyScene(tail: tail, bodyCount: bodyCount, fry: fry, maxDistance: maxDistance))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    OutlinedText(text: scene.altitude.formatted(), font: AppFont.display(44 * s), fill: .white, width: 2.5)
                    OutlinedText(text: "m", font: AppFont.display(22 * s), fill: .white, width: 2)
                    OutlinedText(text: "/ \(scene.maxDistance.formatted())", font: AppFont.display(15 * s), fill: .white, width: 2)
                }
                .padding(.top, 12 * s)
                Spacer()
                if showHint {
                    Toast(text: scene.usesTilt ? "iPhoneをかたむけてよけよう" : "左右にドラッグしてよけよう",
                          sub: "鳥・飛行機・いん石にぶつかったらそこまで")
                        .transition(.opacity)
                }
                Text(scene.zone)
                    .font(AppFont.black(13 * s))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 18 * s)
            .padding(.bottom, 22 * s)
            .allowsHitTesting(false)

            if let outcome = scene.outcome {
                ZStack {
                    Color(hex: 0xFFF6DC, alpha: 0.6).ignoresSafeArea()
                    VStack(spacing: 8) {
                        OutlinedText(text: outcome.hitBy == nil ? "とびきった！" : "ぶつかった！",
                                     font: AppFont.display(40 * s), fill: Palette.accent, width: 2.5)
                        Text("\(outcome.distance.formatted()) m").font(AppFont.black(18 * s)).foregroundStyle(Palette.ink)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: scene.outcome)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { withAnimation { showHint = false } }
        }
        .onChange(of: scene.outcome) { outcome in
            guard let outcome else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                game.finishFlight(distance: outcome.distance, hitBy: outcome.hitBy)
            }
        }
    }
}

struct FlightOutcome: Equatable {
    let distance: Int
    let hitBy: Obstacle?
}

final class FlyScene: GameScene, ObservableObject {
    @Published private(set) var altitude = 0
    @Published private(set) var zone = "キッチン"
    @Published private(set) var outcome: FlightOutcome?
    let maxDistance: Int
    var usesTilt: Bool { motion.isAvailable }

    private let tail: TailKind
    private let bodyCount: Int
    private let fry: Double
    private let motion = MotionService()

    private struct Item {
        let node: SKSpriteNode
        var altitude: CGFloat
        var x: CGFloat           // left edge
        let width: CGFloat
        let height: CGFloat
        var vx: CGFloat = 0      // px/s at u = 1
        var fall: CGFloat = 0    // m/s
        var obstacle: Obstacle?
    }

    private var items: [Item] = []
    private var flyer: ShrimpNode!
    private var ground: SKSpriteNode!
    private var floor: SKSpriteNode!
    private var sky: SKSpriteNode!
    private var skyKey = -1
    private var camera0: CGFloat = 0           // altitude in m
    private var flyerX: CGFloat = 0
    private var tilt: CGFloat = 0
    private var lastTouch: CGPoint?
    private var lastTime: TimeInterval?
    private var startTime: TimeInterval?

    /// pixels per meter, and how fast the camera climbs
    private var k: CGFloat { 0.45 * u }
    private let climbSpeed: CGFloat = 400
    /// The shrimp flies in the lower part of the screen so the player sees what's coming.
    private var flyerY: CGFloat { size.height * 0.3 }

    private static let skyStops: [(CGFloat, UInt32, UInt32)] = [
        (0, 0x8FD8FF, 0xD8F3FF), (1500, 0x4FB0F0, 0xA8DCFF), (3000, 0x2B6FD1, 0x5AA6EE),
        (4500, 0x1B2F7A, 0x2F5BB5), (6500, 0x070B26, 0x141C4A),
    ]
    private static let zones: [(Int, String)] = [
        (0, "キッチン"), (200, "鳥のエリア"), (1500, "飛行機のエリア"), (3400, "いん石のエリア"), (5500, "宇宙"),
    ]

    init(tail: TailKind, bodyCount: Int, fry: Double, maxDistance: Int) {
        self.tail = tail
        self.bodyCount = bodyCount
        self.fry = fry
        self.maxDistance = max(maxDistance, 300)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        sky = SKSpriteNode(color: .cyan, size: size)
        sky.anchorPoint = .zero
        sky.zPosition = -10
        addChild(sky)
        updateSky(0)

        flyerX = size.width / 2
        flyer = ShrimpNode(tail: tail, count: bodyCount, skin: SegmentSkin.fry(fry), unit: 62 * u / ShrimpGeometry.width)
        flyer.zRotation = .pi  // head up, tail down
        flyer.zPosition = 10
        flyer.startWiggle()
        addChild(flyer)
        flyer.run(.repeatForever(.sequence([.run { [weak self] in self?.emitTrail() }, .wait(forDuration: 0.08)])))

        ground = SKSpriteNode(asset: "pot-front", width: 240 * u)
        ground.zPosition = 2
        addChild(ground)
        floor = SKSpriteNode(color: UIColor(hex: 0xE8C79A), size: CGSize(width: size.width, height: size.height))
        floor.anchorPoint = CGPoint(x: 0, y: 1)
        floor.zPosition = 1
        addChild(floor)
        let edge = SKSpriteNode(color: UIColor(hex: 0x3A2418), size: CGSize(width: size.width, height: 4))
        edge.anchorPoint = CGPoint(x: 0, y: 1)
        floor.addChild(edge)

        buildWorld()
        motion.startTilt()
        place(at: 0)
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        motion.stop()
    }

    private func addItem(_ asset: String, altitude: CGFloat, x: CGFloat, width: CGFloat, z: CGFloat) -> Item {
        let node = SKSpriteNode(asset: asset, width: width * u)
        node.zPosition = z
        addChild(node)
        return Item(node: node, altitude: altitude, x: x * u, width: node.size.width, height: node.size.height)
    }

    private func buildWorld() {
        let D = CGFloat(maxDistance)
        var a: CGFloat = 350
        while a < min(D + 900, 5000) {
            items.append(addItem("cloud", altitude: a, x: .random(in: -20...200), width: .random(in: 110...160), z: 1))
            a += .random(in: 230...350)
        }
        a = 3400
        while a < D + 900 {
            items.append(addItem("star", altitude: a, x: .random(in: 0...280), width: .random(in: 10...22), z: 0))
            a += .random(in: 60...140)
        }
        items.append(addItem("moon", altitude: 5600, x: 170, width: 100, z: 0.5))

        a = 700
        while a < D {
            let kind: Obstacle = a < 1500 ? .bird : a < 3400 ? (Bool.random() ? .plane : .bird) : .meteor
            let width: CGFloat = kind == .plane ? 120 : kind == .bird ? 46 : 50
            var item = addItem(kind.rawValue, altitude: a, x: .random(in: 0...(300 - width)), width: width, z: 5)
            let dir: CGFloat = Bool.random() ? 1 : -1
            item.vx = dir * (kind == .plane ? .random(in: 70...120) : .random(in: 30...80))
            item.fall = kind == .meteor ? 70 : 0
            item.obstacle = kind
            if dir < 0 { item.node.xScale = -1 }
            items.append(item)
            a += .random(in: 230...390)
        }
    }

    private func screenY(top altitude: CGFloat, camera c: CGFloat) -> CGFloat {
        flyerY + (altitude - c) * k
    }

    private func place(at c: CGFloat) {
        for item in items {
            let top = screenY(top: item.altitude, camera: c)
            item.node.position = CGPoint(x: item.x + item.width / 2, y: top - item.height / 2)
        }
        let groundTop = flyerY - 20 * u - c * k
        ground.position = CGPoint(x: size.width / 2, y: groundTop - ground.size.height / 2)
        floor.position = CGPoint(x: 0, y: groundTop - ground.size.height + 4 * u)
        flyer.position = CGPoint(x: flyerX, y: flyerY)
        flyer.zRotation = .pi + tilt * .pi / 180
        updateSky(c)
    }

    private func updateSky(_ c: CGFloat) {
        let key = Int(c / 40)
        guard key != skyKey else { return }
        skyKey = key
        let stops = Self.skyStops
        var top = UIColor(hex: stops[0].1), bottom = UIColor(hex: stops[0].2)
        for i in 1..<stops.count where c <= stops[i].0 || i == stops.count - 1 {
            let t = (c - stops[i - 1].0) / (stops[i].0 - stops[i - 1].0)
            top = UIColor(hex: stops[i - 1].1).mixed(with: UIColor(hex: stops[i].1), t)
            bottom = UIColor(hex: stops[i - 1].2).mixed(with: UIColor(hex: stops[i].2), t)
            break
        }
        sky.texture = Tex.gradient(CGSize(width: 4, height: 64), top: top, bottom: bottom)
    }

    private func emitTrail() {
        guard outcome == nil else { return }
        let drop = SKSpriteNode(asset: "oil-drop", width: 12 * u)
        drop.position = flyer.convert(CGPoint(x: .random(in: -25...25) * flyer.unit, y: flyer.tailTip.y), to: self)
        drop.zRotation = .pi
        drop.zPosition = 9
        addChild(drop)
        drop.run(.sequence([.group([.moveBy(x: 0, y: -60 * u, duration: 0.6), .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouch = touches.first?.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard outcome == nil, let p = touches.first?.location(in: self), let last = lastTouch else { return }
        let dx = p.x - last.x
        lastTouch = p
        flyerX = min(max(flyerX + dx, 20 * u), size.width - 20 * u)
        tilt = min(max(tilt - dx * 1.5, -25), 25)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { lastTouch = nil }

    override func update(_ currentTime: TimeInterval) {
        guard isLaidOut, outcome == nil else { return }
        let dt = CGFloat(min(0.05, currentTime - (lastTime ?? currentTime)))
        lastTime = currentTime
        if startTime == nil { startTime = currentTime }

        // short run-up so the player can get ready
        let warmup = min(1, (currentTime - (startTime ?? currentTime)) / 0.8)
        camera0 = min(CGFloat(maxDistance), camera0 + climbSpeed * CGFloat(warmup) * dt)

        let gx = CGFloat(motion.tiltX)
        if abs(gx) > 0.03 {
            flyerX = min(max(flyerX + gx * 900 * u * dt, 20 * u), size.width - 20 * u)
            tilt = min(max(tilt - gx * 40, -25), 25)
        }
        tilt *= 0.9

        let width = size.width
        for i in items.indices where items[i].obstacle != nil {
            items[i].x += items[i].vx * u * dt
            if items[i].x > width { items[i].x = -items[i].width }
            if items[i].x < -items[i].width { items[i].x = width }
            items[i].altitude -= items[i].fall * dt
        }
        place(at: camera0)

        let alt = Int(camera0)
        if alt != altitude { altitude = alt }
        if let z = Self.zones.last(where: { alt >= $0.0 })?.1, z != zone { zone = z }

        if let hit = collidingObstacle() {
            end(hitBy: hit)
        } else if camera0 >= CGFloat(maxDistance) {
            end(hitBy: nil)
        }
    }

    /// Hit box: a narrow column over the body, from the head down to just above the tail.
    private func collidingObstacle() -> Obstacle? {
        let headTop = flyer.position.y + flyer.bottomExtent - 8 * u
        let tailEnd = flyer.position.y - flyer.topExtent + 30 * u
        let box = CGRect(x: flyerX - 14 * u, y: tailEnd, width: 28 * u, height: headTop - tailEnd)
        for item in items {
            guard let kind = item.obstacle else { continue }
            let f = item.node.frame
            let r = f.insetBy(dx: f.width * 0.15, dy: f.height * 0.2)
            if r.intersects(box) { return kind }
        }
        return nil
    }

    private func end(hitBy: Obstacle?) {
        outcome = FlightOutcome(distance: Int(camera0), hitBy: hitBy)
        motion.stop()
        if hitBy != nil {
            Haptics.heavy()
            let s = SKAction.sequence([.moveBy(x: -6, y: 0, duration: 0.03), .moveBy(x: 12, y: 0, duration: 0.06), .moveBy(x: -6, y: 0, duration: 0.03)])
            flyer.run(.repeat(s, count: 4))
        } else {
            Haptics.success()
        }
    }
}

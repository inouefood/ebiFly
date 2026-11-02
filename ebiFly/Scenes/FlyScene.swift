import SpriteKit
import SwiftUI

struct FlyView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene: FlyScene
    @State private var showHint = true
    @State private var showingAd = false
    @ObservedObject private var ads = Ads.shared
    private let shakes: Int

    init(tail: TailKind, bodyCount: Int, fry: Double, shakes: Int, maxDistance: Int) {
        _scene = StateObject(wrappedValue: FlyScene(tail: tail, bodyCount: bodyCount, fry: fry,
                                                    climbSpeed: Scoring.climbSpeed(shakes: shakes), maxDistance: maxDistance))
        self.shakes = shakes
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    OutlinedText(text: scene.altitude.formatted(), font: AppFont.display(44 * s), fill: .white, width: 2.5)
                    OutlinedText(text: "m", font: AppFont.display(22 * s), fill: .white, width: 2)
                }
                .padding(.top, 12 * s)
                FuelGauge(level: scene.fuel, refuels: scene.refuelCount)
                    .padding(.top, 4)
                Pill(label: "ソース \(Scoring.sauceLabel(shakes: shakes))", value: "\(Int(scene.climbSpeed))", unit: "m/s")
                    .padding(.top, 2)
                Spacer()
                if showHint {
                    Toast(text: scene.usesTilt ? "iPhoneをかたむけてよけよう" : "左右にドラッグしてよけよう",
                          sub: "ソースのボトルで燃料ほきゅう。ぶつかったらそこまで")
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

            if let hit = scene.crashedInto {
                continueOffer(hit)
                    .transition(.scale.combined(with: .opacity))
            }

            if let outcome = scene.outcome {
                ZStack {
                    Color(hex: 0xFFF6DC, alpha: 0.6).ignoresSafeArea()
                    VStack(spacing: 8) {
                        OutlinedText(text: outcome.hitBy == nil ? "燃料切れ！" : "ぶつかった！",
                                     font: AppFont.display(40 * s), fill: Palette.accent, width: 2.5)
                        Text("\(outcome.distance.formatted()) m").font(AppFont.black(18 * s)).foregroundStyle(Palette.ink)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .backdrop(.gradient(top: Color(scene.skyTop), bottom: Color(scene.skyBottom)))
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: scene.outcome)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: scene.crashedInto)
        .onReceive(ads.$isRewardedReady) { scene.continueAvailable = $0 }
        #if DEBUG
        // `-autoWatchAd YES`: open the ad as soon as the offer appears, to check it without tapping
        .onChange(of: scene.crashedInto) { hit in
            if hit != nil, UserDefaults.standard.bool(forKey: "autoWatchAd") { watchAd() }
        }
        #endif
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { withAnimation { showHint = false } }
        }
        .onChange(of: scene.outcome) { outcome in
            guard let outcome else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                game.finishFlight(distance: outcome.distance, hitBy: outcome.hitBy, refuels: outcome.refuels)
            }
        }
    }
}

extension FlyView {
    private func watchAd() {
        showingAd = true
        Ads.shared.showRewarded { earned in
            showingAd = false
            if earned { scene.continueFlight() } else { scene.giveUp() }
        }
    }

    /// After a crash: watch a rewarded ad to keep flying from here (once per flight), or stop.
    private func continueOffer(_ hit: Obstacle) -> some View {
        ZStack {
            Color(hex: 0x1B1410, alpha: 0.45).ignoresSafeArea()
            VStack(spacing: 12 * s) {
                OutlinedText(text: "\(hit.displayName)にぶつかった！", font: AppFont.display(22 * s), fill: Palette.accent, width: 2.5)
                Text("\(scene.altitude.formatted()) m").font(AppFont.display(22 * s)).foregroundStyle(Palette.ink)
                Text("広告を見ると ここからつづきを飛べます\n（1回のフライトで1回まで）")
                    .font(AppFont.body(13 * s))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.ink)
                Button {
                    watchAd()
                } label: {
                    HStack(spacing: 6 * s) {
                        Image(systemName: "play.rectangle.fill")
                        Text("広告を見てつづきから")
                    }
                }
                .buttonStyle(GameButtonStyle(wide: true, size: 15))
                .disabled(showingAd)
                Button("ここまでにする") { scene.giveUp() }
                    .buttonStyle(GameButtonStyle(kind: .ghost, wide: true, size: 15))
                    .disabled(showingAd)
            }
            .padding(18 * s)
            .frame(width: 290 * s)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color(hex: 0xFFF6DC)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 3))
        }
    }
}

struct FlightOutcome: Equatable {
    let distance: Int
    let hitBy: Obstacle?
    let refuels: Int
}

/// Fuel left, 0...1. Turns red and blinks when it is about to run out.
struct FuelGauge: View {
    let level: Double
    /// Bumps on every refuel; the gauge flashes and shows "+" each time it changes.
    var refuels = 0
    @Environment(\.uiScale) private var s
    @State private var blink = false
    @State private var flash = false

    private var low: Bool { level < 0.2 }

    var body: some View {
        HStack(spacing: 6 * s) {
            Text("燃料").font(AppFont.black(13 * s)).foregroundStyle(Palette.ink)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white)
                    Capsule()
                        .fill(low ? AnyShapeStyle(Palette.accent)
                                  : AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xF2B632), Color(hex: 0x6CC04A)],
                                                                 startPoint: .leading, endPoint: .trailing)))
                        .frame(width: geo.size.width * max(0, min(1, level)))
                }
                .clipShape(Capsule())
                .overlay(Capsule().fill(Color.white.opacity(flash ? 0.7 : 0)))
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
            }
            .frame(height: 16 * s)
        }
        .frame(width: 196 * s)
        .padding(.horizontal, 12 * s).padding(.vertical, 6 * s)
        .background(Capsule().fill(flash ? Color(hex: 0xFFF3B0) : Color.white.opacity(0.85)))
        .overlay(Capsule().stroke(Color(hex: 0x5CBF4A), lineWidth: 4).opacity(flash ? 1 : 0))
        .overlay(alignment: .trailing) {
            OutlinedText(text: "+", font: AppFont.display(26 * s), fill: Color(hex: 0x5CBF4A), width: 2)
                .offset(x: 26 * s, y: flash ? -6 * s : 4 * s)
                .opacity(flash ? 1 : 0)
        }
        .scaleEffect(flash ? 1.12 : 1)
        .opacity(low && blink && !flash ? 0.45 : 1)
        .onChange(of: refuels) { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { flash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.3)) { flash = false }
            }
        }
        .onChange(of: low) { isLow in
            if isLow {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) { blink = true }
            } else {
                blink = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("燃料")
        .accessibilityValue("\(Int(level * 100))パーセント")
    }
}

final class FlyScene: GameScene, ObservableObject {
    @Published private(set) var altitude = 0
    @Published private(set) var zone = "キッチン"
    @Published private(set) var outcome: FlightOutcome?
    /// Set when the shrimp hit something and a "continue with an ad" offer is open; the flight is frozen meanwhile.
    @Published private(set) var crashedInto: Obstacle?
    /// Whether a rewarded ad is loaded (kept in sync by the view).
    var continueAvailable = false
    private var continueUsed = false
    private var invincibleUntil: TimeInterval = 0
    private var now: TimeInterval = 0
    /// Fuel left, 0...1 of the tank.
    @Published private(set) var fuel = 1.0
    /// How many refuels so far (drives the gauge flash).
    @Published private(set) var refuelCount = 0
    /// Current sky colours, so the space beside the column on wide screens matches the scene.
    @Published private(set) var skyTop = UIColor(hex: 0x8FD8FF)
    @Published private(set) var skyBottom = UIColor(hex: 0xD8F3FF)
    /// Tank size in meters of climbing: what the prep steps earned.
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
        var isFuel = false
    }

    /// Fuel is measured in meters of climbing. A sauce drop refills this much.
    private static let refuelMeters: CGFloat = 180
    private var fuelMeters: CGFloat = 0
    private var refuels = 0
    /// Once the tank is empty the shrimp coasts for a moment before stopping.
    private var coast: CGFloat = 1
    private var worldTop: CGFloat = 0
    private var nextCloud: CGFloat = 350
    private var nextStar: CGFloat = 3400
    private var nextObstacle: CGFloat = 700
    private var nextFuel: CGFloat = 480

    private var items: [Item] = []
    private var flyer: ShrimpNode!
    private var thrust: ThrustNode!
    private var lastSpeedLine: TimeInterval = 0
    private var launched = false
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
    /// Set by the sauce: more shakes, faster climb.
    let climbSpeed: CGFloat
    /// The shrimp flies in the lower part of the screen so the player sees what's coming.
    private var flyerY: CGFloat { size.height * 0.3 }

    private static let skyStops: [(CGFloat, UInt32, UInt32)] = [
        (0, 0x8FD8FF, 0xD8F3FF), (1500, 0x4FB0F0, 0xA8DCFF), (3000, 0x2B6FD1, 0x5AA6EE),
        (4500, 0x1B2F7A, 0x2F5BB5), (6500, 0x070B26, 0x141C4A),
    ]
    private static let zones: [(Int, String)] = [
        (0, "キッチン"), (200, "鳥のエリア"), (1500, "飛行機のエリア"), (3400, "いん石のエリア"), (5500, "宇宙"),
    ]

    init(tail: TailKind, bodyCount: Int, fry: Double, climbSpeed: Double, maxDistance: Int) {
        self.climbSpeed = CGFloat(climbSpeed)
        self.tail = tail
        self.bodyCount = bodyCount
        self.fry = fry
        self.maxDistance = max(maxDistance, 300)
        fuelMeters = CGFloat(self.maxDistance)
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
        thrust = ThrustNode(unit: u, power: climbSpeed / 460, target: self)
        thrust.position = flyer.tailTip
        thrust.zPosition = -1   // behind the tail fan
        flyer.addChild(thrust)

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
        items.append(addItem("moon", altitude: 5600, x: 170, width: 100, z: 0.5))
        extendWorld(to: 1500)
    }

    /// The flight has no fixed ceiling any more (refuels can take it past the tank),
    /// so the world is generated a little ahead of the camera.
    private func extendWorld(to top: CGFloat) {
        guard top > worldTop else { return }
        while nextCloud < min(top, 5000) {
            items.append(addItem("cloud", altitude: nextCloud, x: .random(in: -20...200), width: .random(in: 110...160), z: 1))
            nextCloud += .random(in: 230...350)
        }
        while nextStar < top {
            items.append(addItem("star", altitude: nextStar, x: .random(in: 0...280), width: .random(in: 10...22), z: 0))
            nextStar += .random(in: 60...140)
        }
        while nextObstacle < top {
            let a = nextObstacle
            let kind: Obstacle = a < 1500 ? .bird : a < 3400 ? (Bool.random() ? .plane : .bird) : .meteor
            let width: CGFloat = kind == .plane ? 120 : kind == .bird ? 46 : 50
            var item = addItem(kind.rawValue, altitude: a, x: .random(in: 0...(300 - width)), width: width, z: 5)
            let dir: CGFloat = Bool.random() ? 1 : -1
            item.vx = dir * (kind == .plane ? .random(in: 70...120) : .random(in: 30...80))
            item.fall = kind == .meteor ? 70 : 0
            item.obstacle = kind
            if dir < 0 { item.node.xScale = -1 }
            items.append(item)
            nextObstacle += .random(in: 230...390)
        }
        while nextFuel < top {
            var item = addItem("fuel", altitude: nextFuel, x: .random(in: 20...230), width: 50, z: 6)
            item.isFuel = true
            item.node.run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.35), .scale(to: 1, duration: 0.35)])))
            items.append(item)
            nextFuel += .random(in: 300...460)
        }
        worldTop = top
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
        skyTop = top
        skyBottom = bottom
    }

    /// White streaks rushing past, faster with more sauce.
    private func spawnSpeedLine() {
        let h = CGFloat.random(in: 50...120) * u
        let line = SKSpriteNode(color: .white, size: CGSize(width: 3 * u, height: h))
        line.alpha = .random(in: 0.25...0.5)
        line.position = CGPoint(x: .random(in: 0...size.width), y: size.height + h)
        line.zPosition = 0.9   // over the sky, under clouds and obstacles
        addChild(line)
        let v = climbSpeed * k * 1.8
        let dist = size.height + h * 2
        line.run(.sequence([.moveBy(x: 0, y: -dist, duration: TimeInterval(dist / v)), .removeFromParent()]))
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
        guard crashedInto == nil else {
            lastTime = nil   // no big time step when the flight resumes
            return
        }
        now = currentTime
        let dt = CGFloat(min(0.05, currentTime - (lastTime ?? currentTime)))
        lastTime = currentTime
        if startTime == nil { startTime = currentTime }

        // short run-up so the player can get ready
        let warmup = min(1, (currentTime - (startTime ?? currentTime)) / 0.8)
        if fuelMeters <= 0 { coast = max(0, coast - dt / 0.7) }
        let power = CGFloat(warmup) * coast
        let climb = climbSpeed * power * dt
        thrust.setIntensity(power)
        thrust.aim(shrimpRotation: flyer.zRotation)
        if !launched && warmup > 0.3 {
            launched = true
            thrust.burst()
            Haptics.medium()
        }
        if power > 0.5, currentTime - lastSpeedLine > 0.07 {
            lastSpeedLine = currentTime
            spawnSpeedLine()
        }
        camera0 += climb
        fuelMeters = max(0, fuelMeters - climb)
        extendWorld(to: camera0 + size.height / k + 400)

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
        collectFuel()
        let level = Double(fuelMeters / CGFloat(maxDistance))
        if abs(level - fuel) > 0.004 || (level == 0 && fuel != 0) { fuel = level }

        let alt = Int(camera0)
        if alt != altitude { altitude = alt }
        if let z = Self.zones.last(where: { alt >= $0.0 })?.1, z != zone { zone = z }

        #if DEBUG
        // `-flyAutopilot YES`: steer to the next bottle and ignore obstacles, for checking refuel effects
        if UserDefaults.standard.bool(forKey: "flyAutopilot") {
            if let target = items.filter({ $0.isFuel && $0.altitude > camera0 }).min(by: { $0.altitude < $1.altitude }) {
                flyerX += (target.x + target.width / 2 - flyerX) * min(1, 6 * dt)
            }
        }
        let autopilot = UserDefaults.standard.bool(forKey: "flyAutopilot")
        // `-flyCrashAt 6`: with the autopilot, crash into a bird after that many seconds (to test the continue offer)
        let crashAt = UserDefaults.standard.double(forKey: "flyCrashAt")
        if autopilot, crashAt > 0, !continueUsed, currentTime - (startTime ?? currentTime) > crashAt {
            if continueAvailable { crashedInto = .bird } else { end(hitBy: .bird) }
            return
        }
        #else
        let autopilot = false
        #endif
        if !autopilot, currentTime >= invincibleUntil, let hit = collidingObstacle() {
            if !continueUsed && continueAvailable {
                crashedInto = hit
                thrust.setIntensity(0)
                Haptics.heavy()
            } else {
                end(hitBy: hit)
            }
        } else if coast <= 0 {
            end(hitBy: nil)
        }
    }

    private func collectFuel() {
        let box = CGRect(x: flyerX - 24 * u, y: flyer.position.y - flyer.topExtent, width: 48 * u,
                         height: flyer.topExtent + flyer.bottomExtent)
        // drop what has scrolled far below the screen while we are at it
        let floorAlt = camera0 - (flyerY / k) - 200
        items.removeAll { item in
            if item.altitude < floorAlt && item.fall == 0 {
                item.node.removeFromParent()
                return true
            }
            guard item.isFuel, fuelMeters > 0, item.node.frame.intersects(box) else { return false }
            fuelMeters = min(CGFloat(maxDistance), fuelMeters + Self.refuelMeters)
            refuels += 1
            refuelCount = refuels
            Haptics.success()
            refuelPopup(at: item.node.position)
            thrust.burst()
            item.node.removeAllActions()
            item.node.run(.sequence([.group([.scale(to: 2, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
            return true
        }
    }

    /// "+燃料" floating up from where the bottle was picked up.
    private func refuelPopup(at p: CGPoint) {
        let node = SKNode()
        node.position = CGPoint(x: min(max(p.x, 60 * u), size.width - 60 * u), y: p.y + 10 * u)
        node.zPosition = 30
        let text = "+燃料"
        for (dx, dy) in [(-2, 0), (2, 0), (0, -2), (0, 2), (-1.5, -1.5), (1.5, 1.5), (-1.5, 1.5), (1.5, -1.5)] as [(CGFloat, CGFloat)] {
            let outline = SKLabelNode(text: text)
            outline.fontName = AppFont.displayName
            outline.fontSize = 24 * u
            outline.fontColor = UIColor(hex: 0x3A2418)
            outline.position = CGPoint(x: dx * u, y: dy * u)
            outline.zPosition = 0   // the view ignores sibling order, so layer explicitly
            node.addChild(outline)
        }
        let label = SKLabelNode(text: text)
        label.fontName = AppFont.displayName
        label.fontSize = 24 * u
        label.fontColor = UIColor(hex: 0x7CDB5A)
        label.zPosition = 1
        node.addChild(label)
        node.setScale(0.5)
        addChild(node)
        let pop = SKAction.scale(to: 1.15, duration: 0.15)
        pop.timingMode = .easeOut
        node.run(.sequence([
            pop, .scale(to: 1, duration: 0.1),
            .group([.moveBy(x: 0, y: 50 * u, duration: 0.7), .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.35)])]),
            .removeFromParent(),
        ]))
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

    /// Resume after the rewarded ad: clear what was hit and blink for a moment of safety.
    func continueFlight() {
        guard crashedInto != nil else { return }
        continueUsed = true
        let box = flyer.calculateAccumulatedFrame().insetBy(dx: -40 * u, dy: -40 * u)
        items.removeAll { item in
            guard item.obstacle != nil, item.node.frame.intersects(box) else { return false }
            item.node.run(.sequence([.group([.fadeOut(withDuration: 0.25), .scale(to: 1.4, duration: 0.25)]), .removeFromParent()]))
            return true
        }
        invincibleUntil = now + 2
        flyer.run(.repeat(.sequence([.fadeAlpha(to: 0.3, duration: 0.1), .fadeAlpha(to: 1, duration: 0.1)]), count: 10))
        crashedInto = nil
        Haptics.success()
    }

    func giveUp() {
        guard let hit = crashedInto else { return }
        crashedInto = nil
        end(hitBy: hit)
    }

    private func end(hitBy: Obstacle?) {
        outcome = FlightOutcome(distance: Int(camera0), hitBy: hitBy, refuels: refuels)
        thrust.setIntensity(0)
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

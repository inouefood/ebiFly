import SpriteKit
import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @StateObject private var scene = TitleScene()

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 6 * s) {
                    Text("とべ！")
                        .font(AppFont.display(20 * s))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Palette.accent))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.ink, lineWidth: 3))
                        .rotationEffect(.degrees(-4))
                    OutlinedText(text: "えびフライ", font: AppFont.display(52 * s), width: 3.5, shadow: 5)
                }
                .padding(.top, 40 * s)
                Spacer()
                VStack(spacing: 14 * s) {
                    Button("あそぶ") { game.startRun() }
                        .buttonStyle(GameButtonStyle(wide: true))
                    Button("きろく") { game.go(.records) }
                        .buttonStyle(GameButtonStyle(kind: .ghost, wide: true))
                }
                .frame(width: 200 * s)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("ベスト").font(AppFont.black(13 * s))
                    Text(game.best.formatted()).font(AppFont.display(18 * s)).monospacedDigit()
                    Text("m").font(AppFont.black(13 * s))
                    Text("・").font(AppFont.black(13 * s))
                    Text(game.points.formatted()).font(AppFont.display(18 * s)).monospacedDigit()
                    Text("pt").font(AppFont.black(13 * s))
                }
                .foregroundStyle(Palette.ink)
                .padding(.top, 14 * s)
                .padding(.bottom, 24 * s)
            }
        }
        .backdrop(.gradient(top: Color(hex: 0x7FD3FF), bottom: Color(hex: 0xFFE9A8)))
    }
}

/// Sky with drifting clouds and several fried shrimp flying across.
/// Tapping the sky drops an obstacle there; a shrimp that runs into one gets knocked away, then flies back in.
final class TitleScene: GameScene, ObservableObject {
    private struct Route {
        let x0, y0, x1, y1: CGFloat   // design px, y from top
        let duration: Double
        let phase: Double
        let width: CGFloat
        let count: Int
        let tail: TailKind
    }

    private let routes: [Route] = [
        Route(x0: -90, y0: 600, x1: 380, y1: 20, duration: 5.5, phase: 1.2, width: 54, count: 4, tail: .normal),
        Route(x0: 400, y0: 640, x1: -90, y1: 140, duration: 7, phase: 3.6, width: 42, count: 3, tail: .heart),
        Route(x0: -80, y0: 420, x1: 380, y1: -180, duration: 6.2, phase: 5, width: 36, count: 3, tail: .normal),
        Route(x0: 380, y0: 470, x1: -110, y1: -200, duration: 8, phase: 2.2, width: 48, count: 5, tail: .crown),
        Route(x0: 60, y0: 700, x1: 300, y1: -220, duration: 9, phase: 7.5, width: 30, count: 3, tail: .normal),
    ]

    private struct Flyer {
        let node: ShrimpNode
        let route: Route
        var knocked = false
    }

    private var flyers: [Flyer] = []
    private var obstacles: [SKSpriteNode] = []
    private static let maxObstacles = 5

    override func layout() {
        let h = size.height
        let bg = SKSpriteNode(texture: Tex.gradient(size, top: UIColor(hex: 0x7FD3FF), bottom: UIColor(hex: 0xFFE9A8)))
        bg.size = size
        bg.anchorPoint = .zero
        bg.zPosition = -10
        addChild(bg)

        for (x, y, cw, dur) in [(-30.0, 120.0, 130.0, 6.0), (190, 210, 120, 7), (160, 70, 80, 9), (20, 470, 110, 8)] as [(CGFloat, CGFloat, CGFloat, Double)] {
            let cloud = SKSpriteNode(asset: "cloud", width: cw * u)
            cloud.position = CGPoint(x: (x + cw / 2) * u, y: h - y * h / 640)
            cloud.zPosition = -5
            addChild(cloud)
            let drift = SKAction.moveBy(x: 24 * u, y: 0, duration: dur)
            drift.timingMode = .easeInEaseOut
            cloud.run(.repeatForever(.sequence([drift, drift.reversed()])))
        }

        for route in routes {
            let shrimp = ShrimpNode(tail: route.tail, count: route.count, skin: SegmentSkin.fry(0.5),
                                    unit: route.width * u / ShrimpGeometry.width)
            shrimp.zPosition = 1
            shrimp.startWiggle()
            addChild(shrimp)
            flyers.append(Flyer(node: shrimp, route: route))
            fly(shrimp, along: route, from: CGFloat(route.phase.truncatingRemainder(dividingBy: route.duration) / route.duration))
        }
        #if DEBUG
        // `-titleDemo YES`: drop obstacles on the routes by itself, to check the knock-away without tapping
        if UserDefaults.standard.bool(forKey: "titleDemo") {
            run(.repeatForever(.sequence([.wait(forDuration: 0.7), .run { [weak self] in
                guard let self, let r = self.routes.randomElement() else { return }
                let (p0, p1) = self.endpoints(r)
                let t = CGFloat.random(in: 0.3...0.7)
                self.placeObstacle(at: CGPoint(x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t))
            }])))
        }
        #endif
    }

    private func endpoints(_ r: Route) -> (CGPoint, CGPoint) {
        let h = size.height, sy = h / 640
        return (CGPoint(x: r.x0 * u + r.width * u / 2, y: h - r.y0 * sy),
                CGPoint(x: r.x1 * u + r.width * u / 2, y: h - r.y1 * sy))
    }

    /// Starts (or restarts) the endless flight along the route, `frac` of the way in.
    private func fly(_ shrimp: ShrimpNode, along r: Route, from frac: CGFloat) {
        let (p0, p1) = endpoints(r)
        let dx = p1.x - p0.x, dy = p1.y - p0.y
        // the head (local -y) faces the flight direction
        shrimp.zRotation = atan2(dx, -dy)
        shrimp.position = CGPoint(x: p0.x + dx * frac, y: p0.y + dy * frac)
        shrimp.alpha = 1
        shrimp.setScale(1)
        let first = SKAction.move(to: p1, duration: r.duration * Double(1 - frac))
        let loop = SKAction.sequence([.move(to: p0, duration: 0), .move(to: p1, duration: r.duration)])
        shrimp.run(.sequence([first, .repeatForever(loop)]), withKey: "fly")
        shrimp.run(.repeatForever(.sequence([
            .run { [weak self, weak shrimp] in
                guard let self, let shrimp else { return }
                self.emitDrop(from: shrimp)
            },
            .wait(forDuration: 0.16),
        ])), withKey: "trail")
    }

    private func emitDrop(from shrimp: ShrimpNode) {
        let drop = SKSpriteNode(asset: "oil-drop", width: 9 * u)
        drop.position = shrimp.convert(CGPoint(x: CGFloat.random(in: -20...20) * shrimp.unit, y: shrimp.tailTip.y), to: self)
        drop.zPosition = 0.5
        drop.zRotation = shrimp.zRotation + .pi
        addChild(drop)
        drop.run(.sequence([.group([.fadeOut(withDuration: 0.6), .scale(to: 0.4, duration: 0.6)]), .removeFromParent()]))
    }

    // MARK: tap to drop an obstacle

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isLaidOut, let p = touches.first?.location(in: self) else { return }
        placeObstacle(at: p)
    }

    private func placeObstacle(at p: CGPoint) {
        if obstacles.count >= Self.maxObstacles {
            let oldest = obstacles.removeFirst()
            oldest.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
        let kind = Obstacle.allCases.randomElement() ?? .bird
        let width: CGFloat = kind == .plane ? 96 : kind == .bird ? 46 : 50
        let node = SKSpriteNode(asset: kind.rawValue, width: width * u)
        node.position = p
        node.zPosition = 2
        if Bool.random() { node.xScale = -1 }
        let sx = node.xScale
        node.xScale = sx * 0.1
        node.yScale = 0.1
        addChild(node)
        obstacles.append(node)
        Haptics.light()

        let pop = SKAction.group([.scaleX(to: sx * 1.15, duration: 0.12), .scaleY(to: 1.15, duration: 0.12)])
        let settle = SKAction.group([.scaleX(to: sx, duration: 0.08), .scaleY(to: 1, duration: 0.08)])
        let bob = SKAction.sequence([.moveBy(x: 0, y: 6 * u, duration: 0.5), .moveBy(x: 0, y: -6 * u, duration: 0.5)])
        bob.timingMode = .easeInEaseOut
        node.run(.sequence([pop, settle]))
        node.run(.repeatForever(bob), withKey: "bob")
        // obstacles go away on their own after a while
        node.run(.sequence([
            .wait(forDuration: 4),
            .fadeOut(withDuration: 0.4),
            .run { [weak self, weak node] in
                guard let self, let node else { return }
                self.obstacles.removeAll { $0 === node }
            },
            .removeFromParent(),
        ]), withKey: "life")
    }

    // MARK: collisions

    override func update(_ currentTime: TimeInterval) {
        guard isLaidOut, !obstacles.isEmpty else { return }
        for i in flyers.indices where !flyers[i].knocked {
            let shrimp = flyers[i].node
            guard let hit = obstacles.first(where: { touches(shrimp, $0) }) else { continue }
            flyers[i].knocked = true
            knockAway(i, from: hit)
        }
    }

    /// Checks a few points down the middle of the body against the obstacle (trimmed to its drawn shape).
    private func touches(_ shrimp: ShrimpNode, _ obstacle: SKSpriteNode) -> Bool {
        let f = obstacle.frame
        let box = f.insetBy(dx: f.width * 0.15, dy: f.height * 0.2)
        let r = 40 * shrimp.unit
        var y: CGFloat = 0
        while y > -shrimp.bottomExtent + r {
            let p = shrimp.convert(CGPoint(x: 0, y: y), to: self)
            if box.insetBy(dx: -r, dy: -r).contains(p) { return true }
            y -= 50 * shrimp.unit
        }
        return false
    }

    private func knockAway(_ i: Int, from obstacle: SKSpriteNode) {
        let shrimp = flyers[i].node
        shrimp.removeAction(forKey: "fly")
        shrimp.removeAction(forKey: "trail")
        Haptics.medium()

        // bounce away from the obstacle, a little upward, spinning
        var dx = shrimp.position.x - obstacle.position.x
        var dy = shrimp.position.y - obstacle.position.y
        let len = max(1, hypot(dx, dy))
        dx /= len
        dy /= len
        let dist = 420 * u
        let target = CGPoint(x: shrimp.position.x + dx * dist, y: shrimp.position.y + dy * dist + 120 * u)
        let move = SKAction.move(to: target, duration: 0.9)
        move.timingMode = .easeOut
        let spin = SKAction.rotate(byAngle: (dx >= 0 ? -1 : 1) * 4 * .pi, duration: 0.9)
        shrimp.run(.sequence([
            .group([move, spin, .scale(to: 0.6, duration: 0.9), .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 0.4)])]),
            .wait(forDuration: 1.2),
            .run { [weak self] in
                guard let self else { return }
                self.flyers[i].knocked = false
                self.fly(shrimp, along: self.flyers[i].route, from: 0)
            },
        ]))

        burst(at: CGPoint(x: (shrimp.position.x + obstacle.position.x) / 2, y: (shrimp.position.y + obstacle.position.y) / 2))

        // the obstacle reels from the hit
        let jolt = SKAction.sequence([.rotate(byAngle: 0.35, duration: 0.06), .rotate(byAngle: -0.6, duration: 0.1), .rotate(toAngle: 0, duration: 0.12)])
        obstacle.run(jolt)
    }

    /// "ポーン！" with a ring of stars at the point of impact.
    private func burst(at p: CGPoint) {
        for k in 0..<8 {
            let star = SKSpriteNode(asset: "star", width: 14 * u)
            star.position = p
            star.zPosition = 4
            addChild(star)
            let a = CGFloat(k) / 8 * 2 * .pi
            let out = SKAction.moveBy(x: cos(a) * 46 * u, y: sin(a) * 46 * u, duration: 0.4)
            out.timingMode = .easeOut
            star.run(.sequence([.group([out, .rotate(byAngle: .pi, duration: 0.4), .sequence([.wait(forDuration: 0.2), .fadeOut(withDuration: 0.2)])]),
                                .removeFromParent()]))
        }
        let node = SKNode()
        node.position = CGPoint(x: min(max(p.x, 60 * u), size.width - 60 * u), y: p.y + 18 * u)
        node.zPosition = 5
        for (dx, dy) in [(-2, 0), (2, 0), (0, -2), (0, 2), (-1.5, -1.5), (1.5, 1.5), (-1.5, 1.5), (1.5, -1.5)] as [(CGFloat, CGFloat)] {
            let o = SKLabelNode(text: "ポーン！")
            o.fontName = AppFont.displayName
            o.fontSize = 22 * u
            o.fontColor = UIColor(hex: 0x3A2418)
            o.position = CGPoint(x: dx * u, y: dy * u)
            o.zPosition = 0
            node.addChild(o)
        }
        let label = SKLabelNode(text: "ポーン！")
        label.fontName = AppFont.displayName
        label.fontSize = 22 * u
        label.fontColor = .white
        label.zPosition = 1
        node.addChild(label)
        node.setScale(0.4)
        addChild(node)
        node.run(.sequence([
            .scale(to: 1.1, duration: 0.12), .scale(to: 1, duration: 0.08),
            .group([.moveBy(x: 0, y: 24 * u, duration: 0.5), .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.2)])]),
            .removeFromParent(),
        ]))
    }
}

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
                    Text("とばせ！")
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
                }
                .foregroundStyle(Palette.ink)
                .padding(.top, 14 * s)
                .padding(.bottom, 24 * s)
            }
        }
    }
}

/// Sky with drifting clouds and several fried shrimp flying across.
final class TitleScene: GameScene, ObservableObject {
    /// x0, y0, x1, y1 (design px, y from top), duration, phase, width, body count, tail
    private let flock: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Double, CGFloat, Int, TailKind)] = [
        (-90, 600, 380, 20, 5.5, 1.2, 54, 4, .normal),
        (400, 640, -90, 140, 7, 3.6, 42, 3, .heart),
        (-80, 420, 380, -180, 6.2, 5, 36, 3, .normal),
        (380, 470, -110, -200, 8, 2.2, 48, 5, .crown),
        (60, 700, 300, -220, 9, 7.5, 30, 3, .normal),
    ]

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

        let sy = h / 640
        for (x0, y0, x1, y1, dur, phase, width, n, tail) in flock {
            let unit = width * u / ShrimpGeometry.width
            let shrimp = ShrimpNode(tail: tail, count: n, skin: SegmentSkin.fry(0.5), unit: unit)
            let p0 = CGPoint(x: x0 * u + width * u / 2, y: h - y0 * sy)
            let p1 = CGPoint(x: x1 * u + width * u / 2, y: h - y1 * sy)
            let dx = p1.x - p0.x, dy = p1.y - p0.y
            // the head (local -y) faces the flight direction
            shrimp.zRotation = atan2(dx, -dy)
            let frac = CGFloat((phase.truncatingRemainder(dividingBy: dur)) / dur)
            shrimp.position = CGPoint(x: p0.x + dx * frac, y: p0.y + dy * frac)
            shrimp.zPosition = 1
            shrimp.startWiggle()
            addChild(shrimp)
            let first = SKAction.move(to: p1, duration: dur * Double(1 - frac))
            let loop = SKAction.sequence([.move(to: p0, duration: 0), .move(to: p1, duration: dur)])
            shrimp.run(.sequence([first, .repeatForever(loop)]))
            shrimp.run(.repeatForever(.sequence([
                .run { [weak self, weak shrimp] in
                    guard let self, let shrimp else { return }
                    self.emitDrop(from: shrimp)
                },
                .wait(forDuration: 0.16),
            ])))
        }
    }

    private func emitDrop(from shrimp: ShrimpNode) {
        let drop = SKSpriteNode(asset: "oil-drop", width: 9 * u)
        drop.position = shrimp.convert(CGPoint(x: CGFloat.random(in: -20...20) * shrimp.unit, y: shrimp.tailTip.y), to: self)
        drop.zPosition = 0.5
        drop.zRotation = shrimp.zRotation + .pi
        addChild(drop)
        drop.run(.sequence([.group([.fadeOut(withDuration: 0.6), .scale(to: 0.4, duration: 0.6)]), .removeFromParent()]))
    }
}

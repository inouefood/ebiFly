import SpriteKit
import SwiftUI
import UIKit

/// Geometry of the shrimp, in the same units as the SVG design (a body ball is 100 units at full size).
/// The tail sits on top; balls stack downward and get slightly bigger toward the head end.
enum ShrimpGeometry {
    static let spacing: CGFloat = 56
    static let tailSize: CGFloat = 106
    static let tailCenter: CGFloat = 55          // above ball 0's center
    static let width: CGFloat = 132

    static func scale(_ i: Int, of n: Int) -> CGFloat {
        0.82 + 0.26 * (n > 1 ? CGFloat(i) / CGFloat(n - 1) : 1)
    }

    /// Distance from ball 0's center down to the head end.
    static func bottomExtent(_ n: Int) -> CGFloat { CGFloat(n - 1) * spacing + 54 }
    /// Distance from ball 0's center up to the tail tip.
    static let topExtent: CGFloat = 108
    static func length(_ n: Int) -> CGFloat { topExtent + bottomExtent(n) }
}

// MARK: - SwiftUI

struct ShrimpView: View {
    let tail: TailKind
    let count: Int
    let skin: String
    /// Points per design unit.
    let unit: CGFloat
    /// Batter coat overlay drawn on each ball (CoatKind.overlayName).
    var coat: String? = nil

    var body: some View {
        let g = ShrimpGeometry.self
        let top = g.topExtent
        ZStack {
            Image(tail.imageName).resizable()
                .frame(width: g.tailSize * unit, height: g.tailSize * unit)
                .position(x: g.width / 2 * unit, y: (top - g.tailCenter) * unit)
            ForEach(0..<count, id: \.self) { i in
                let d = 100 * g.scale(i, of: count) * unit
                ZStack {
                    Image(skin).resizable()
                    if let coat { Image(coat).resizable() }
                }
                .frame(width: d, height: d)
                .position(x: g.width / 2 * unit, y: (top + CGFloat(i) * g.spacing) * unit)
            }
        }
        .frame(width: g.width * unit, height: g.length(count) * unit)
    }
}

// MARK: - SpriteKit

final class ShrimpNode: SKNode {
    let count: Int
    let unit: CGFloat
    private let tailSprite: SKSpriteNode
    private var segments: [SKSpriteNode] = []
    private var coats: [SKSpriteNode] = []
    private var skin: String

    private static var textures: [String: SKTexture] = [:]
    static func texture(_ name: String) -> SKTexture {
        if let t = textures[name] { return t }
        let t = SKTexture(imageNamed: name)
        textures[name] = t
        return t
    }

    /// Origin is the center of the first body ball (just under the tail). The tail points to +y.
    init(tail: TailKind, count: Int, skin: String, unit: CGFloat, coat: String? = nil) {
        self.count = count
        self.unit = unit
        self.skin = skin
        tailSprite = SKSpriteNode(texture: Self.texture(tail.imageName))
        tailSprite.size = CGSize(width: ShrimpGeometry.tailSize * unit, height: ShrimpGeometry.tailSize * unit)
        tailSprite.position = CGPoint(x: 0, y: ShrimpGeometry.tailCenter * unit)
        super.init()
        addChild(tailSprite)
        for i in 0..<count {
            let d = 100 * ShrimpGeometry.scale(i, of: count) * unit
            let seg = SKSpriteNode(texture: Self.texture(skin))
            seg.size = CGSize(width: d, height: d)
            seg.position = CGPoint(x: 0, y: -CGFloat(i) * ShrimpGeometry.spacing * unit)
            seg.zPosition = CGFloat(i + 1) * 0.01
            addChild(seg)
            segments.append(seg)
            if let coat {
                // child of the ball so it sways with it
                let c = SKSpriteNode(texture: Self.texture(coat))
                c.size = seg.size
                c.zPosition = 0.001
                seg.addChild(c)
                coats.append(c)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var topExtent: CGFloat { ShrimpGeometry.topExtent * unit }
    var bottomExtent: CGFloat { ShrimpGeometry.bottomExtent(count) * unit }
    var length: CGFloat { ShrimpGeometry.length(count) * unit }
    /// Signed offset along the body axis from the origin to the middle of the whole shrimp.
    var centerOffset: CGFloat { (topExtent - bottomExtent) / 2 }
    /// Tail tip in this node's coordinates.
    var tailTip: CGPoint { CGPoint(x: 0, y: topExtent * 0.8) }

    func setSkin(_ name: String) {
        guard name != skin else { return }
        skin = name
        let t = Self.texture(name)
        segments.forEach { $0.texture = t }
    }

    /// 0...1: how much of the coat shows (it builds up while the batter goes on).
    func setCoatAlpha(_ a: CGFloat) {
        coats.forEach { $0.alpha = a }
    }

    /// Small sway on each ball so the shrimp looks alive.
    func startWiggle() {
        for (i, seg) in segments.enumerated() {
            let a = SKAction.rotate(toAngle: 0.06, duration: 0.7)
            let b = SKAction.rotate(toAngle: -0.06, duration: 0.7)
            a.timingMode = .easeInEaseOut
            b.timingMode = .easeInEaseOut
            seg.run(.sequence([.wait(forDuration: Double(i) * 0.15), .repeatForever(.sequence([a, b]))]))
        }
    }
}

// MARK: - Scene base

/// Lays out once the SKView has a real size, then switches to aspect-fill so later size changes
/// (iPad rotation keeps the column's aspect ratio) only scale the scene.
class GameScene: SKScene {
    private(set) var isLaidOut = false
    /// Scale relative to the 300pt-wide design.
    var u: CGFloat { size.width / 300 }

    override init(size: CGSize = CGSize(width: 300, height: 640)) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if view.bounds.width > 10 { size = view.bounds.size }
        layoutIfReady()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutIfReady()
    }

    private func layoutIfReady() {
        guard !isLaidOut, view != nil, size.width > 10, size.height > 10 else { return }
        isLaidOut = true
        layout()
        scaleMode = .aspectFill
    }

    /// Build the scene for the current `size`. Called exactly once.
    func layout() {}
}

enum Tex {
    static func image(_ size: CGSize, draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext) }
    }

    /// Vertical gradient, `top` at the top of the image.
    static func gradient(_ size: CGSize, top: UIColor, bottom: UIColor, split: CGFloat? = nil) -> SKTexture {
        SKTexture(image: image(size) { ctx in
            if let split {
                // hard split: top gradient region then flat bottom region
                let colors = [top.cgColor, top.mixed(with: .white, 0.5).cgColor] as CFArray
                let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
                ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height * split), options: [])
                ctx.setFillColor(bottom.cgColor)
                ctx.fill(CGRect(x: 0, y: size.height * split, width: size.width, height: size.height * (1 - split)))
            } else {
                let colors = [top.cgColor, bottom.cgColor] as CFArray
                let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
                ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
        })
    }

    /// Flat color with a dot grid (panko bowl).
    static func dots(_ size: CGSize, bg: UIColor, dot: UIColor, spacing: CGFloat, radius: CGFloat) -> SKTexture {
        SKTexture(image: image(size) { ctx in
            ctx.setFillColor(bg.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.setFillColor(dot.cgColor)
            var y: CGFloat = spacing / 2
            while y < size.height {
                var x: CGFloat = spacing / 2
                while x < size.width {
                    ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    x += spacing
                }
                y += spacing
            }
        })
    }

    /// Flat color with a square tile grid (kitchen wall).
    static func tiles(_ size: CGSize, bg: UIColor, line: UIColor, spacing: CGFloat) -> SKTexture {
        SKTexture(image: image(size) { ctx in
            ctx.setFillColor(bg.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.setFillColor(line.cgColor)
            var p: CGFloat = 0
            while p < max(size.width, size.height) {
                ctx.fill(CGRect(x: p, y: 0, width: 2, height: size.height))
                ctx.fill(CGRect(x: 0, y: p, width: size.width, height: 2))
                p += spacing
            }
        })
    }
}

extension SKSpriteNode {
    /// Sprite from an asset with a given width, keeping the image's aspect ratio.
    convenience init(asset: String, width: CGFloat) {
        let t = ShrimpNode.texture(asset)
        let ts = t.size()
        self.init(texture: t, size: CGSize(width: width, height: width * ts.height / max(ts.width, 1)))
    }
}

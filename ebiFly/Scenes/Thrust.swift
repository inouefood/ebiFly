import SpriteKit
import UIKit

/// The jet blasting out of the shrimp's tail while it flies: a flickering flame plus a stream of
/// hot oil particles that cool to smoke. Attach to the shrimp at its tail tip; local +y points away from the head.
final class ThrustNode: SKNode {
    private let flame: SKSpriteNode
    private let core: SKSpriteNode
    private let jet: SKEmitterNode
    private let u: CGFloat
    private var power: CGFloat = 1
    private var intensity: CGFloat = 0

    /// `power` ~ climb speed relative to the average (1 = 460 m/s); more sauce, bigger jet.
    /// `colors`: hot and cooler particle colours for the jet (the sauce in use); nil = fire.
    init(unit u: CGFloat, power: CGFloat, target: SKNode, colors: (UIColor, UIColor)? = nil) {
        self.u = u
        self.power = power
        flame = SKSpriteNode(texture: Self.flameTexture)
        flame.size = CGSize(width: 46 * u, height: 92 * u)
        flame.anchorPoint = CGPoint(x: 0.5, y: 0.08)
        core = SKSpriteNode(texture: Self.coreTexture)
        core.size = CGSize(width: 24 * u, height: 48 * u)
        core.anchorPoint = CGPoint(x: 0.5, y: 0.06)
        core.zPosition = 0.1

        jet = SKEmitterNode()
        jet.particleTexture = Self.dotTexture
        jet.particleBirthRate = 0
        jet.particleLifetime = 0.5
        jet.particleLifetimeRange = 0.25
        jet.emissionAngle = -.pi / 2         // set from the shrimp's heading with `aim(_:)`
        jet.emissionAngleRange = 0.6
        jet.particleSpeed = 520 * u
        jet.particleSpeedRange = 180 * u
        jet.particlePositionRange = CGVector(dx: 22 * u, dy: 4 * u)
        jet.particleScale = 1.3 * u
        jet.particleScaleRange = 0.6 * u
        jet.particleScaleSpeed = -1.1 * u
        jet.particleAlpha = 1
        jet.particleAlphaSpeed = -1.7
        jet.particleRotationRange = .pi * 2
        jet.particleColorBlendFactor = 1
        let (hot, cool) = colors ?? (UIColor(hex: 0xFFC84A), UIColor(hex: 0xF07A2E))
        jet.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor(hex: 0xFFF6C8), hot, cool, UIColor(hex: 0xC9BFB4)],
            times: [0, 0.18, 0.45, 1])
        jet.yAcceleration = -500 * u          // the world rushes past, so the exhaust falls away quickly
        jet.targetNode = target
        jet.particleZPosition = 8

        super.init()
        jet.position = CGPoint(x: 0, y: 46 * u)   // out at the flame's tip, so the spray isn't hidden behind it
        addChild(jet)
        addChild(flame)
        flame.addChild(core)
        flame.run(.repeatForever(.sequence([
            .run { [weak self] in self?.flicker() },
            .wait(forDuration: 0.05),
        ])))
        setIntensity(0)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 0 = off, 1 = full thrust.
    func setIntensity(_ t: CGFloat) {
        intensity = max(0, min(1, t))
        jet.particleBirthRate = 240 * intensity * power
        jet.particleSpeed = (380 + 220 * power) * u * max(0.3, intensity)
        flame.alpha = intensity
    }

    /// The jet's particles live in the scene, so their direction is a scene angle:
    /// pass the shrimp's rotation and they shoot straight out of the tail.
    func aim(shrimpRotation: CGFloat) {
        jet.emissionAngle = shrimpRotation + .pi / 2
    }

    /// Big flare, e.g. on take-off or a refuel.
    func burst() {
        flame.run(.sequence([.scaleX(to: 1.5, y: 1.9, duration: 0.08), .scaleX(to: 1, y: 1, duration: 0.25)]), withKey: "burst")
        jet.particleBirthRate = 900 * power
        run(.sequence([.wait(forDuration: 0.15), .run { [weak self] in
            guard let self else { return }
            self.setIntensity(self.intensity)
        }]))
    }

    private func flicker() {
        guard flame.action(forKey: "burst") == nil else { return }
        let len = (0.85 + 0.45 * power) * CGFloat.random(in: 0.8...1.2)
        flame.yScale = len * max(0.2, intensity)
        flame.xScale = CGFloat.random(in: 0.9...1.08)
        core.alpha = CGFloat.random(in: 0.75...1)
    }

    // MARK: textures

    private static let dotTexture: SKTexture = SKTexture(image: Tex.image(CGSize(width: 24, height: 24)) { ctx in
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.85).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.45, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: 12, y: 12), startRadius: 0, endCenter: CGPoint(x: 12, y: 12), endRadius: 12, options: [])
    })

    /// Teardrop flame, wide end at the bottom of the image (where it leaves the tail), point at the top.
    private static func flamePath(_ w: CGFloat, _ h: CGFloat, inset: CGFloat) -> UIBezierPath {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: w / 2, y: inset))
        p.addCurve(to: CGPoint(x: w - inset, y: h * 0.72), controlPoint1: CGPoint(x: w * 0.62, y: h * 0.3), controlPoint2: CGPoint(x: w - inset, y: h * 0.5))
        p.addArc(withCenter: CGPoint(x: w / 2, y: h * 0.72), radius: w / 2 - inset, startAngle: 0, endAngle: .pi, clockwise: true)
        p.addCurve(to: CGPoint(x: w / 2, y: inset), controlPoint1: CGPoint(x: inset, y: h * 0.5), controlPoint2: CGPoint(x: w * 0.38, y: h * 0.3))
        p.close()
        return p
    }

    // SpriteKit shows the image upright (its top at +y), so the point ends up away from the tail
    private static let flameTexture: SKTexture = SKTexture(image: Tex.image(CGSize(width: 92, height: 184)) { ctx in
        let outer = flamePath(92, 184, inset: 4)
        UIColor(hex: 0xF07A2E).setFill()
        outer.fill()
        UIColor(hex: 0x3A2418).setStroke()
        outer.lineWidth = 5
        outer.stroke()
        let mid = flamePath(92, 184, inset: 18)
        UIColor(hex: 0xFFC84A).setFill()
        mid.fill()
    })

    private static let coreTexture: SKTexture = SKTexture(image: Tex.image(CGSize(width: 48, height: 96)) { _ in
        UIColor(hex: 0xFFF6C8).setFill()
        flamePath(48, 96, inset: 4).fill()
    })
}

//
//  Constant.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/14.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation
import SpriteKit

struct Constant {
    struct SpriteNum {
        static let abura = 300
    }
    struct EbiAnimation {
        static let left: SKAction = SKAction.animate(
            with: [SKTexture(imageNamed: "ebiAnimation05"),SKTexture(imageNamed: "ebiAnimation06"),SKTexture(imageNamed: "ebiAnimation05"), SKTexture(imageNamed: "ebiAnimation04")],
            timePerFrame: 0.2)
        static let right: SKAction = SKAction.animate(
            with: [SKTexture(imageNamed: "ebiAnimation02"),SKTexture(imageNamed: "ebiAnimation03"),SKTexture(imageNamed: "ebiAnimation02"), SKTexture(imageNamed: "ebiAnimation01")],
            timePerFrame: 0.2)
    }
}

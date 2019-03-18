//
//  EbiModel.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/18.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation
import SpriteKit

struct EbiModel {
    let tale: SKSpriteNode
    var taleImageCount: Int
    var body: [SKSpriteNode] = []
    var bodyCount: Int
    init(tale:SKSpriteNode, body: [SKSpriteNode], taleImageCount: Int = 1, bodyCount: Int = 3) {
        self.tale = tale
        self.body = body
        self.taleImageCount = taleImageCount
        self.bodyCount = bodyCount
    }
    mutating func setTaleTexture() -> String{
        
        if taleImageCount == 4 {
            self.taleImageCount = 1
        }
        if taleImageCount == 0 {
            self.taleImageCount = 3
        }
        
        if taleImageCount == 1 {
            tale.texture = SKTexture(imageNamed: "tale1")
            return "tale1"
        } else if taleImageCount == 2 {
            tale.texture = SKTexture(imageNamed: "tale2")
            return "tale2"
        } else if taleImageCount == 3 {
            tale.texture = SKTexture(imageNamed: "tale3")
            return "tale3"
        } else {
            return "tale1"
        }
    }
}

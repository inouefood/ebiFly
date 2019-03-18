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
    let body: [SKSpriteNode]
    init(tale:SKSpriteNode, body: [SKSpriteNode]) {
        self.tale = tale
        self.body = body
    }
}

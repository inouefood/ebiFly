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
    var tale: SKSpriteNode
    var body: [SKSpriteNode]
    var bodyCount: Int = 3
    
    init(tale:SKSpriteNode, body: [SKSpriteNode]) {
        self.tale = tale
        self.body = body
    }
    
    func setTaleTexture(selectNum: Int){
        if selectNum == 1 {
            self.tale.texture = SKTexture(imageNamed: "tale1")
        } else if selectNum == 2 {
            self.tale.texture = SKTexture(imageNamed: "tale2")
        } else if selectNum == 3 {
            self.tale.texture = SKTexture(imageNamed: "tale3")
        }
    }
}

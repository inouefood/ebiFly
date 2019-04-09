//
//  SKSpriteNode+Addition.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/08.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit

extension SKSpriteNode {
    convenience init(image: String, pos: CGPoint, size: CGSize){
        self.init(imageNamed: image)
        self.position = pos
        self.size = size
    }
}

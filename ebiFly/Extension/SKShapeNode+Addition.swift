//
//  SKShapeNode+Addition.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/27.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit


extension SKShapeNode {
    convenience init(rect: CGRect, color: UIColor) {
        self.init(rect: rect)
        self.fillColor = color
    }
}

//
//  SKLabel+Addition.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/08.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation
import SpriteKit

extension SKLabelNode {
    convenience init(font:String = "Verdana-bold", fontSize: CGFloat, text: String, pos: CGPoint){
        self.init()
        self.fontName = font
        self.fontSize = fontSize
        self.text = text
        self.position = pos
    }
}

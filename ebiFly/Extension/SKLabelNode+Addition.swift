//
//  SKLabel+Addition.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/08.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit

extension SKLabelNode {
    convenience init(font:String = "Verdana-bold", fontSize: CGFloat, text: String, pos: CGPoint){
        self.init()
        self.fontName = font
        self.fontSize = fontSize
        self.text = text
        self.position = pos
    }
    convenience init(font:String = "Verdana-bold", fontSize: CGFloat, text: String, pos: CGPoint, zPos:CGFloat){
        self.init()
        self.fontName = font
        self.fontSize = fontSize
        self.text = text
        self.position = pos
        self.zPosition = zPos
    }
}

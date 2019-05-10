//
//  FlyModel.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/10.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation
import UIKit

protocol  FlyModel {
    func aburaToEbiCollision(ebiPos:ObjectPosition, aburaPos: ObjectPosition) -> (collision:Bool,pos: ObjectPosition)
}
class FlyModelImpl:FlyModel {
    func aburaToEbiCollision(ebiPos:ObjectPosition, aburaPos: ObjectPosition) -> (collision:Bool,pos: ObjectPosition) {
        let dx = ebiPos.x - aburaPos.x
        let dy = ebiPos.y - aburaPos.y
        let dist = sqrtf(dx * dx + dy * dy)
        let pos = ObjectPosition(x: CGFloat(dx), y: CGFloat(dy))
        return dist < 50.0 ? (collision:true, pos:pos) : (collision:false, pos: pos)
    }
    
    
}

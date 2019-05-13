//
//  FlyScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/13.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit

class FlyScene: SKScene {
    
    lazy var fallSprite: [SKSpriteNode]! = {
        return [
            SKSpriteNode(image: "fallBack", pos: CGPoint(x: width/2, y: height/8), size: CGSize(width: width/4, height: width/2), zPos: 0.1),
            SKSpriteNode(image: "fallFront", pos: CGPoint(x: width/2, y: height/8), size: CGSize(width: width/4, height: width/2), zPos: 2.0)
        ]
    }()
    let distance: Int
    var body: [SKSpriteNode]
    var tale: SKSpriteNode
    
    // MARK: - Initializer
    
    init(size: CGSize, flyingDistance: Int, body: [SKSpriteNode], tale: SKSpriteNode) {
        self.distance = flyingDistance
        self.body = body
        self.tale = tale
        super.init(size: size)
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.backgroundColor = UIColor(appColor: .white)
        self.addChild(fallSprite)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
}

//
//  GameScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/15.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

class TitleScene: SKScene {
    lazy var startLabel = SKLabelNode(fontSize: 70, text: "START", pos: CGPoint(x: width/2, y: height/7))
    lazy var ebiSprite =  SKSpriteNode(image: "ebiAnimation01", pos: CGPoint(x: width/2, y: height/7), size: CGSize(width: width/3, height: width/9))
    lazy var ebiSprite2 = SKSpriteNode(image: "ebiAnimation04", pos: CGPoint(x: width/2, y: height/1.5), size: CGSize(width: width/2, height: width/5))
    lazy var ebiSprite3 = SKSpriteNode(image: "ebiAnimation04", pos: CGPoint(x: width/6, y: height/8), size: CGSize(width: width/3, height: width/9))
    var width: CGFloat!
    var height: CGFloat!
    
    // MARK: LifeCycle
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = UIColor(appColor: .thema)
        
        
        width = self.view!.frame.width
        height =  self.view!.frame.height
        
        self.addChild(startLabel)
        self.addChild(ebiSprite)
        self.addChild(ebiSprite2)
        self.addChild(ebiSprite3)

        ebiAnimation()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if ebiSprite.position.x > width + 100 {
            ebiSprite.position.x = 0
            ebiSprite.position.y = CGFloat(Int.random(in: 100...Int(height-100)))
        }
        if ebiSprite2.position.x < -100 {
            ebiSprite2.position.y = CGFloat(Int.random(in: 100...Int(height-100)))
            ebiSprite2.position.x = width
        }
        if ebiSprite3.position.x < -100 {
            ebiSprite3.position.y = CGFloat(Int.random(in: 100...Int(height-100)))
            ebiSprite3.position.x = width
        }
    }
    
    // MARK: - PrivateMethod
    
    private func ebiAnimation() {
        ebiSprite.run(SKAction.repeatForever(Constant.EbiAnimation.right))
        let moveAction = SKAction.moveBy(x: 80.0, y: 0, duration: 1.0)
        ebiSprite.run(SKAction.repeatForever(moveAction))
        
        ebiSprite2.run(SKAction.repeatForever(Constant.EbiAnimation.left))
        let moveAction2 = SKAction.moveBy(x: -40.0, y: 0, duration: 1.0)
        ebiSprite2.run(SKAction.repeatForever(moveAction2))
        
        ebiSprite3.run(SKAction.repeatForever(Constant.EbiAnimation.left))
        let moveAction3 = SKAction.moveBy(x: -200.0, y: 0, duration: 1.0)
        ebiSprite3.run(SKAction.repeatForever(moveAction3))
    }
    
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            if touchNode == startLabel {
                let scene = CharactorMakeScene(size: self.scene!.size)
                scene.scaleMode = SKSceneScaleMode.aspectFill
                self.view!.presentScene(scene)
            }
        }
    }
}

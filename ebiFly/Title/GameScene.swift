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

class GameScene: SKScene {
    let startLabel = SKLabelNode(fontNamed: "Verdana-bold")
    let ebiSprite = SKSpriteNode(imageNamed: "ebiAnimation01")
    let ebiSprite2 = SKSpriteNode(imageNamed: "ebiAnimation04")
    let ebiSprite3 = SKSpriteNode(imageNamed: "ebiAnimation04")
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 36/255, green: 139/255, blue: 255/255, alpha: 1)
        startLabel.text = "START"
        startLabel.fontSize = 150
        startLabel.position = CGPoint(x:0, y:-250)
        self.addChild(startLabel)
        
        ebiSprite.position  = CGPoint(x: 0, y: 0)
        ebiSprite.size = CGSize(width: 300, height: 100)
        self.addChild(ebiSprite)
        let playerAnime = SKAction.animate(
            with: [SKTexture(imageNamed: "ebiAnimation02"),SKTexture(imageNamed: "ebiAnimation03"),SKTexture(imageNamed: "ebiAnimation02"), SKTexture(imageNamed: "ebiAnimation01"),SKTexture(imageNamed: "ebiAnimation02"), SKTexture(imageNamed: "ebiAnimation03")],
            timePerFrame: 0.2)
        ebiSprite.run(SKAction.repeatForever(playerAnime))
        let moveAction = SKAction.moveBy(x: 80.0, y: 0, duration: 1.0)
        ebiSprite.run(SKAction.repeatForever(moveAction))
        
        
        ebiSprite2.position  = CGPoint(x: self.view!.frame.width/2, y: self.view!.frame.height/2)
        ebiSprite2.size = CGSize(width: 200, height: 70)
        self.addChild(ebiSprite2)
        let playerAnime2 = SKAction.animate(
            with: [SKTexture(imageNamed: "ebiAnimation05"),SKTexture(imageNamed: "ebiAnimation06"),SKTexture(imageNamed: "ebiAnimation05"), SKTexture(imageNamed: "ebiAnimation04"),SKTexture(imageNamed: "ebiAnimation05"), SKTexture(imageNamed: "ebiAnimation06")],
            timePerFrame: 0.2)
        ebiSprite2.run(SKAction.repeatForever(playerAnime2))
        let moveAction2 = SKAction.moveBy(x: -40.0, y: 0, duration: 1.0)
        ebiSprite2.run(SKAction.repeatForever(moveAction2))

        ebiSprite3.position  = CGPoint(x: self.view!.frame.width/6, y: self.view!.frame.height/8)
        ebiSprite3.size = CGSize(width: 120, height: 30)
        self.addChild(ebiSprite3)
        let playerAnime3 = SKAction.animate(
            with: [SKTexture(imageNamed: "ebiAnimation05"),SKTexture(imageNamed: "ebiAnimation06"),SKTexture(imageNamed: "ebiAnimation05"), SKTexture(imageNamed: "ebiAnimation04"),SKTexture(imageNamed: "ebiAnimation05"), SKTexture(imageNamed: "ebiAnimation06")],
            timePerFrame: 0.2)
        ebiSprite3.run(SKAction.repeatForever(playerAnime3))
        let moveAction3 = SKAction.moveBy(x: -200.0, y: 0, duration: 1.0)
        ebiSprite3.run(SKAction.repeatForever(moveAction3))
    }
    override func update(_ currentTime: TimeInterval) {
        if ebiSprite.position.x > (self.view?.frame.width)! + 100 {
            ebiSprite.position.x = -self.view!.frame.width
        }
        if ebiSprite2.position.x < -self.view!.frame.width - 100 {
            ebiSprite2.position.y = CGFloat(Int.random(in: 0...Int( self.view!.frame.height))) - 200
            ebiSprite2.position.x = self.view!.frame.width
        }
        if ebiSprite3.position.x < -self.view!.frame.width - 100 {
            ebiSprite3.position.y = CGFloat(Int.random(in: 0...Int( self.view!.frame.height))) - 200
            ebiSprite3.position.x = self.view!.frame.width
        }
    }
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

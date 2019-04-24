//
//  CharactorMake.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/15.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class CharactorMakeScene: SKScene {
    //胴体
    var tale: SKSpriteNode?
    var ebiBodySprites:[SKSpriteNode] = []
    var aburaSprites:[SKSpriteNode] = []
    var bodyCount: Int = 3
    var taleCollectionCount = 1

    
    //ボタン
    let tailLeft = SKSpriteNode(imageNamed: "left")
    let tailRight = SKSpriteNode(imageNamed: "right")
    let bodyLeft = SKSpriteNode(imageNamed: "left")
    let bodyRight = SKSpriteNode(imageNamed: "right")
    let flyLabel = SKLabelNode(fontNamed: "Verdana-bold")
    
    var width: CGFloat!
    var height: CGFloat!
    var taleY: CGFloat!
    
    var texture = "tale1"
    
    // MARK: - Initializer
    
    override func didMove(to view: SKView) {
        width  = self.view!.frame.width
        height = self.view!.frame.height
        taleY = height - height/6

        addTail(taleImgStr: "tale1")
        addBody(count: bodyCount)
    }
    
    // MARK: - PrivateMethod
    
    private func addBody(count: Int){
        
        
        let taleX = width/2
        
        for i in 0..<count {
            let ebiBody = SKSpriteNode(imageNamed: "ebibody")
            let ebX = taleX
            let rootY = taleY - width/4
            let ebY = rootY - (width/4 * CGFloat(i))
            ebiBody.size = CGSize(width: width/4 , height: width/4)
            ebiBody.position = CGPoint(x: ebX, y: ebY)
            ebiBody.physicsBody = SKPhysicsBody(circleOfRadius: 20)
            ebiBody.physicsBody!.affectedByGravity = false
            ebiBody.name = "ebiBody" + String(i)
            self.addChild(ebiBody)
            ebiBodySprites.append(ebiBody)
        }
    }
    private func addTail(taleImgStr: String){
        tale = SKSpriteNode(imageNamed: taleImgStr)
        setSelectButton(width: width, height: height)
    
        tale!.position = CGPoint(x: width/2, y: taleY)
        tale!.size = CGSize(width: width/4, height: width/4)
        tale!.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        tale!.physicsBody!.affectedByGravity = false
        tale!.physicsBody!.isDynamic = false
        self.addChild(tale!)
    }
    private func setSelectButton(width: CGFloat, height: CGFloat){
        let buttonSize = CGSize(width: width/6, height: width/6)
        tailLeft.size = buttonSize
        tailLeft.position = CGPoint(x: width/6, y: height - height/6)
        
        tailRight.position = CGPoint(x: width - width/6, y: height - height/6)
        tailRight.size = buttonSize
        
        
        bodyLeft.position = CGPoint(x: width/6 , y: height/3)
        bodyLeft.size = buttonSize
        bodyRight.position = CGPoint(x: width - width/6, y: height/3)
        bodyRight.size = buttonSize
        
        self.addChild(bodyLeft)
        self.addChild(tailRight)
        self.addChild(tailLeft)
        self.addChild(bodyRight)
        
        flyLabel.text = "揚げる!!"
        flyLabel.fontSize = 70
        flyLabel.position = CGPoint(x:width/2, y:height/10)
        self.addChild(flyLabel)
    }
    
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            if touchNode == tailLeft {
                
                taleCollectionCount += 1
                 print(taleCollectionCount)
                if taleCollectionCount == 4 {
                    taleCollectionCount = 1
                }
                if taleCollectionCount == 1 {
                    tale?.texture = SKTexture(imageNamed: "tale1")
                    texture = "tale1"
                } else if taleCollectionCount == 2 {
                    tale?.texture = SKTexture(imageNamed: "tale2")
                     texture = "tale2"
                } else if taleCollectionCount == 3 {
                    tale?.texture = SKTexture(imageNamed: "tale3")
                     texture = "tale3"
                }
                
            }
            if touchNode == tailRight {
                taleCollectionCount -= 1
                 print(taleCollectionCount)
                if taleCollectionCount == 0 {
                    taleCollectionCount = 3
                }
                if taleCollectionCount == 1 {
                    tale?.texture = SKTexture(imageNamed: "tale1")
                     texture = "tale1"
                } else if taleCollectionCount == 2 {
                    tale?.texture = SKTexture(imageNamed: "tale2")
                     texture = "tale2"
                } else if taleCollectionCount == 3 {
                    tale?.texture = SKTexture(imageNamed: "tale3")
                     texture = "tale3"
                }
            }
            if touchNode == bodyLeft {
                if bodyCount <= 1 {
                    return
                }
                self.removeChildren(in: ebiBodySprites)
                bodyCount -= 1
                addBody(count: bodyCount)
            }
            if touchNode == bodyRight {
                if bodyCount >= 5 {
                    return
                }
                self.removeChildren(in: ebiBodySprites)
                bodyCount += 1
                addBody(count: bodyCount)
            }
            if touchNode == flyLabel {
                let scene = FryScene(size: self.scene!.size, bodyCount: bodyCount, taleImageStr: texture)
                scene.scaleMode = SKSceneScaleMode.aspectFill
                self.view!.presentScene(scene)
            }
        }
    }
}


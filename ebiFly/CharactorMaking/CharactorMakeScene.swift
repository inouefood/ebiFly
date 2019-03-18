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
   // var ebiBodySprites:[SKSpriteNode] = []
    var aburaSprites:[SKSpriteNode] = []
    var bodyCount: Int = 3
    var taleCollectionCount = 1

    var ebi: EbiModel?
    
    //ボタン
    let tailLeft = SKSpriteNode(imageNamed: "left")
    let tailRight = SKSpriteNode(imageNamed: "right")
    let bodyLeft = SKSpriteNode(imageNamed: "left")
    let bodyRight = SKSpriteNode(imageNamed: "right")
    let flyLabel = SKLabelNode(fontNamed: "Verdana-bold")


    var texture = "tale1"
    
    
    override init(size: CGSize) {
        ebi = EbiModel(tale: SKSpriteNode(imageNamed: "tale1"), body: [SKSpriteNode(imageNamed: "ebibody")])
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        addCharactor()
    }
    func addCharactor(){
        guard let width: CGFloat = self.view!.frame.width, let height: CGFloat = self.view!.frame.height else {
            return
        }
        
        let taleX = width
        let taleY = height * 1.3
        
        
        ebi = EbiModel(tale: SKSpriteNode(imageNamed: "tale1"), body: addBody(count: 3))
        setSelectButton(width: width, height: height)
        

        ebi!.tale.position = CGPoint(x: taleX, y: taleY)
        ebi!.tale.size = CGSize(width: width/4, height: width/4)
        ebi!.tale.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ebi!.tale.physicsBody!.affectedByGravity = false
        ebi!.tale.physicsBody!.isDynamic = false
        self.addChild(ebi!.tale)
    }
    
    func addBody(count: Int) -> [SKSpriteNode]{
        guard let width: CGFloat = self.view!.frame.width, let height: CGFloat = self.view!.frame.height else {
            return [SKSpriteNode()]
        }
        
        var ebiBodySprites:[SKSpriteNode] = []
        let taleX = width
        let taleY = height * 1.3
        
        for i in 0..<count {
            let ebiBody = SKSpriteNode(imageNamed: "ebibody")
            let ebX = taleX
            let ebY = (taleY - width/4)  - (width/4 * CGFloat(i))
            ebiBody.size = CGSize(width: width/4 , height: width/4)
            ebiBody.position = CGPoint(x: ebX, y: ebY)
            ebiBody.physicsBody = SKPhysicsBody(circleOfRadius: 20)
            ebiBody.physicsBody!.affectedByGravity = false
            ebiBody.name = "ebiBody" + String(i)
            self.addChild(ebiBody)
            ebiBodySprites.append(ebiBody)
        }
        return ebiBodySprites
    }

    func setSelectButton(width: CGFloat, height: CGFloat){
        tailLeft.position = CGPoint(x: width/6 * 2, y: height * 1.3)
        tailLeft.size = CGSize(width: width/3, height: width/3)
        
        tailRight.position = CGPoint(x: width * 2 - width/6 * 2, y: height * 1.3)
        tailRight.size = CGSize(width: width/3, height: width/3)
        
        bodyLeft.position = CGPoint(x: width/6 * 2, y: height - height / 4 * 2)
        bodyLeft.size = CGSize(width: (self.view?.frame.width)!/3, height: (self.view?.frame.width)!/3)
        bodyRight.position = CGPoint(x: width * 2 - width/6 * 2, y: height - height / 4 * 2)
        bodyRight.size = CGSize(width: (self.view?.frame.width)!/3, height: (self.view?.frame.width)!/3)
        
        self.addChild(bodyLeft)
        self.addChild(tailRight)
        self.addChild(tailLeft)
        self.addChild(bodyRight)
        
        flyLabel.text = "揚げる!!"
        flyLabel.fontSize = 130
        flyLabel.position = CGPoint(x:width, y:height/10)
        self.addChild(flyLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            //tale textureの変更
            if touchNode == tailLeft {
                ebi?.taleImageCount += 1
                texture = ebi!.setTaleTexture()
            }
            if touchNode == tailRight {
                ebi?.taleImageCount -= 1
                texture = ebi!.setTaleTexture()
            }
            //body countの変更
            if touchNode == bodyLeft {
                if ebi!.bodyCount <= 2 {
                    return
                }
                self.removeChildren(in: ebi!.body)
                ebi!.bodyCount -= 1
                ebi!.body = addBody(count: ebi!.bodyCount)
            }
            if touchNode == bodyRight {
                if ebi!.bodyCount >= 5 {
                    return
                }
                self.removeChildren(in: ebi!.body)
                ebi!.bodyCount += 1
                ebi!.body = addBody(count: ebi!.bodyCount)
            }
            if touchNode == flyLabel {
                let scene = FryScene(size: self.scene!.size, bodyCount: ebi!.bodyCount, taleImageStr: texture)
                scene.scaleMode = SKSceneScaleMode.aspectFill
                self.view!.presentScene(scene)
            }
        }
    }
}


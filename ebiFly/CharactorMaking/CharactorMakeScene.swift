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
    var taleCollectionCount = 1
    var ebiModel: EbiModel

    //ボタン
    lazy var tailLeft = SKSpriteNode(image: "left", pos: CGPoint(x: width/6, y: height - height/6), size: CGSize(width: width/6, height: width/6))
    lazy var tailRight = SKSpriteNode(image: "right", pos: CGPoint(x: width - width/6, y: height - height/6), size: CGSize(width: width/6, height: width/6))
    lazy var bodyLeft = SKSpriteNode(image: "left", pos: CGPoint(x: width/6 , y: height/3), size: CGSize(width: width/6, height: width/6))
    lazy var bodyRight = SKSpriteNode(image: "right", pos: CGPoint(x: width - width/6, y: height/3), size: CGSize(width: width/6, height: width/6))
    lazy var flyLabel = SKLabelNode(fontSize: 70, text: "揚げる!!", pos: CGPoint(x:width/2, y:height/10))

    var taleY: CGFloat!
    
    // MARK: - Initializer
    override init(size: CGSize) {
        ebiModel = EbiModel(tale: SKSpriteNode(imageNamed: "tale1"), body: [SKSpriteNode(imageNamed: "ebibody")])
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    override func didMove(to view: SKView) {
        taleY = height - height/6

        addTail(taleImgStr: "tale1")
        addBody(count: ebiModel.bodyCount)
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
            ebiModel.body.append(ebiBody)
        }
    }
    private func addTail(taleImgStr: String){
        self.addChild(bodyLeft, tailRight, tailLeft, bodyRight, flyLabel)
    
        ebiModel.tale.position = CGPoint(x: width/2, y: taleY)
        ebiModel.tale.size = CGSize(width: width/4, height: width/4)
        ebiModel.tale.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ebiModel.tale.physicsBody!.affectedByGravity = false
        ebiModel.tale.physicsBody!.isDynamic = false
        self.addChild(ebiModel.tale)
    }
 
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            if touchNode == tailLeft {
                taleCollectionCount += 1
                if taleCollectionCount == 4 {
                    taleCollectionCount = 1
                }
                ebiModel.setTaleTexture(selectNum: taleCollectionCount)
            }
            if touchNode == tailRight {
                taleCollectionCount -= 1
                if taleCollectionCount == 0 {
                    taleCollectionCount = 3
                }
                ebiModel.setTaleTexture(selectNum: taleCollectionCount)

            }
            if touchNode == bodyLeft {
                if ebiModel.bodyCount <= 1 {
                    return
                }
                self.removeChildren(in: ebiModel.body)
                ebiModel.bodyCount -= 1
                addBody(count: ebiModel.bodyCount)
            }
            if touchNode == bodyRight {
                if ebiModel.bodyCount >= 5 {
                    return
                }
                self.removeChildren(in: ebiModel.body)
                ebiModel.bodyCount += 1
                addBody(count: ebiModel.bodyCount)
            }
            if touchNode == flyLabel {
                // TODO 遷移先先に渡すものをEbiModelだけに修正,レイアウト修正は1画面ずつ行いたいので後で
                let scene = FryScene(size: self.scene!.size, bodyCount: ebiModel.bodyCount, taleImageStr: "tale1")
                self.view!.presentScene(scene)
            }
        }
    }
}


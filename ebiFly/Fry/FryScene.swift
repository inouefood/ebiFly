//
//  FlyScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/16.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit
import SpriteKit

class FryScene: SKScene {
    // 定数
    let numAbura:Int = 300
    // 尻尾のスプライト
    let tale: SKSpriteNode
    // スプライトの配列
    var ebiBodySprites:[SKSpriteNode] = []
    var aburaSprites:[SKSpriteNode] = []
    var aburaRandomSeed:[Int] = []
    var koromoSprites:[SKSpriteNode] = []
    var koromoRandomSeed:[Int] = []
    var bodyCount: Int
    
    var isTale:Bool = false
    
    init(size: CGSize, bodyCount: Int, taleImageStr: String) {
        self.bodyCount = bodyCount
        
        tale = SKSpriteNode(imageNamed: taleImageStr)
        super.init(size: size)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false){(_) in
            self.isTale = false
            self.removeChildren(in: self.aburaSprites)
            
            let ebi = self.ebiBodySprites
            let t = self.tale
            self.removeChildren(in: self.ebiBodySprites)
            self.removeChildren(in: [self.tale])
//             self.removeChildren(in: self.tale)
            let scene = SauceScene(size: self.scene!.size, count: 5, abura: self.koromoSprites,  tale: t, ebi: ebi, seed: self.koromoRandomSeed)
            scene.scaleMode = SKSceneScaleMode.aspectFill
            self.view!.presentScene(scene)
        }
        Timer.scheduledTimer(withTimeInterval: 2.9, repeats: false){(_) in
            self.isTale = false
        }
        
        guard let width: CGFloat = self.view!.frame.width, let height: CGFloat = self.view!.frame.height else {
            return
        }
        // えび --------------------------------------------------------------
        //// 尻尾の初期設定
        let taleX = width
        let taleY = height * 1.3
        tale.size = CGSize(width: width/6, height: width/6)
        tale.position = CGPoint(x: taleX, y: taleY)
        tale.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        tale.zPosition = 1.2
        tale.physicsBody!.affectedByGravity = false
        tale.physicsBody!.isDynamic = false
        self.addChild(tale)
        
        
        //// 身体の初期設定
        for i in 0..<bodyCount {
            let ebiBody = SKSpriteNode(imageNamed: "ebibody")
            let ebX = taleX
            let ebY = (taleY - width/6)  - (width/6 * CGFloat(i))
            ebiBody.size = CGSize(width: width/6, height: width/6)
            ebiBody.position = CGPoint(x: ebX, y: ebY)
            ebiBody.physicsBody = SKPhysicsBody(circleOfRadius: 2)
            ebiBody.physicsBody!.affectedByGravity = true
            ebiBody.name = "ebiBody" + String(i)
            self.addChild(ebiBody)
            ebiBodySprites.append(ebiBody)
        }
        
        // jointの設定
        //// 身体のjoint
        for i in 1..<bodyCount {
            let joint = SKPhysicsJointPin.joint(withBodyA:ebiBodySprites[i-1].physicsBody!, bodyB: ebiBodySprites[i].physicsBody!, anchor: CGPoint(x: ebiBodySprites[i-1].frame.midX, y: ebiBodySprites[i].frame.midY))
            joint.frictionTorque = 0.2
            joint.upperAngleLimit = CGFloat(Double.pi/4)
            self.physicsWorld.add(joint)
        }
        //// 尻尾のjoint
        let joint = SKPhysicsJointFixed.joint(withBodyA: tale.physicsBody!, bodyB: ebiBodySprites[0].physicsBody!, anchor: CGPoint(x: tale.frame.midX, y: tale.frame.maxY))
        self.physicsWorld.add(joint)
        
        // あぶら --------------------------------------------------------------
        //// 配列の初期化
        for _ in 0..<numAbura {
            aburaRandomSeed.append(Int.random(in: 0...bodyCount-1))
        }
        
        //// あぶらたちの初期設定
        for i in 0..<numAbura {
            let abura = SKSpriteNode(imageNamed: "abura")
            let aburaX = Int(arc4random_uniform(UInt32(self.frame.size.width)))
            let aburaY = Int(arc4random_uniform(UInt32(self.frame.size.height / 2.0)))
            abura.position = CGPoint(x: aburaX, y: aburaY)
            abura.size = CGSize(width: abura.size.width*0.5, height: abura.size.height*0.5)
            abura.name = "abura" + String(i)
            abura.zPosition = 1.1
            abura.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            abura.physicsBody!.affectedByGravity = false
            abura.physicsBody!.linearDamping = 1.0
            self.addChild(abura)
            aburaSprites.append(abura)
        }
        
        // あぶら部分の背景 -----------------------------------------------------------------
        let rect = SKShapeNode(rectOf: CGSize(width: self.frame.size.width, height: self.frame.size.height))
        rect.position = CGPoint(x: self.frame.size.width/2, y: 0.0)
        rect.fillColor = UIColor.init(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0)
        self.addChild(rect)
        
        // ノードすべてについて画面端で跳ね返るようにする
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //タッチしたノードを取得する
        let location = touches.first!.location(in: self)
        guard let node = atPoint(location) as? SKSpriteNode else{
            return
        }
        if(node == tale) {
            isTale = true
        } else {
            isTale = false
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
            // タッチしたノードの座標を取得、移動
            let location = touches.first!.location(in: self)
            let action = SKAction.move(to: CGPoint(x:location.x, y:location.y), duration:0.1)
            if (isTale) { tale.run(action) }
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // あぶらの更新
        for i in 0..<numAbura {
            // あぶらエリアより高い位置のときあぶらたちを落下させる
            if (self.frame.height/2.0 < aburaSprites[i].position.y) {
                aburaSprites[i].position.y -= 1.0
            }
            
            // あぶらとえびの距離計算
            let dx:Float = Float(ebiBodySprites[aburaRandomSeed[i]].position.x - aburaSprites[i].position.x)
            let dy:Float = Float(ebiBodySprites[aburaRandomSeed[i]].position.y - aburaSprites[i].position.y)
            let dist:Float = sqrtf(dx * dx + dy * dy)
            if (dist < 50.0) {
                aburaSprites[i].position.x += CGFloat(dx)
                aburaSprites[i].position.y += CGFloat(dy)
                if !koromoSprites.contains(aburaSprites[i]){
                    koromoSprites.append(aburaSprites[i])
                    koromoRandomSeed.append(aburaRandomSeed[i])
                }
                // たまにあぶらのサイズを大きくする
                if (Int.random(in: 0...100) == 0 && aburaSprites[i].position.y < self.frame.height/2.0) {
                    aburaSprites[i].size = CGSize(width: aburaSprites[i].size.width*1.1, height: aburaSprites[i].size.height*1.1)
                }
            }
        }
    }
}


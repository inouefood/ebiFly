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
    let numAbura:Int = Constant.SpriteNum.abura
    var ebiModel: EbiModel 
    // スプライトの配列
    var ebiBodySprites:[SKSpriteNode] = []
    var aburaSprites:[SKSpriteNode] = []
    var aburaRandomSeed:[Int] = []
    var koromoSprites:[SKSpriteNode] = []
    var koromoRandomSeed:[Int] = []
    
    var isTale:Bool = false
    
    fileprivate lazy var presenter: FlyPresenter! = {
        return FlyPresenterImpl(model: FlyModelImpl(), output: self)
    }()

    // MARK: - Initializer
    
    init(size: CGSize, model: EbiModel) {
        self.ebiModel = model
        ebiModel.body.removeLast()
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    
    override func didMove(to view: SKView) {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false){(_) in
            self.isTale = false
            self.removeChildren(in: self.aburaSprites)
            
            let ebi = self.ebiBodySprites
            let t = self.ebiModel.tale
            self.removeChildren(in: self.ebiBodySprites)
            self.removeChildren(in: [self.ebiModel.tale])
            let scene = SauceScene(size: self.scene!.size, count: 5, abura: self.koromoSprites,  tale: t, ebi: ebi, seed: self.koromoRandomSeed)
            self.view!.presentScene(scene)
        }
        Timer.scheduledTimer(withTimeInterval: 2.9, repeats: false){(_) in
            self.isTale = false
        }
        
        //// 尻尾の初期設定
        let taleX = width/2
        let taleY = height - height/6
        ebiModel.tale.size = CGSize(width: width/6, height: width/6)
        ebiModel.tale.position = CGPoint(x: taleX, y: taleY)
        ebiModel.tale.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        ebiModel.tale.zPosition = 1.2
        ebiModel.tale.physicsBody!.affectedByGravity = false
        ebiModel.tale.physicsBody!.isDynamic = false
        self.addChild(ebiModel.tale)

        
        // 身体の初期設定
        for i in 0..<ebiModel.bodyCount {
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
        for i in 1..<ebiModel.bodyCount {
            let joint = SKPhysicsJointPin.joint(withBodyA:ebiBodySprites[i-1].physicsBody!, bodyB: ebiBodySprites[i].physicsBody!, anchor: CGPoint(x: ebiBodySprites[i-1].frame.midX, y: ebiBodySprites[i].frame.midY))
            joint.frictionTorque = 0.2
            joint.upperAngleLimit = CGFloat(Double.pi/4)
            self.physicsWorld.add(joint)
        }
        //// 尻尾のjoint
        let joint = SKPhysicsJointFixed.joint(withBodyA: ebiModel.tale.physicsBody!, bodyB: ebiBodySprites[0].physicsBody!, anchor: CGPoint(x: ebiModel.tale.frame.midX, y: ebiModel.tale.frame.maxY))
        self.physicsWorld.add(joint)
        
        // あぶら --------------------------------------------------------------
        //// 配列の初期化
        for _ in 0..<numAbura {
            aburaRandomSeed.append(Int.random(in: 0...ebiModel.bodyCount-1))
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
            // TODO 応急処置、できれば当たり判定を制御してプルプルさせたい
//            abura.physicsBody = SKPhysicsBody(circleOfRadius: 1)
//            abura.physicsBody!.affectedByGravity = false
//            abura.physicsBody!.linearDamping = 1.0
            self.addChild(abura)
            aburaSprites.append(abura)
        }
        
        // あぶら部分の背景 -----------------------------------------------------------------
        let rect = SKShapeNode(rectOf: CGSize(width: self.frame.size.width, height: self.frame.size.height))
        rect.position = CGPoint(x: self.frame.size.width/2, y: 0.0)
        rect.fillColor = UIColor.init(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0)
        self.addChild(rect)
        
        // 画面端での跳ね返
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // あぶらの更新
        for i in 0..<numAbura {
            // あぶらエリアより高い位置のときあぶらたちを落下させる
            if (self.frame.height/2.0 < aburaSprites[i].position.y) {
                aburaSprites[i].position.y -= 1.0
            }
            presenter.aburaToEbiCollision(ebiPos: ObjectPosition(pos: ebiBodySprites[aburaRandomSeed[i]].position), aburaPos:ObjectPosition(pos: aburaSprites[i].position), count: i)
        }
    }
    
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //タッチしたノードを取得する
        let location = touches.first!.location(in: self)
        guard let node = atPoint(location) as? SKSpriteNode else{
            return
        }
        if(node == ebiModel.tale) {
            isTale = true
        } else {
            isTale = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        let action = SKAction.move(to: CGPoint(x:location.x, y:location.y), duration:0.1)
        if (isTale) { ebiModel.tale.run(action) }
    }
}

// MARK: - Extension-FlyPresenterOutput

extension FryScene: FlyPresenterOutput {
    func showUpdateAbura(count: Int, pos: ObjectPosition) {
        aburaSprites[count].position.x += CGFloat(pos.x)
        aburaSprites[count].position.y += CGFloat(pos.y)
        if !koromoSprites.contains(aburaSprites[count]){
            koromoSprites.append(aburaSprites[count])
            koromoRandomSeed.append(aburaRandomSeed[count])
        }
        // たまにあぶらのサイズを大きくする
        if (Int.random(in: 0...100) == 0 && aburaSprites[count].position.y < self.frame.height/2.0) {
            aburaSprites[count].size = CGSize(width: aburaSprites[count].size.width*1.1, height: aburaSprites[count].size.height*1.1)
        }
    }
}

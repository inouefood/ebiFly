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
    var ebiModel: EbiModel
    // スプライトの配列
    var aburaSprites:[SKSpriteNode] = []
    var aburaRandomSeed:[Int] = []
    var koromoSprites:[SKSpriteNode] = []
    var koromoRandomSeed:[Int] = []
    lazy var aburaBackground = SKShapeNode(size: CGSize(width: self.frame.size.width, height: self.frame.size.height), color: UIColor.init(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0), pos: CGPoint(x: self.frame.size.width/2, y: 0.0))
    
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
        // 画面端での跳ね返り
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        self.addChild(aburaBackground)
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false){(_) in
            self.isTale = false
            self.removeChildren(in: self.aburaSprites)

            self.removeChildren(in: self.ebiModel.body)
            self.removeChildren(in: [self.ebiModel.tale])
        
            var body:[SKSpriteNode] = []
            for i in 0..<self.ebiModel.bodyCount {
                body.append(self.ebiModel.body[i])
            }
            
            let scene = SauceScene(size: self.scene!.size, count: 5, abura: self.koromoSprites,  tale: self.ebiModel.tale, ebi: body, seed: self.koromoRandomSeed)
            self.view!.presentScene(scene)
        }
        Timer.scheduledTimer(withTimeInterval: 2.9, repeats: false){(_) in
            self.isTale = false
        }
        
        ebiModel.tale.size = CGSize(width: width/6, height: width/6)
        ebiModel.tale.position = CGPoint(x: width/2, y: height - height/6)
        self.addChild(ebiModel.tale)

        for i in 0..<ebiModel.bodyCount {
            let ebY = (height - height/6 - width/6)  - (width/6 * CGFloat(i))
            ebiModel.body[i].size = CGSize(width: width/6, height: width/6)
            ebiModel.body[i].position = CGPoint(x: width/2, y: ebY)
            ebiModel.body[i].name = "ebiBody" + String(i)
            ebiModel.body[i].physicsBody = SKPhysicsBody(circleOfRadius: 20)
            ebiModel.body[i].physicsBody!.affectedByGravity = true
            self.addChild(ebiModel.body[i])
        }
        
        // jointの設定
        //// 身体のjoint
        for i in 1..<ebiModel.bodyCount {
            let joint = SKPhysicsJointPin.joint(withBodyA:ebiModel.body[i-1].physicsBody!, bodyB: ebiModel.body[i].physicsBody!, anchor: CGPoint(x: ebiModel.body[i-1].frame.midX, y: ebiModel.body[i].frame.midY))
            joint.frictionTorque = 0.2
            joint.upperAngleLimit = CGFloat(Double.pi/4)
            self.physicsWorld.add(joint)
        }
        //// 尻尾のjoint
        let joint = SKPhysicsJointFixed.joint(withBodyA: ebiModel.tale.physicsBody!, bodyB: ebiModel.body[0].physicsBody!, anchor: CGPoint(x: ebiModel.tale.frame.midX, y: ebiModel.tale.frame.maxY))
        self.physicsWorld.add(joint)
        
        // あぶら --------------------------------------------------------------
        //// 配列の初期化
        for _ in 0..<Constant.SpriteNum.abura {
            aburaRandomSeed.append(Int.random(in: 0...ebiModel.bodyCount-1))
        }
        
        //// あぶらたちの初期設定
        for i in 0..<Constant.SpriteNum.abura {
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
    }
    
    override func update(_ currentTime: TimeInterval) {
        // あぶらの更新
        for i in 0..<Constant.SpriteNum.abura {
            // あぶらエリアより高い位置のときあぶらたちを落下させる
            if (self.frame.height/2.0 < aburaSprites[i].position.y) {
                aburaSprites[i].position.y -= 1.0
            }
            presenter.aburaToEbiCollision(ebiPos: ObjectPosition(pos: ebiModel.body[aburaRandomSeed[i]].position), aburaPos:ObjectPosition(pos: aburaSprites[i].position), count: i)
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

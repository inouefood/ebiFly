//
//  SauceScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/16.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion
import AudioToolbox

class SauceScene: SKScene {
    
    // MARK: - Property
    
    var aburaSprites: [SKSpriteNode]
    var taleSprite: SKSpriteNode
    var ebiBodySprites: [SKSpriteNode]
    var aburaRandomSeed: [Int]
    var isFirstPosition:Bool = false
    var isEbiDonw = true
    var isShakeEnd = false
    var motionManager:CMMotionManager? = CMMotionManager()
    var x = 0
    var y = 0
    var z = 0
    var shakeCount = 0
    var flyCount = 0
    var flyCirc = 0
    var countVal = 0

    lazy var shakeLabel = SKLabelNode(fontSize: 50, text: "シェイクしろ！", pos: CGPoint(x: width/2, y: height - height / 6.0))
    lazy var fallSprite: [SKSpriteNode]! = {
       return [
            SKSpriteNode(image: "fallBack", pos: CGPoint(x: width/2, y: height/8), size: CGSize(width: width/2, height: width)),
            SKSpriteNode(image: "fallFront", pos: CGPoint(x: width/2, y: height/8), size: CGSize(width: width/2, height: width), zPos: 1.3)
        ]
    }()

    
    lazy var cloudSprite: [SKSpriteNode]! = {
        return [
            SKSpriteNode(image: "cround1", pos: CGPoint(x: width/3, y: height * 1.7), size: CGSize(width: width/2, height: width/3)),
            SKSpriteNode(image: "cround1", pos: CGPoint(x: width/1.3, y: height * 1.2), size: CGSize(width: width/2, height: width/3))
         ]
        }()
    lazy var backgroundSky: [SKShapeNode]! = {
        return [
            SKShapeNode(rect: CGRect(x: 0, y: height/1.5, width: width, height: height * 2),color: UIColor(appColor: .sky)),
            SKShapeNode(rect: CGRect(x: 0, y: height*2, width: width, height: height * 4), color: UIColor(appColor: .night))
        ]
    }()
    
    lazy var stars: [SKSpriteNode]! = {
        var sprite: [SKSpriteNode] = []
        for i in 0...20 {
            let posX = Int.random(in:0..<Int(width))
            let posY = Int.random(in:Int(height * 2)..<Int(height * 6))
            sprite.append(SKSpriteNode(image: "star", pos: CGPoint(x: posX, y: posY)))
        }
        return sprite
    }()
    
    fileprivate lazy var presenter: SaucePresenter! = {
        return SaucePresenterImpl(model: SauceModelImpl())
    }()
    
    var width: CGFloat!
    var height: CGFloat!
    
    // MARK: - Initializer
    
    init(size: CGSize, count: Int, abura: [SKSpriteNode], tale: SKSpriteNode, ebi: [SKSpriteNode], seed: [Int]){
        self.aburaSprites = abura
        self.taleSprite = tale
        self.ebiBodySprites = ebi
        self.aburaRandomSeed = seed
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = UIColor(appColor: .white)
        
        width = self.view!.frame.width
        height = self.view!.frame.height
    
        
        self.addChild(backgroundSky, cloudSprite, fallSprite, stars)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false){(_) in
            self.isFirstPosition = true
        }
        
        let taleX = width/2
        
        let taleY = height - height / 6.0
        taleSprite.position = CGPoint(x: width/2, y: height - height / 6.0)
        self.addChild(taleSprite)
        
        for i in 0..<ebiBodySprites.count {
            let ebY = (taleY - width/6) - (width/6 * CGFloat(i))
            ebiBodySprites[i].position = CGPoint(x: width, y: ebY)
            self.addChild(ebiBodySprites[i])
        }
        for i in 1..<ebiBodySprites.count {
            let joint = SKPhysicsJointPin.joint(withBodyA:ebiBodySprites[i-1].physicsBody!, bodyB: ebiBodySprites[i].physicsBody!, anchor: CGPoint(x: ebiBodySprites[i-1].frame.midX, y: ebiBodySprites[i].frame.midY))
            joint.frictionTorque = 0.2
            joint.upperAngleLimit = CGFloat(Double.pi/4)
            self.physicsWorld.add(joint)
        }
        
        
        for i in 0..<aburaSprites.count {
            switch aburaRandomSeed[i] {
            case 0:
                aburaSprites[i].position = CGPoint(x: taleX, y: ebiBodySprites[0].position.y)
            case 1:
                aburaSprites[i].position = CGPoint(x: taleX, y: ebiBodySprites[1].position.y)
            case 2:
                aburaSprites[i].position = CGPoint(x: taleX, y: ebiBodySprites[2].position.y)
            case 3:
                aburaSprites[i].position = CGPoint(x: taleX, y: ebiBodySprites[3].position.y)
            case 4:
                aburaSprites[i].position = CGPoint(x: taleX, y: ebiBodySprites[4].position.y)
            default:
                break
            }
            self.addChild(aburaSprites[i])
        }
        //// 尻尾のjoint
        let joint = SKPhysicsJointFixed.joint(withBodyA: taleSprite.physicsBody!, bodyB: ebiBodySprites[0].physicsBody!, anchor: CGPoint(x: taleSprite.frame.midX, y: taleSprite.frame.maxY))
        self.physicsWorld.add(joint)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if taleSprite.position != CGPoint(x: width, y: height - height / 6.0) && !isFirstPosition {
            
            self.removeChildren(in: [taleSprite])
            let taleY = height - height / 6.0
            taleSprite.position = CGPoint(x: width/2, y: taleY)
            self.addChild(taleSprite)
            
            self.removeChildren(in: ebiBodySprites)
            for i in 0..<ebiBodySprites.count {
                let ebY = (taleY - width/6)  - (width/6 * CGFloat(i))
                ebiBodySprites[i].position = CGPoint(x: width/2, y: ebY)
                self.addChild(ebiBodySprites[i])
            }
            for i in 1..<ebiBodySprites.count {
                let joint = SKPhysicsJointPin.joint(withBodyA:ebiBodySprites[i-1].physicsBody!, bodyB: ebiBodySprites[i].physicsBody!, anchor: CGPoint(x: ebiBodySprites[i-1].frame.midX, y: ebiBodySprites[i].frame.midY))
                joint.frictionTorque = 0.2
                joint.upperAngleLimit = CGFloat(Double.pi/4)
                self.physicsWorld.add(joint)
            }
            let joint = SKPhysicsJointFixed.joint(withBodyA: taleSprite.physicsBody!, bodyB: ebiBodySprites[0].physicsBody!, anchor: CGPoint(x: taleSprite.frame.midX, y: taleSprite.frame.maxY))
            self.physicsWorld.add(joint)
        }
        if isFirstPosition && isEbiDonw {
            if ebiBodySprites.last!.position.y < height/8 {
                isEbiDonw = false
                
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) {(_) in
                    //バイブ
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    self.motionManager = nil
                    self.shakeLabel.text = "0m"
                    self.shakeLabel.zPosition = 1.3
                    self.flyCirc = self.shakeCount * self.aburaSprites.count
                    
                    self.isShakeEnd = true
                }
                
                self.addChild(shakeLabel)
                
                for (i, value) in aburaRandomSeed.enumerated() {
                    if value == ebiBodySprites.count - 1  || value == ebiBodySprites.count - 2  {
                        aburaSprites[i].texture = SKTexture(imageNamed: "aburaBlack3")
                    }
                }
                //TODO シェイクロジックをModelで行う、なぜか処理が戻ってこないので一旦保留
//                if presenter.shakeDevice() {
//                    shakeCount += 1
//                }
                //シェイクジェスチャー開始
                self.motionManager!.accelerometerUpdateInterval = 0.2
                self.motionManager!.startAccelerometerUpdates(to: OperationQueue()) {
                    (data, error) in
                    DispatchQueue.main.async {
                        self.updateAccelerationData(data: data!.acceleration)
                    }
                }
            }
            taleSprite.position.y -= 1
            for i in 0..<ebiBodySprites.count {
                ebiBodySprites[i].position.y -= 1
            }
            for i in 0..<aburaSprites.count {
                aburaSprites[i].position.y -= 1
            }
        }
        if isShakeEnd {
            if flyCirc > countVal {
                
                for _ in 0...2 {
                    countVal += 1
                    
                    moveBackgroundItem()

                    if taleSprite.position.y < height / 2 {
                        taleSprite.position.y += 0.5
                        
                        for i in 0..<aburaSprites.count {
                            aburaSprites[i].position.y += 0.5
                        }
                    }
                }
            } else {
                sleep(1)
                let scene = GameClearScene(size: self.scene!.size, score: flyCount)
                scene.scaleMode = SKSceneScaleMode.aspectFill
                self.view!.presentScene(scene)
            }
        }
    }
    
    // MARK: - PrivateMethod
    
    private func updateAccelerationData(data: CMAcceleration) {
        
        let isShaken = self.x != Int(data.x) || self.y != Int(data.y) || self.z != Int(data.z)
        
        if isShaken {
            shakeCount += 1
            print("シェイクされたよ\(shakeCount)")
        }
        
        self.x = Int(data.x)
        self.y = Int(data.y)
        self.z = Int(data.z)
    }
    
    private func moveBackgroundItem() {
        fallSprite.forEach{ fall in
            fall.position.y -= 1
        }
        flyCount += 1
        shakeLabel.text = "\(flyCount)m"
        
        cloudSprite.forEach{ cloud in
            cloud.position.y -= 1
        }
        backgroundSky.forEach{ sky in
            sky.position.y -= 1
        }
        
        stars.forEach{ star in
            star.position.y -= 1
        }
    }
}

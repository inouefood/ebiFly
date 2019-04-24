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
    let fallFlont = SKSpriteNode(imageNamed: "fallFront")
    let fallBack = SKSpriteNode(imageNamed: "fallBack")
    
    var width: CGFloat!
    var height: CGFloat!
    
    //背景
    var croundSprite: [SKSpriteNode] = [SKSpriteNode(imageNamed: "cround1"), SKSpriteNode(imageNamed: "cround1")]
    var clearSky:SKShapeNode!
    var universeSky: SKShapeNode!
    var stars: [SKSpriteNode] = [SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star"), SKSpriteNode(imageNamed: "star")]
    
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
    override func didMove(to view: SKView) {
        self.backgroundColor = UIColor(appColor: .white)
        
        width = self.view!.frame.width
        height = self.view!.frame.height
       
        //背景
        clearSky = SKShapeNode(rectOf: CGSize(width: self.frame.width * 2, height: self.frame.height))
        clearSky.position = CGPoint(x: 0, y: self.frame.height)
        clearSky.fillColor = UIColor(appColor: .sky)
        self.addChild(clearSky)
        
        universeSky = SKShapeNode(rectOf: CGSize(width: self.frame.width * 2, height: self.frame.height + self.frame.height))
        universeSky.fillColor = UIColor(appColor: .night)
        universeSky.position = CGPoint(x: 0, y: self.frame.height + self.frame.height)
        self.addChild(universeSky)
        
        croundSprite[0].position = CGPoint(x: self.frame.width/3, y: self.frame.height )
        croundSprite[0].zPosition = 0.8
        self.addChild(croundSprite[0])
        croundSprite[1].position = CGPoint(x: self.frame.width/2, y: self.frame.height / 2 + 200)
        croundSprite[1].zPosition = 0.8
        self.addChild(croundSprite[1])
        
        stars[0].position = CGPoint(x: self.frame.width/3, y: self.frame.height + self.frame.height/2)
        stars[0].zPosition = 0.8
        self.addChild(stars[0])
        stars[1].position = CGPoint(x: self.frame.width/1, y: self.frame.height + self.frame.height/3)
        stars[1].zPosition = 0.8
        self.addChild(stars[1])
        stars[2].position = CGPoint(x: self.frame.width/2, y: self.frame.height + self.frame.height/1 + 100)
        stars[2].zPosition = 0.8
        self.addChild(stars[2])
        stars[3].position = CGPoint(x: self.frame.width/2 + 300, y: self.frame.height + self.frame.height/2 - 200)
        stars[3].zPosition = 0.8
        self.addChild(stars[3])
        stars[4].position = CGPoint(x: self.frame.width/3, y: self.frame.height + self.frame.height/1 + 400)
        stars[4].zPosition = 0.8
        self.addChild(stars[4])
        stars[5].position = CGPoint(x: self.frame.width/2, y: self.frame.height + self.frame.height/1 + 700)
        stars[5].zPosition = 0.8
        self.addChild(stars[5])
        stars[6].position = CGPoint(x: self.frame.width/2 - 200, y: self.frame.height + self.frame.height/1 + 8000)
        stars[6].zPosition = 0.8
        self.addChild(stars[6])
        stars[7].position = CGPoint(x: self.frame.width/2 + 100, y: self.frame.height + self.frame.height/1 + 300)
        stars[7].zPosition = 0.8
        self.addChild(stars[7])
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false){(_) in
            self.isFirstPosition = true
        }
        
        setHall(wid: width/2, hgt: height)
        
        let taleX = width/2
        
        let taleY = self.frame.height - self.frame.height / 6.0
        taleSprite.position = CGPoint(x: width/2, y: self.frame.height - self.frame.height / 6.0)
        self.addChild(taleSprite)
        
        for i in 0..<ebiBodySprites.count {
            let ebY = (taleY - width/6)  - (width/6 * CGFloat(i))
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
    func updateAccelerationData(data: CMAcceleration) {
        
        let isShaken = self.x != Int(data.x) || self.y != Int(data.y) || self.z != Int(data.z)
        
        if isShaken {
            shakeCount += 1
            print("シェイクされたよ\(shakeCount)")
        }
        
        self.x = Int(data.x)
        self.y = Int(data.y)
        self.z = Int(data.z)
    }
    func setHall(wid: CGFloat, hgt: CGFloat){
        fallBack.position = CGPoint(x: wid, y: hgt/8)
        fallFlont.position = CGPoint(x: wid, y: hgt/8)
        fallFlont.zPosition = 1.3
        self.addChild(fallBack)
        self.addChild(fallFlont)
    }
    override func update(_ currentTime: TimeInterval) {
        if taleSprite.position != CGPoint(x: self.view!.frame.width, y: self.frame.height - self.frame.height / 6.0) && !isFirstPosition {
            
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
            if ebiBodySprites.last!.position.y < self.view!.frame.height/8 {
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
                countVal += 1
                fallFlont.position.y -= 1
                fallBack.position.y -= 1
                flyCount += 1
                shakeLabel.text = "\(flyCount)m"
                
                croundSprite[0].position.y -= 1
                croundSprite[1].position.y -= 1
                clearSky.position.y -= 1
                universeSky.position.y -= 1
                stars[0].position.y -= 1
                stars[1].position.y -= 1
                stars[2].position.y -= 1
                stars[3].position.y -= 1
                stars[4].position.y -= 1
                stars[5].position.y -= 1
                stars[6].position.y -= 1
                stars[7].position.y -= 1
                
                if taleSprite.position.y < self.frame.height / 2 {
                    taleSprite.position.y += 0.5
                    
                    for i in 0..<aburaSprites.count {
                        aburaSprites[i].position.y += 0.5
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
}

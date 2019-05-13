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
    var ebiModel: EbiModel

    //ボタン
    lazy var tailLeft = SKSpriteNode(image: "left", pos: CGPoint(x: width/6, y: height - height/6), size: CGSize(width: width/6, height: width/6))
    lazy var tailRight = SKSpriteNode(image: "right", pos: CGPoint(x: width - width/6, y: height - height/6), size: CGSize(width: width/6, height: width/6))
    lazy var bodyLeft = SKSpriteNode(image: "left", pos: CGPoint(x: width/6 , y: height/3), size: CGSize(width: width/6, height: width/6))
    lazy var bodyRight = SKSpriteNode(image: "right", pos: CGPoint(x: width - width/6, y: height/3), size: CGSize(width: width/6, height: width/6))
    lazy var flyLabel = SKLabelNode(fontSize: 70, text: "揚げる!!", pos: CGPoint(x:width/2, y:height/10))
    
    fileprivate lazy var presenter: CharactorMakePresenter! = {
        return CharactorMakePresenterImpl(model: CharactorMakeModelImpl(), output: self)
    }()

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

        createTale(taleImgStr: "tale1")
        createBody(count: ebiModel.bodyCount)
    }
    
    // MARK: - PrivateMethod
    
    private func createBody(count: Int){
        
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
    private func createTale(taleImgStr: String){
        self.addChild(bodyLeft, tailRight, tailLeft, bodyRight, flyLabel)
    
        ebiModel.tale.position = CGPoint(x: width/2, y: taleY)
        ebiModel.tale.size = CGSize(width: width/4, height: width/4)
        ebiModel.tale.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        ebiModel.tale.zPosition = 1.2
        ebiModel.tale.physicsBody!.affectedByGravity = false
        ebiModel.tale.physicsBody!.isDynamic = false
        self.addChild(ebiModel.tale)
    }
 
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            if touchNode == tailLeft {
                presenter.changeEbiTaleLeft()
            }
            if touchNode == tailRight {
                presenter.changeEbiTaleRignt()
            }
            if touchNode == bodyLeft {
                presenter.subEbiBody(count: ebiModel.bodyCount)
            }
            if touchNode == bodyRight {
                presenter.addEbiBody(count: ebiModel.bodyCount)
            }
            if touchNode == flyLabel {
                //SpriteKitでは親Nodeに追加済みのNodeを再度別親Nodeに追加しようとすると落ちる
                self.removeChildren(in: ebiModel.body)
                self.removeChildren(in: [ebiModel.tale])

                let scene = FryScene(size: self.scene!.size, model: ebiModel)
                self.view!.presentScene(scene)
            }
        }
    }
}

extension CharactorMakeScene: CharactorMakePresenterOutput {
    func showUpdateEbiBody(bodyCount: Int) {
        self.removeChildren(in: ebiModel.body)
        ebiModel.bodyCount = bodyCount
        createBody(count: ebiModel.bodyCount)
    }
    
    func showUpdateEbiTale(taleCount: Int) {
        ebiModel.setTaleTexture(selectNum: taleCount)
    }
}

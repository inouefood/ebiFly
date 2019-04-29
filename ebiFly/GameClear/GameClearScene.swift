//
//  GameClearScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/16.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import SpriteKit

class GameClearScene: SKScene {
    let score: Int
    lazy var scoreLabel: SKLabelNode! = {
        return SKLabelNode(font: "Verdana-bold", fontSize: 50, text: "\(score)m", pos: CGPoint(x:self.frame.width/2, y:self.frame.height - self.frame.height/5))
    }()
    lazy var retrayLabel: SKLabelNode! = {
       return SKLabelNode(fontSize: 50, text: "もう一度遊ぶ", pos: CGPoint(x: self.frame.width/2, y: self.frame.height/6))
    }()
    lazy var clearImage:SKSpriteNode! = {
        return SKSpriteNode(image: "clearimage", pos: CGPoint(x: self.frame.width/2, y: self.frame.height/2), size: CGSize(width: self.view!.frame.width/1.5, height: self.view!.frame.width/1.5))
    }()

    // MARK: - Initializer
    
    init(size: CGSize, score: Int) {
        self.score = score
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = UIColor(appColor: .thema)
        
        self.addChild(scoreLabel, clearImage, retrayLabel)        
    }
    
    // MARK: - TouchEvent
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self){
            let touchNode = self.atPoint(location)
            if touchNode == retrayLabel {
                let scene = CharactorMakeScene(size: self.scene!.size)
                scene.scaleMode = SKSceneScaleMode.aspectFill
                self.view!.presentScene(scene)
            }
        }
    }
}

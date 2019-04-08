//
//  GameClearScene.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/03/16.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit
import SpriteKit

class GameClearScene: SKScene {
    let score: Int
    let scoreLabel = SKLabelNode(fontNamed: "Verdana-bold")
    let clearImage = SKSpriteNode(imageNamed: "clearimage")
    let retrayLabel = SKLabelNode(fontNamed: "Verdana-bold")
    init(size: CGSize, score: Int) {
        self.score = score
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = SKColor.gray
        
       self.backgroundColor = SKColor(red: 36/255, green: 139/255, blue: 255/255, alpha: 1)
        
        scoreLabel.text = "\(score)m"
        scoreLabel.fontSize = 150
        scoreLabel.position = CGPoint(x:self.frame.width/2, y:self.frame.height - self.frame.height/3)
        self.addChild(scoreLabel)
        clearImage.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        clearImage.size = CGSize(width: self.view!.frame.width, height: self.view!.frame.width)
        self.addChild(clearImage)
        retrayLabel.position = CGPoint(x: self.frame.width/2, y: self.frame.height/3)
        retrayLabel.fontSize = 100
        retrayLabel.text = "もう一度遊ぶ"
        self.addChild(retrayLabel)
    }
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

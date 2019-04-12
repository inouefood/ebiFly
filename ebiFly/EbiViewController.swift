//
//  EbiViewController.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/12.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit
import SpriteKit

class EbiViewController: UIViewController {

    override func loadView() {
        let skView = SKView(frame: UIScreen.main.bounds)
        self.view = skView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView
        skView.ignoresSiblingOrder = true
        let size = CGSize(width: skView.bounds.size.width, height: skView.bounds.size.height)
        let scene = GameScene(size: size)
        skView.presentScene(scene)
    }
}

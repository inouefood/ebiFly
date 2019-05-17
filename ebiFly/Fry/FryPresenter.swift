//
//  FryScenePresenter.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/10.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol FlyPresenter:class {
    func aburaToEbiCollision(ebiPos: ObjectPosition, aburaPos: ObjectPosition,count: Int)
}
protocol FlyPresenterOutput:class {
    func showUpdateAbura(count: Int, pos: ObjectPosition)
}


class FlyPresenterImpl: FlyPresenter {
    private let model: FlyModel
    private weak var  output: FlyPresenterOutput?
    init(model: FlyModel, output: FlyPresenterOutput) {
        self.model = model
        self.output = output
    }
    
    func aburaToEbiCollision(ebiPos: ObjectPosition, aburaPos: ObjectPosition,count: Int){
        let ebiAburaDist = model.aburaToEbiCollision(ebiPos:ebiPos, aburaPos: aburaPos)
        if ebiAburaDist.collision {
            output?.showUpdateAbura(count:count , pos: ebiAburaDist.pos)
        }
    }
    
    
}

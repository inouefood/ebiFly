//
//  CharactorMakePresenter.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/11.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol CharactorMakePresenter {
    func changeEbiTaleLeft()
    func changeEbiTaleRignt()
}
protocol CharactorMakePresenterOutput {
    func showUpdateEbiTale(taleCount:Int)
}

class CharactorMakePresenterImpl: CharactorMakePresenter {
    let model:CharactorMakeModel
    let output: CharactorMakePresenterOutput
    
    // MARK: - Initializer
    init(model: CharactorMakeModel, output: CharactorMakePresenterOutput) {
        self.model = model
        self.output = output
    }

    func changeEbiTaleLeft() {
        output.showUpdateEbiTale(taleCount: model.changeEbiTale(count: 1))
    }
    
    func changeEbiTaleRignt() {
        output.showUpdateEbiTale(taleCount: model.changeEbiTale(count: -1))
    }
}

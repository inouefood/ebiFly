//
//  CharactorMakePresenter.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/11.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol CharactorMakePresenter:class {
    func changeEbiTaleLeft()
    func changeEbiTaleRignt()
    func addEbiBody(count: Int)
    func subEbiBody(count: Int)
}
protocol CharactorMakePresenterOutput:class {
    func showUpdateEbiTale(taleCount: Int)
    func showUpdateEbiBody(bodyCount: Int)
    
}

class CharactorMakePresenterImpl: CharactorMakePresenter {
    
    private let model:CharactorMakeModel
    private weak var output: CharactorMakePresenterOutput?
    
    // MARK: - Initializer
    init(model: CharactorMakeModel, output: CharactorMakePresenterOutput) {
        self.model = model
        self.output = output
    }

    func changeEbiTaleLeft() {
        output?.showUpdateEbiTale(taleCount: model.changeEbiTale(count: 1))
    }
    
    func changeEbiTaleRignt() {
        output?.showUpdateEbiTale(taleCount: model.changeEbiTale(count: -1))
    }
    func addEbiBody(count: Int) {
        if count <= 1 {
            return
        }
        output?.showUpdateEbiBody(bodyCount: count - 1)
    }
    func subEbiBody(count: Int) {
        if count >= 5 {
            return
        }
        output?.showUpdateEbiBody(bodyCount: count + 1)
    }
}

//
//  MyShape.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 09/01/2018.
//  Copyright © 2018 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

class MyShape: SKShapeNode {
    var type: GameStatus
    var isActive: Bool {
        didSet {
            switch (oldValue, isActive) {
            case (false, false):
                break
            case (false, true):
                switch type {
                case .Off:
                    self.fillColor = .red
                    self.strokeColor = .red
                case .Searching:
                    self.fillColor = .yellow
                    self.strokeColor = .yellow
                case .On:
                    self.fillColor = .greenAppleColor()
                    self.strokeColor = .greenAppleColor()
                }
            case (true, false):
                self.fillColor = .gray
                self.strokeColor = .gray
            case (true, true):
                break
            }
//            if oldValue == false && oldValue != !isActive {
//                self.fillColor = .gray
//                self.strokeColor = .gray
//            } else if !oldValue && isActive {
//                switch type {
//                case .Off:
//                    self.fillColor = .red
//                    self.strokeColor = .red
//                case .Searching:
//                    self.fillColor = .yellow
//                    self.strokeColor = .yellow
//                case .On:
//                    self.fillColor = .greenAppleColor()
//                    self.strokeColor = .greenAppleColor()
//                }
//            }
        }
    }
        
    override init() {
        type = .Off
        isActive = false
        super.init()
    }
    
    convenience init(type: GameStatus) {
//        self.init()
        let radius = GV.mainViewController!.view.frame.size.width / 80
        self.init(circleOfRadius: radius)
        self.type = type
        self.fillColor = .gray
        self.strokeColor = .gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(gameStatus: GameStatus) {
        isActive = self.type == gameStatus
        
    }
}


//
//  MySKLanguage.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 27/04/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import RealmSwift

class MySKLanguages: MySKTable {
    
    var callBack: ()->()
    let heightOfTableRow: CGFloat = 40
    var parentNode: SKSpriteNode
    var positionMultiplier = GV.deviceConstants.cardPositionMultiplier * 0.6
    var countLanguages = 0
    let myColumnWidths: [CGFloat] = [100]  // in %
    let deleteImage = DrawImages.getDeleteImage(CGSize(width: 30,height: 30))
    let modifyImage = DrawImages.getModifyImage(CGSize(width: 30,height: 30))
    let OKImage = DrawImages.getOKImage(CGSize(width: 30,height: 30))
    //    let statisticImage = DrawImages.getStatisticImage(CGSizeMake(30,30))
    let myName = "MySKLanguages"
    
    
    
    init(parent: SKSpriteNode, callBack: @escaping ()->()) {
        countLanguages = GV.language.count()
        self.parentNode = parent
        self.callBack = callBack
//        let size = CGSizeMake(parent.frame.width * 0.9, heightOfTableRow + CGFloat(countLanguages) * heightOfTableRow)
        
        
        super.init(columnWidths: myColumnWidths, rows:countLanguages, headLines: [GV.language.getText(.tcChooseLanguage)], parent: parent)
        self.name = myName

        showMe(showLanguages)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLanguages() {
        changeHeadLines([GV.language.getText(.tcChooseLanguage)])
        reDraw()
        for index in 0..<countLanguages {
            let (languageName, selected) = GV.language.getLanguageNames(LanguageCodes(rawValue:index)!)
            showElementOfTable(languageName, column: 0, row: index, selected: selected)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        touchesBeganAtNode = atPoint(touchLocation)
        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != myName)) {
            touchesBeganAtNode = nil
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = touches.first!.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        let touchesEndedAtNode = atPoint(touchLocation)
        let (touch, _, _) = checkTouches(touches, withEvent: event)
        switch touch {
            case MyEvents.goBackEvent:
                let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
                myParent.run(fadeInAction)                
                removeFromParent()
                callBack()
            case .noEvent:
                if touchesBeganAtNode != nil && touchesEndedAtNode is SKLabelNode || (touchesEndedAtNode is SKSpriteNode && touchesEndedAtNode.name != myName) {
                    let (_, row) = getColumnRowOfElement(touchesBeganAtNode!.name!)
                    GV.language.setLanguage(LanguageCodes(rawValue: row)!)
                    try! realm.write({
                        GV.player!.aktLanguageKey = GV.language.getText(.tcAktLanguage)
                    })
                    showLanguages()
                }        
        }
    }
    override func setMyDeviceSpecialConstants() {
        switch GV.deviceConstants.type {
        case .iPadPro12_9:
            fontSize = CGFloat(20)
        case .iPadPro9_7:
            fontSize = CGFloat(20)
        case .iPad2:
            fontSize = CGFloat(20)
        case .iPadMini:
            fontSize = CGFloat(20)
        case .iPhone6Plus:
            fontSize = CGFloat(15)
        case .iPhone6:
            fontSize = CGFloat(15)
        case .iPhone5:
            fontSize = CGFloat(13)
        case .iPhone4:
            fontSize = CGFloat(12)
        default:
            break
        }
    }
    
}


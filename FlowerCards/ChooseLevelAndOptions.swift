//
//  ChooseLevelAndOptions.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 02/11/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift
import SpriteKit


class ChooseLevelAndOptions: MySKTable {
    let myDetailedColumnWidths: [CGFloat] = [30, 20, 25, 25] // in %
    let chooseLevelColumn = 0
    let choosePackageNrColumn = 2
    let chooseHelplineTypeColumn = 3
    let myName = "MyChooseLevel"
    var countColumns = 0
    var countLevels = 0
    let playerID: Int
    let xxx = SKSpriteNode()
    
    
    
    
    
    init() {
        self.playerID = GV.player!.ID
        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        countColumns = myDetailedColumnWidths.count
        countLevels = GV.levelsForPlay.count()
        let headLines = GV.language.getText(.tcPlayerStatisticHeader, values: playerName)
        super.init(columnWidths: myDetailedColumnWidths,
                   rows:countLevels + 1, headLines: [headLines],
                   parent: xxx,
                   width: (GV.mainViewController?.view.frame.width)! * 0.9)
        
        showMe(showLevels)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLevels() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcLevelAndGames)),
                                    MultiVar(string: GV.language.getText(.tcSize)),
                                    MultiVar(string: GV.language.getText(.tcPackages)),
                                    MultiVar(string: GV.language.getText(.tcHelpLines))
                                    ]
        showRowOfTable(elements: elements, row: 0, selected: true)
        let button1Texture = atlas.textureNamed("button1")
        let button2Texture = atlas.textureNamed("button2")
        let button3Texture = atlas.textureNamed("button3")
        let greenRedTexture = atlas.textureNamed("greenRedButton")
        let purpleTexture = atlas.textureNamed("purpleButton")
        let noColorTexture = atlas.textureNamed("noColorButton")
        for row in 0..<countLevels {
            let countStr = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true", GV.player!.ID, row).count)
            var actPackageCount = 0
            var helpLinesCount = 2
            var packageTextures = [button1Texture, button2Texture, button3Texture]
            var helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
            if countStr != "0" {
                let lastGame = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d", GV.player!.ID, row).sorted(byProperty: "created").last!
                #if REALM_V1
                actPackageCount = lastGame.packages
                helpLinesCount = lastGame.helpLines
                #endif
            }
            switch actPackageCount {
                case 0: packageTextures = [button1Texture, button2Texture, button3Texture]
                case 1: packageTextures = [button1Texture, button2Texture, button3Texture]
                case 2: packageTextures = [button1Texture, button2Texture, button3Texture]
                default: break
            }
            switch helpLinesCount {
                case 2: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
                case 1: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
                case 0: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
                default: break
            }
            let elements: [MultiVar] = [MultiVar(string: (row < 10 ? " " : "") + String(row + 1) + ": (" + countStr + ")" ),
                                        MultiVar(string: GV.levelsForPlay.getLevelFormat(level: row)),
                                        MultiVar(textures: packageTextures),
                                        MultiVar(textures: helpLineTextures),
            ]
            showRowOfTable(elements: elements, row: row + 1, selected: row == GV.player!.levelID ? true : false)
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
        let (_, row, column, element) = checkTouches(touches, withEvent: event)
        switch (row, column, element) {
        case (0, 0, _):
            removeFromParent()
        case (2..<1000, chooseLevelColumn, NoValue):
            realm.beginWrite()
            GV.player!.levelID = row - 2
            try! realm.commitWrite()
            removeFromParent()
            showMe(showLevels)
        case (2..<1000, choosePackageNrColumn, 0...2):
            break
        case (2..<1000, chooseHelplineTypeColumn, 0...2):
            break
        default:
            break
        }
        
    }
    

}

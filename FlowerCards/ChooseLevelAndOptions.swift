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
    var callBack: () -> ()
    let myDetailedColumnWidths: [CGFloat] = [20, 20, 20, 25, 15] // in %
    let chooseLevelColumn = 0
    let showPackageNrColumn = 2
    let chooseHelplineTypeColumn = 3
    let startPlayingLevel = 4
    var countColumns = 0
    var countLevels = 0
    let playerID: Int
    let xxx = SKSpriteNode()
    let startImage = DrawImages.getStartImage(CGSize(width: 20, height: 20))
    
    init(_ callBack: @escaping ()->()) {
        self.playerID = GV.player!.ID
        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        countColumns = myDetailedColumnWidths.count
        countLevels = GV.levelsForPlay.count()
        self.callBack = callBack
        let headLines = GV.language.getText(.tcPlayerStatisticHeader, values: playerName)
//        self.myName = "ChooseLevelAndOptions"

        super.init(columnWidths: myDetailedColumnWidths,
                   countRows:countLevels + 1, headLines: [headLines],
                   parent: xxx,
                   myName: "ChooseLevelAndOptions",
                   width: (GV.mainViewController?.view.frame.width)! * 0.9)
        
        showMe(showLevels)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLevels() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcLevel)),
                                    MultiVar(string: GV.language.getText(.tcSize)),
                                    MultiVar(string: GV.language.getText(.tcPackages)),
                                    MultiVar(string: GV.language.getText(.tcHelpLines)),
                                    MultiVar(string: GV.language.getText(.tcStart))
                                    ]
//        showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: 0)
        tableOfRows.append(RowOfTable(elements: elements, selected: true))
        let greenRedTexture = atlas.textureNamed("greenRedButton")
        let purpleTexture = atlas.textureNamed("purpleButton")
        let noColorTexture = atlas.textureNamed("noColorButton")
        for levelID in 0..<countLevels {
            let countStr = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true", GV.player!.ID, levelID).count)
            var actPackageCount = 1
            var helpLinesCount = 2
            var helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
            if countStr != "0" {
                let lastGame = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d", GV.player!.ID, levelID).sorted(byProperty: "created").last!
                #if REALM_V1
                    helpLinesCount = lastGame.helpLines
                #endif
            }
            switch helpLinesCount {
                case 2: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
//                case 1: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
//                case 0: helpLineTextures = [greenRedTexture, purpleTexture, noColorTexture]
                default: break
            }
            #if REALM_V1
                actPackageCount = GV.levelsForPlay.levelParam[levelID].countPackages
            #endif
            let elements: [MultiVar] = [MultiVar(string: (levelID < 10 ? " " : "") + String(levelID + 1) + ": (" + countStr + ")" ),
                                        MultiVar(string: GV.levelsForPlay.getLevelFormat(level: levelID)),
                                        MultiVar(string: String(actPackageCount)),
                                        MultiVar(textures: helpLineTextures),
                                        MultiVar(texture: SKTexture(image: startImage))
            ]
//            showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: levelID == GV.player!.levelID ? true : false), row: levelID + 1)
            tableOfRows.append(RowOfTable(elements: elements, selected: levelID == GV.player!.levelID ? true : false))
        }
        // show the actLevel in the first line!
        setStartIndex() // the actLevel should always be on screen!
        showTable()
    }
    
    
    // called only when not after scrolling of the screen
    override func ownTouchesEnded(row: Int, column: Int, element: Int) {
        switch (row, column, element) {
        case (0, 0, _):
            removeFromParent()
        case (2..<1000, chooseLevelColumn...chooseHelplineTypeColumn, NoValue):
            setLevel(level: row - 2)
        case (2..<1000, chooseHelplineTypeColumn, 0...2):
            break
        case (2..<1000, startPlayingLevel, _):
            if tableOfRows[row - 1].selected {
                callBack()  // start a new Game at this level
            } else {
                setLevel(level: row - 2)
            }
            
            break
        default:
            break
        }
        
    }
    
    func setLevel(level: Int) {
        realm.beginWrite()
        GV.player!.levelID = level
        try! realm.commitWrite()
        setStartIndex()
        showTable()
    }
    

}

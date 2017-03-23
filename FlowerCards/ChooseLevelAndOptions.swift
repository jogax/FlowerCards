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
    let myDetailedColumnWidths: [CGFloat] = [20, 20, 20, 20, 20] // in %
    let chooseLevelColumn = 0
    let showPackageNrColumn = 2
//    let chooseHelplineTypeColumn = 3
    let startPlayingLevel = 3
    var countColumns = 0
    var countLevels = 0
    let playerID: Int
    let imageSize = CGSize(width: 30, height: 30)
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
//                                    MultiVar(string: GV.language.getText(.tcSize)),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "1")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "2")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "3")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "4")),
//                                    MultiVar(string: GV.language.getText(.tcHelpLines)),
//                                    MultiVar(string: GV.language.getText(.tcStart))
                                    ]
//        showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: 0)
        tableOfRows.append(RowOfTable(elements: elements, selected: true))
        for levelID in 0..<countLevels {
            let countStr = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true", GV.player!.ID, levelID).count)
            let countStr1Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 1", GV.player!.ID, levelID).count)
            let countStr2Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 2", GV.player!.ID, levelID).count)
            let countStr3Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 3", GV.player!.ID, levelID).count)
            let countStr4Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 4", GV.player!.ID, levelID).count)
//           var actPackageCount = 1
//                actPackageCount = GV.levelsForPlay.levelParam[levelID].countPackages
            let levelString = (levelID < 10 ? "0" : "") + String(levelID + 1) + "(" + GV.levelsForPlay.getLevelFormat(level: levelID) + "): " + countStr
            let elements: [MultiVar] = [MultiVar(string: levelString),
//                                        MultiVar(string: GV.levelsForPlay.getLevelFormat(level: levelID)),
                                        MultiVar(string: "(" + String(countStr1Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr2Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr3Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr4Pkg + ") >")),
            ]
            tableOfRows.append(RowOfTable(elements: elements, selected: levelID == GV.player!.levelID ? true : false))
        }
        // show the actLevel in the first line!
        setStartIndex() // the actLevel should always be on screen!
        showTable()
    }
    
    
    // called only when not after scrolling of the screen
    override func ownTouchesEnded(row: Int, column: Int, element: Int) {
        switch (row, column) {
        case (0, 0):
            removeFromParent()
        case (2..<1000, 1...4):
            setLevel(level: row - 2, countPackages: column)
            callBack()  // start a new Game at this level            
            break
        default:
            break
        }
        
    }
    
    func setLevel(level: Int, countPackages: Int) {
        realm.beginWrite()
        GV.player!.levelID = level
        GV.player!.countPackages = countPackages
        try! realm.commitWrite()
        setStartIndex()
        showTable()
    }
    

}

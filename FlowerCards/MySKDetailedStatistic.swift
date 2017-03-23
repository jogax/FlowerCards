//
//  MySKDetailedStatistic.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 11/05/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import RealmSwift

class MySKDetailedStatistic: MySKTable {
    
    var callBack: (Bool, Int, Int, Int)->()
    let myDetailedColumnWidths: [CGFloat] = [18, 14, 17, 17, 17, 17] // in %
//    let myName = "MySKStatistic"
    let countLines = GV.levelsForPlay.count()
    let playerID: Int
    let parentNode: SKSpriteNode
    var countPackages = 1
//    var lastLocation = CGPoint.zero

    
    
    
    
    init(playerID: Int, parent: SKSpriteNode, callBack: @escaping (Bool, Int, Int, Int)->()) {
        self.playerID = playerID
        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        self.parentNode = parent
        self.callBack = callBack
        var errorTxt = ""
        #if TEST
            let allGamesCount = realm.objects(GameModel.self).filter("playerID = %d", playerID).count
            let errorGamesCount = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false", playerID).count - 1
            errorTxt = " errorGames: \(errorGamesCount) / \(allGamesCount)"
        #endif
        let headLines = GV.language.getText(.tcPlayerStatisticHeader, values: playerName, errorTxt)
        super.init(columnWidths: myDetailedColumnWidths, countRows:countLines + 1, headLines: [headLines], parent: parent, myName: "MySKDetailedStatistic", width: parent.parent!.frame.width * 0.9)
        self.showVerticalLines = true
        
        showMe(showStatistic)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showStatistic() {
        tableOfRows.removeAll()
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcLevel)),
//                                    MultiVar(string: GV.language.getText(.tcCountPlays)),
//                                    MultiVar(string: GV.language.getText(.tcCountCompetitions)),
//                                    MultiVar(string: GV.language.getText(.tcCountVictorys)),
                                    MultiVar(string: GV.language.getText(.tcAllTime)),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "1")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "2")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "3")),
                                    MultiVar(string: GV.language.getText(.tcPackage, values: "4")),
                                    
                                    ]
        tableOfRows.append(RowOfTable(elements: elements, selected: true))
        // collect all lines in tableOfRows in parent
        for levelID in 0..<countLines {
            var statistic: StatisticModel?
            statistic = realm.objects(StatisticModel.self).filter("playerID = %d and levelID = %d", playerID, levelID).first
            if statistic == nil {
                statistic = StatisticModel()
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = NumberFormatter.Style.none // .DecimalStyle
            let levelString = (levelID < 9 ? "0" : "") + String(levelID + 1) + " (" + GV.levelsForPlay.getLevelFormat(level: levelID) + "): \(statistic!.countPlays)"
            let countStr1Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 1", playerID, levelID).count)
            let countStr2Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 2", playerID, levelID).count)
            let countStr3Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 3", playerID, levelID).count)
            let countStr4Pkg = String(realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = 4", playerID, levelID).count)
            let elements: [MultiVar] = [MultiVar(string: levelString),
                                        MultiVar(string: "\(statistic!.allTime.dayHourMinSec)"),
                                        MultiVar(string: "(" + String(countStr1Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr2Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr3Pkg + ") >")),
                                        MultiVar(string: "(" + String(countStr4Pkg + ") >")),

//                                        MultiVar(string: "\(statistic!.countPlays)"),
//                                        MultiVar(string: "\(statistic!.countMultiPlays)"),
//                                        MultiVar(string: "\(statistic!.victorys) / \(statistic!.defeats)"),
//                                        MultiVar(texture: SKTexture(image: DrawImages.getGoForwardImage(CGSize(width: 20, height: 20)))),
            ]
            tableOfRows.append(RowOfTable(elements: elements, selected: true))
        }
        
        // show the array
        showTable()

    }
    
    func convertNameWhenRequired(_ name: String)->String {
        if name == GV.language.getText(.tcAnonym) {
            return GV.language.getText(.tcGuest)
        }
        return name
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.location(in: self)
//        touchesBeganAtNode = atPoint(touchLocation)
//        lastLocation = touches.first!.location(in: GV.mainViewController!.view)
//        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != myName)) {
//            touchesBeganAtNode = nil
//        }
//    }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let actLocation = touches.first!.location(in: GV.mainViewController!.view)
//        let delta:CGFloat = lastLocation.y - actLocation.y
//        lastLocation = actLocation
//        scrollView(delta)
//    }
//    
    override func ownTouchesEnded(row: Int, column: Int, element: Int) {
        switch (row, column) {
        case (0, 0):
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack(false, 0, 0, 0)
        case (2..<10000, 2...5):
            countPackages = column - 1
            showDetailedPlayerStatistic(levelID: row - 2, countPackages: column - 1)
        default:
            break
        }
        
    }
    
    
    func showDetailedPlayerStatistic(levelID: Int, countPackages: Int) {
        _ = MySKGameStatistic(playerID: playerID, levelID: levelID, countPackages: countPackages, parent: self, callBack: callBackFromGameStatistic)
    }
 
    func callBackFromGameStatistic(_ startGame: Bool = false, gameNumber: Int = 0, levelIndex: Int = 0) {
        if startGame {
            callBack(startGame, gameNumber, levelIndex, countPackages)
        }
    }

//    override func setMyDeviceSpecialConstants() {
//        fontSize = GV.onIpad ? 20 : 15
//    }
//    
    
}


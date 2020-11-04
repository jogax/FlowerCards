//
//  MySKGameStatistic.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 05/08/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import RealmSwift

class MySKGameStatistic: MySKTable {
    
    var callBack: (Bool , Int, Int) -> ()
    let myGameColumnWidths: [CGFloat] = [25, 25, 25, 25] // in %
//    let myName = "MySKStatistic"
    let playerID: Int
    let levelID: Int
    let gamesOfThisLevel: Results<GameModel>
//    var lastLocation = CGPoint.zero
    var gameNumbers = [Int: Int]() // column : gameNumber

    
    
    
    
    
    init(playerID: Int, levelID: Int, countPackages: Int, parent: SKSpriteNode, callBack: @escaping (Bool, Int, Int)->()) {
        self.playerID = playerID
        self.levelID = levelID
//        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        self.callBack = callBack
        let headLines = GV.language.getText(.tcPlayerStatisticLevel,
                        values: String(levelID + 1), GV.levelsForPlay.getLevelFormat(level: levelID), String(countPackages))
        gamesOfThisLevel = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and countPackages = %d",
                                                                playerID, levelID, countPackages).sorted(byKeyPath: "gameNumber")
        super.init(columnWidths: myGameColumnWidths, countRows:gamesOfThisLevel.count + 1, headLines: [headLines], parent: parent, myName: "MySKDetailedStatistic", width: parent.parent!.frame.width * 0.9)
        self.showVerticalLines = true
        
        showMe(showStatistic)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showStatistic() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcGame)),
//                                    MultiVar(string: GV.language.getText(.tcGameArt)),
//                                    MultiVar(string: GV.language.getText(.tcOpponent)),
                                    MultiVar(string: GV.language.getText(.tcScore)),
                                    MultiVar(string: GV.language.getText(.tcAllTime)),
//                                    MultiVar(string: GV.language.getText(.tcVictory)),
                                    MultiVar(string: GV.language.getText(.tcStart)),
                                    ]
        tableOfRows.append(RowOfTable(elements: elements, selected: true))
//        showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: 0)
        var row = 1
        for game in gamesOfThisLevel {
//            var gameArt = GV.language.getText(.tcGame) // simple Game
//            var opponent = ""
            let score = String(game.playerScore)
//            var victory: SKTexture = SKTexture(image: DrawImages.getOKImage(CGSize(width: 20, height: 20)))
//            var textureSize:CGFloat = 1.0
//            #if REALM_V2
//            if !game.gameFinished {
//                victory = atlas.textureNamed("help")
//                textureSize = 0.25
//            }
//            #endif
            let startImage = DrawImages.getStartImage(CGSize(width: 20, height: 20))
//            if game.multiPlay {
//                gameArt = GV.language.getText(.tcCompetitionShort)
//                opponent = game.opponentName
//                score += " / " + String(game.opponentScore)
//                if game.playerScore < game.opponentScore {
//                    victory = SKTexture(image:DrawImages.getNOKImage(CGSize(width: 20, height: 20)))
//                }
//            }
            let elements: [MultiVar] = [MultiVar(string: "#\(game.gameNumber + 1)"),
//                                        MultiVar(string: gameArt),
//                                        MultiVar(string: opponent),
                                        MultiVar(string: score),
                                        MultiVar(string: game.time.HourMin),
//                                        MultiVar(texture: victory, textureSize: textureSize),
                                        MultiVar(texture: SKTexture(image: startImage)),
                                        ]
            tableOfRows.append(RowOfTable(elements: elements, selected: true))
//            showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: row)
            gameNumbers[row] = game.gameNumber
            row += 1
        }
        showTable()
        
    }
    
//    func convertNameWhenRequired(_ name: String)->String {
//        if name == GV.language.getText(.tcAnonym) {
//            return GV.language.getText(.tcGuest)
//        }
//        return name
//    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.location(in: self)
//        touchesBeganAtNode = atPoint(touchLocation)
//        lastLocation = touches.first!.location(in: GV.mainViewController!.view)
//        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != self.name)) {
//            touchesBeganAtNode = nil
//        }
//    }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let actLocation = touches.first!.location(in: GV.mainViewController!.view)
//        let delta:CGFloat = lastLocation.y - actLocation.y
//        lastLocation = actLocation
//        scrollView(delta)
//    }
    
    override func ownTouchesEnded(row: Int, column: Int, element: Int) {
        switch (row, column) {
        case (0, 0):
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack(false, 0, 0)
        case (2..<10000, myGameColumnWidths.count - 1):
            callBack(true, gameNumbers[row - 1]!, levelID)
        default:
            break
        }
        
    }
    
    func showDetailedPlayerStatistic(_ row: Int) {
        //        let countLevelLines = Int(LevelsForPlayWithCards().count() + 1)
        
    }
    
//    override func setMyDeviceSpecialConstants() {
//        fontSize = GV.onIpad ? 20 : 15
//    }
    
    
}


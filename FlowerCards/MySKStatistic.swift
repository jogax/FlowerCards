//
//  MySKStatistic.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 05/05/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//


import SpriteKit
import RealmSwift

class MySKStatistic: MySKTable {
    
    var callBack: (Bool, Int, Int, Int)->()
    var nameTable = [PlayerModel]()
    let myColumnWidths: [CGFloat] = [15, 13, 20, 25, 17, 10]  // in %
//    let myName = "MySKPlayerStatistic"

    
    
    
    init(parent: SKSpriteNode, callBack: @escaping (Bool, Int, Int, Int)->()) {
        nameTable = Array(realm.objects(PlayerModel.self).sorted(byKeyPath: "created", ascending: true))
        var countLines = nameTable.count
        if countLines == 1 {
            countLines += 1
        }
        
        self.callBack = callBack
        
        super.init(columnWidths: myColumnWidths, countRows:countLines, headLines: [""], parent: parent, myName: "MySKStatistic", width: parent.parent!.frame.width * 0.9)
        self.showVerticalLines = true
        
        
        showMe(showPlayerStatistic)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showPlayerStatistic() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcPlayer)),
                                    MultiVar(string: GV.language.getText(.tcCountPlays)),
                                    MultiVar(string: GV.language.getText(.tcCountCompetitions)),
                                    MultiVar(string: GV.language.getText(.tcCountVictorys)),
                                    MultiVar(string: GV.language.getText(.tcAllTime)),
                                   ]
        showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: 0)
        for row in 0..<nameTable.count {
            if nameTable[row].name != GV.language.getText(.tcAnonym) || row == 0 {
//                let statisticTable = realm.objects(StatisticModel.self).filter("playerID = %d", nameTable[row].ID)
                let gamesForPlayer = realm.objects(GameModel.self).filter("playerID = %d and played = true", nameTable[row].ID)
                let allTime:Int = gamesForPlayer.sum(ofProperty: "time")
                let countPlays = gamesForPlayer.filter("ID != %d",GV.actGame!.ID).count
                let countMultiPlays = gamesForPlayer.filter("multiPlay = true").count
                let countVictorys = gamesForPlayer.filter("playerScore >= opponentScore and gameFinished = true").count
                let countDefeats = gamesForPlayer.filter("playerScore < opponentScore").count
//                for index in 0..<statisticTable.count {
//                    allTime += statisticTable[index].allTime
//                    countMultiPlays += statisticTable[index].countMultiPlays
//                    countVictorys += statisticTable[index].victorys
//                    countDefeats += statisticTable[index].defeats
//                }
//                countPlays = realm.objects(GameModel.self).filter("playerID = %d and ID != %d", nameTable[row].ID, GV.actGame!.ID).count
                let elements: [MultiVar] = [MultiVar(string: convertNameWhenRequired(nameTable[row].name)),
                                            MultiVar(string: "\(countPlays)"),
                                            MultiVar(string: "\(countMultiPlays)"),
                                            MultiVar(string: "\(countVictorys) / \(countDefeats)"),
                                            MultiVar(string: allTime.HourMin),
                                            MultiVar(texture: SKTexture(image: DrawImages.getGoForwardImage(CGSize(width: 20, height: 20))))
                ]
                showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row: row + 1)
            }
        }
    }
    
    func convertNameWhenRequired(_ name: String)->String {
        if name == GV.language.getText(.tcAnonym) {
            return GV.language.getText(.tcGuest)
        }
        return name
    }
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let (_, row, column, _) = checkTouches(touches, withEvent: event)
    override func ownTouchesEnded(row: Int, column: Int, element: Int) {
        switch (row, column) {
        case (0, 0):
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack(false, 0, 0, 0)
        case (2..<10000, myColumnWidths.count - 1):
            self.isUserInteractionEnabled = false
            addDetailedPlayerStatistic(row - 2)
        default:
            break
        }
        
    }
    
    func addDetailedPlayerStatistic(_ row: Int) {
        let playerID = nameTable[row].ID
        _ = MySKDetailedStatistic(playerID: playerID, parent: self, callBack: backFromMySKDetailedStatistic)
        
    }
    
    func backFromMySKDetailedStatistic(_ startGame: Bool, gameNumber: Int, levelIndex: Int, countPackages: Int) {
        self.isUserInteractionEnabled = true
        callBack(startGame, gameNumber, levelIndex, countPackages)
    }
//    override func setMyDeviceSpecialConstants() {
//        fontSize = GV.onIpad ? 20 : 15
//    }

    
}


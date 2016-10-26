//
//  LevelsForPlayWithCards.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 12. 28..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//

import SpriteKit


class LevelsForPlayWithCards {

    /*
    enum LevelParamsType: Int {
        CountPackages = 0,
        CountColumns = 1,
        CountRows = 2,
        MinProzent = 3,
        MaxProzent = 4,
        SpriteSize = 5,
        ScoreFactor = 6
        ScoreTime = 7
    }
    */
    var CardPlay = false
    var level: Int
    var aktLevel: LevelParam
    fileprivate var levelContent = [
        1: "1,4,4,40,60,40",
        2: "2,4,4,40,60,40",
        3: "3,4,4,40,60,40",
        4: "1,5,5,40,60,35",
        5: "2,5,5,40,60,35",
        6: "3,5,5,40,60,35",
        7: "1,6,6,40,60,32",
        8: "2,6,6,40,60,32",
        9: "3,6,6,40,60,32",
       10: "1,7,7,40,60,31",
       11: "2,7,7,40,60,31",
       12: "3,7,7,40,60,31",
       13: "1,8,8,50,60,28",
       14: "2,8,8,50,60,28",
       15: "3,8,8,50,60,28",
       16: "1,9,9,80,100,25",
       17: "2,9,9,80,100,25",
       18: "3,9,9,80,100,25",
       19: "1,10,10,80,100,22",
       20: "2,10,10,80,100,22",
       21: "3,10,10,80,100,22",
    ]
    var levelParam = [LevelParam]()
    
    init () {
        level = 0
        
        //let sizeMultiplier: CGFloat = 1.0 //UIDevice.currentDevice().modelConstants[GV.deviceType] //GV.onIpad ? 1.0 : 0.6
        for index in 1..<levelContent.count + 1 {
            let paramString = levelContent[index]
            let paramArr = paramString!.components(separatedBy: ",")
            var aktLevelParam: LevelParam = LevelParam()
            aktLevelParam.countContainers = 4
            aktLevelParam.countPackages = Int(paramArr[0])!
            aktLevelParam.countColumns = Int(paramArr[1])!
            aktLevelParam.countRows = Int(paramArr[2])!
            aktLevelParam.minProzent = Int(paramArr[3])!
            aktLevelParam.maxProzent = Int(paramArr[4])!
            aktLevelParam.spriteSize = Int(paramArr[5])!
            levelParam.append(aktLevelParam)
        }
        aktLevel = levelParam[0]
    }
    
    func setAktLevel(_ level: Int) {
        if !level.between(0, max: levelContent.count - 1) {
            self.level = 0
        } else {
            self.level = level
        }
        aktLevel = levelParam[self.level]
        
    }
    
    func getNextLevel() -> Int {
        if level < levelParam.count {
            level += 1
        }
        aktLevel = levelParam[level]
        return level
    }
    func getPrevLevel() -> Int {
        if level > 0 {
            level -= 1
        }
        aktLevel = levelParam[level]
        return level
    }
    
    func count()->Int {
        return levelContent.count
    }
    
    func getLastLevelWithColumnCount(maxColumnCount: Int)->Int {
        var index = 0
        while index < levelParam.count {
            if levelParam[index].countColumns > maxColumnCount - 1 {
                break
            }
            index += 1
        }
        return index
    }
    
}

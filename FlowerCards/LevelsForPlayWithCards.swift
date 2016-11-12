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

        CountColumns = 1,
        CountRows = 2,
        MinProzent = 3,
        MaxProzent = 4,
        SpriteSize = 5,
    }
    */
    var CardPlay = false
    var level: Int
    var aktLevel: LevelParam
    
    #if REALM_V1
    fileprivate var levelContent = [
        
        "3,3,40,60,40",
        "3,4,40,60,40",
        "3,5,40,60,40",
        "3,6,40,60,40",
        
        "4,4,40,60,40",  // old 0 new 4
        
        "4,5,40,60,40",
        "4,6,40,60,32",
        "4,7,40,60,32",
        
        "5,5,40,60,35",  // old 1 new 8
        "5,6,40,60,33",
        "5,7,40,60,33",
        "5,8,40,60,33",
        
        "6,6,40,60,33", // old 2 new 12
        "6,7,40,60,33",
        "6,8,40,60,33",
        
        "7,7,40,60,30", // old 3 new 15
        "7,8,40,60,30",
        "7,9,40,60,30",
        
        "8,8,50,60,28", // old 4 new 18
        "8,9,50,60,28",
        "8,10,50,60,28",
        
        "9,9,80,100,25", // old 5 new 21
        "9,10,80,100,25",
        
        "10,10,80,100,25", // old 6 new 23
    ]
    #else
        fileprivate var levelContent = [
        
        "4,4,40,60,40",   // old 0 new 4
        "5,5,40,60,35",   // old 1 new 8
        "6,6,40,60,33",   // old 2 new 12
        "7,7,40,60,30",   // old 3 new 15
        "8,8,50,60,28",   // old 4 new 18
        "9,9,80,100,25",  // old 5 new 21
        "10,10,80,100,25",// old 6 new 23
        ]
    #endif
    
    var levelParam = [LevelParam]()
    
    init () {
        level = 0
        
        //let sizeMultiplier: CGFloat = 1.0 //UIDevice.currentDevice().modelConstants[GV.deviceType] //GV.onIpad ? 1.0 : 0.6
        for index in 0..<levelContent.count {
            let paramString = levelContent[index]
            let paramArr = paramString.components(separatedBy: ",")
            var aktLevelParam: LevelParam = LevelParam()
            aktLevelParam.countColumns = Int(paramArr[0])!
            aktLevelParam.countRows = Int(paramArr[1])!
            aktLevelParam.minProzent = Int(paramArr[2])!
            aktLevelParam.maxProzent = Int(paramArr[3])!
            aktLevelParam.spriteSize = Int(paramArr[4])!
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
    
    func getLevelFormat(level: Int)->String {
        return "\(levelParam[level].countColumns) * \(levelParam[level].countRows)"
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

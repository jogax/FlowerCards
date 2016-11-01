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
        OnlyiPad   = 6
    }
    */
    var CardPlay = false
    var level: Int
    var aktLevel: LevelParam
    fileprivate var levelContent = [
        
         "1,3,3,40,60,40",
         "1,3,4,40,60,40",
         "1,3,5,40,60,40",
         
         "1,4,4,40,60,40",
         "1,4,5,40,60,40",
         "1,4,6,40,60,32",
         
         "1,5,5,40,60,35",
         "1,5,6,40,60,33",
         "1,5,7,40,60,33",

         "1,6,6,40,60,33",
         "1,6,7,40,60,33",
         "1,6,8,40,60,33",
         
         "1,7,7,40,60,30",
         "1,7,8,40,60,30",
         "1,7,9,40,60,30",

         "1,8,8,50,60,28",
         "1,8,9,50,60,28",
         "1,8,10,50,60,28",

         "1,9,9,80,100,25",
         "1,9,10,80,100,25",

         "1,10,10,80,100,25",
    ]
    
    var levelParam = [LevelParam]()
    
    init () {
        level = 0
        
        //let sizeMultiplier: CGFloat = 1.0 //UIDevice.currentDevice().modelConstants[GV.deviceType] //GV.onIpad ? 1.0 : 0.6
        for index in 0..<levelContent.count {
            let paramString = levelContent[index]
            let paramArr = paramString.components(separatedBy: ",")
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

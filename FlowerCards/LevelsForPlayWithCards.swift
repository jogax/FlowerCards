//
//  LevelsForPlayWithCards.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 12. 28..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//

import SpriteKit

struct LevelParam {
    
//    #if REALM_V1
    var countPackages: Int
//    #endif
    var countColumns: Int
    var countRows: Int
    var minProzent: Int
    var maxProzent: Int
    var cardSize: Int
    
    init()
    {
//        #if REALM_V1
            countPackages = 0
//        #endif
        self.countColumns = 0
        self.countRows = 0
        self.minProzent = 0
        self.maxProzent = 0
        self.cardSize = 0
    }
    
}


class LevelsForPlayWithCards {

    /*
    enum LevelParamsType: Int {

        CountColumns = 1,
        CountRows = 2,
        MinProzent = 3,
        MaxProzent = 4,
        CardSize = 5,
    }
    */
    var CardPlay = false
    var level: Int
    var aktLevel: LevelParam
//    let maxCountPackages = 4
    let maxCountPackages = 2
    
//    #if REALM_V1
    fileprivate var levelContent = [
        
        "3,3,25,50,40",
        "3,4,25,50,40",
        "3,5,40,60,35",
        "3,6,40,60,35",
        
        "4,4,40,60,35",  // old 0 new 4
        "4,5,40,60,35",
        "4,6,40,60,32",
        "4,7,40,60,32",
        
        "5,5,40,60,32",  // old 1 new 8
        "5,6,40,60,32",
        "5,7,40,60,30",
        "5,8,40,60,30",
        
        "6,6,40,60,30", // old 2 new 12
        "6,7,40,60,30",
        "6,8,40,60,24",
        "6,9,40,60,24",
        
        "7,7,40,60,28", // old 3 new 15
        "7,8,40,60,28",
        "7,9,40,60,24",
        "7,10,40,60,22",
        
        "8,8,50,60,24", // old 4 new 18
        "8,9,50,60,24",
        "8,10,50,60,22",
        
        "9,9,60,80,24", // old 5 new 21
        "9,10,60,80,22",
        
        "10,10,60,80,22", // old 6 new 23
    ]
//    #else
//        fileprivate var levelContent = [
//        
//        "4,4,40,60,40",   // old 0 new 4
//        "5,5,40,60,35",   // old 1 new 8
//        "6,6,40,60,33",   // old 2 new 12
//        "7,7,40,60,30",   // old 3 new 15
//        "8,8,50,60,28",   // old 4 new 18
//        "9,9,80,100,25",  // old 5 new 21
//        "10,10,80,100,25",// old 6 new 23
//        ]
//    #endif
    
    var levelParam = [LevelParam]()
    
    init () {
        level = 0
        
        //let sizeMultiplier: CGFloat = 1.0 //UIDevice.currentDevice().modelConstants[GV.deviceType] //GV.onIpad ? 1.0 : 0.6
//        #if REALM_V1
            for index in 0..<levelContent.count {
                for countPackages in 1...maxCountPackages {
                    let paramString = levelContent[index]
                    let paramArr = paramString.components(separatedBy: ",")
                    var aktLevelParam: LevelParam = LevelParam()
                    aktLevelParam.countPackages = countPackages
                    aktLevelParam.countColumns = Int(paramArr[0])!
                    aktLevelParam.countRows = Int(paramArr[1])!
                    aktLevelParam.minProzent = Int(paramArr[2])!
                    aktLevelParam.maxProzent = Int(paramArr[3])!
                    aktLevelParam.cardSize = Int(paramArr[4])!
                    levelParam.append(aktLevelParam)
                }
            }
//        #else
//            for index in 0..<levelContent.count {
//                let paramString = levelContent[index]
//                let paramArr = paramString.components(separatedBy: ",")
//                var aktLevelParam: LevelParam = LevelParam()
//                aktLevelParam.countColumns = Int(paramArr[0])!
//                aktLevelParam.countRows = Int(paramArr[1])!
//                aktLevelParam.minProzent = Int(paramArr[2])!
//                aktLevelParam.maxProzent = Int(paramArr[3])!
//                aktLevelParam.cardSize = Int(paramArr[4])!
//                levelParam.append(aktLevelParam)
//            }
//        #endif
        aktLevel = levelParam[0]
    }
    
    func setAktLevel(_ level: Int) {
        if !level.between(min: 0, max: levelParam.count - 1) {
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
        return levelParam.count
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

//
//  HighScoreModel.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 10/10/2017.
//Copyright © 2017 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class HighScoreModel: Object {
    @objc dynamic var ID = 0
    @objc dynamic var levelID = 0
    @objc dynamic var countPackages = 0
    @objc dynamic var myRank = 0
    @objc dynamic var myHighScore = 0
    @objc dynamic var sentToGameCenter = false
    @objc dynamic var bestPlayerName = ""
    @objc dynamic var bestPlayerHighScore = 0
    @objc dynamic var created = Date()
    
    override  class func primaryKey() -> String {
        return "ID"
    }
}

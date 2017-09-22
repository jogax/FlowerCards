//
//  GameToPlayerModel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 02/06/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class GameModel: Object {
    @objc dynamic var ID = 0
    @objc dynamic var playerID = 0
    @objc dynamic var levelID = 0
    @objc dynamic var countPackages = 0
    @objc dynamic var gameNumber = 0
    @objc dynamic var played = false
    @objc dynamic var countSteps = 0
    @objc dynamic var gameFinished = false
    @objc dynamic var time = 0
    @objc dynamic var playerScore = 0
    @objc dynamic var multiPlay = false
    @objc dynamic var opponentName = ""
    @objc dynamic var opponentScore = 0
    @objc dynamic var created = Date()

    override  class func primaryKey() -> String {
        return "ID"
    }
}

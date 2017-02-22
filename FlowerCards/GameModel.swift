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
    dynamic var ID = 0
    dynamic var playerID = 0
    dynamic var gameNumber = 0
    dynamic var levelID = 0
    dynamic var played = false
    dynamic var countSteps = 0 // new in v1
    dynamic var packages = 0  // new in v1

    #if REALM_V2
        dynamic var gameFinished = false // new in V2
    #endif
    dynamic var time = 0
    dynamic var playerScore = 0
    dynamic var multiPlay = false
    dynamic var opponentName = ""
    dynamic var opponentScore = 0
    dynamic var created = Date()

    override  class func primaryKey() -> String {
        return "ID"
    }
}

//
//  PlayerModel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 29/03/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

let startingLevel = 16
class PlayerModel: Object {
    @objc dynamic var ID = 0
    @objc dynamic var name = ""
    @objc dynamic var levelID = startingLevel
    @objc dynamic var countPackages = 1
    @objc dynamic var isActPlayer = false
    @objc dynamic var aktLanguageKey = GV.language.getAktLanguageKey()
    @objc dynamic var soundVolume: Float = 0
    @objc dynamic var musicVolume: Float = 0
    @objc dynamic var created = Date()
    @objc dynamic var GCEnabled = 0 // 0 - ask, 1 - enabled, 2 - supressed
    @objc dynamic var onlineCompetitionEnabled = true

    override  class func primaryKey() -> String {
        return "ID"
    }

    
}

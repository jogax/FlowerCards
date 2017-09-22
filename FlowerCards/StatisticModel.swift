//
//  StatisticModel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 30/03/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class StatisticModel: Object {

    @objc dynamic var ID = 0
    @objc dynamic var playerID = 0
    @objc dynamic var levelID = 0
    @objc dynamic var countPackages = 0
    @objc dynamic var actScore = 0
    @objc dynamic var actTime = 0
    @objc dynamic var allTime = 0
    @objc dynamic var bestScore = 0
    @objc dynamic var bestTime = 0
    @objc dynamic var countPlays = 0
    @objc dynamic var countMultiPlays = 0
    @objc dynamic var victorys = 0
    @objc dynamic var defeats = 0
    @objc dynamic var levelScore = 0
    @objc dynamic var created = Date()

    override  class func primaryKey() -> String {
        return "ID"
    }
    
}

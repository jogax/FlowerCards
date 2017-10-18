//
//  RecordIDModel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 03/06/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class RecordIDModel: Object {
    
    @objc dynamic var ID = 0
    @objc dynamic var gameModelID = 0
    @objc dynamic var playerModelID = 0
    @objc dynamic var statisticModelID = 0
    @objc dynamic var highScoreModelID = 0
    override  class func primaryKey() -> String {
        return "ID"
    }
    
    
}


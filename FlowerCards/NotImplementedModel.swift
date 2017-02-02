//
//  NoImplementedModel.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 02/02/2017.
//  Copyright © 2017 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class NotImplementedModel: Object {
    
    dynamic var ID = 0
    dynamic var switchValue = ""
    dynamic var implemented = false
    dynamic var cardPrintValue = ""
    dynamic var card1PrintValue = ""
    dynamic var levelID = 0
    dynamic var gameNumber = 0
    dynamic var created = Date()
    
    override  class func primaryKey() -> String {
        return "ID"
    }
    
}

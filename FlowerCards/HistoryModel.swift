//
//  GameHistoryModel.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 21/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

#if REALM_V2
import Foundation
import RealmSwift

class HistoryModel: Object {
    
    dynamic var ID = 0
    dynamic var gameID = 0
    dynamic var recordNr = 0
    dynamic var colorIndex = 0
//===========================================
    dynamic var fromColumn = 0
    dynamic var fromRow = 0
    dynamic var fromMinValue = 0
    dynamic var fromMaxValue = 0
//===========================================
    dynamic var toColumn = 0
    dynamic var toRow = 0
    dynamic var toMinValue = 0
    dynamic var toMaxValue = 0
    
    var points = List<PointModel>()
    
    dynamic var created = Date()
    
    override  class func primaryKey() -> String {
        return "ID"
    }
}
#endif

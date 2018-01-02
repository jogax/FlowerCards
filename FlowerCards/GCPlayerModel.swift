//
//  GCPlayerModel.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 14/12/2017.
//Copyright © 2017 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import RealmSwift

class GCPlayerModel: Object {
    
    @objc dynamic var playerID = ""
    @objc dynamic var name = ""
    @objc dynamic var isMyFriend = false
    @objc dynamic var created = Date()

    override  class func primaryKey() -> String {
        return "playerID"
    }
}


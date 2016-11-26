//
//  FlowerCardsTests.swift
//  FlowerCardsTests
//
//  Created by Jozsef Romhanyi on 14/11/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import XCTest
@testable import FlowerCards
import SpriteKit

class FlowerCardsTests: XCTestCase {
    
    let scene = SKScene()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_startAutoPlay() {
        let autoPlayer = AutoPlayer()
        autoPlayer.play(gameNumber: 1)
        
    }
}

//
//  Stack.swift
//  JLines
//
//  Created by Jozsef Romhanyi on 27.08.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//


enum StackType: Int {
    case saveSpriteType = 0, mySKNodeType
}
class Stack<T> {
    fileprivate var savedSpriteStack: Array<SavedSprite>
    fileprivate var cardStack: Array<MySKNode>
    var lastRandomIndex = -1
    
    init() {
        savedSpriteStack = Array<SavedSprite>()
        cardStack = Array<MySKNode>()
    }
    
    func push (_ value: SavedSprite) {
        savedSpriteStack.append(value)
    }
    
    func push (_ value: MySKNode) {
        cardStack.append(value)
    }

    func pushLast (_ value: MySKNode) {
        cardStack.insert(value, at: 0)
    }

    func count(_ type: StackType)->Int {
        switch type {
            case .mySKNodeType: return cardStack.count
            case .saveSpriteType: return savedSpriteStack.count
        }
    }
    
    func pull () -> SavedSprite? {

        if savedSpriteStack.count > 0 {
            let value = savedSpriteStack.last
            savedSpriteStack.removeLast()
            return value!
        } else {
            return nil
        }
    }
    
    func pull () -> MySKNode? {        
        if cardStack.count > 0 {
            let value = cardStack.last
            cardStack.removeLast()
            return value!
        } else {
            return nil
        }
    }
    
    func last() -> MySKNode? {
        if cardStack.count > 0 {
            let value = cardStack.last
            return value!
        } else {
            return nil
        }
    }
    
    func random(_ random: MyRandom?)->MySKNode? {
        lastRandomIndex = random!.getRandomInt(0, max: cardStack.count - 1)
        return cardStack[lastRandomIndex]
    }
    
    func removeAtLastRandomIndex() {
        if lastRandomIndex >= 0 {
            cardStack.remove(at: lastRandomIndex)
            lastRandomIndex = -1
        }
    }
    
    func countChangesInStack() -> Int {
        var counter = 0
        for index in 0..<savedSpriteStack.count {
            if !(savedSpriteStack[index].status == .added || savedSpriteStack[index].status == .addedFromCardStack) {counter += 1}
        }
        return counter
    }
    
    func removeAll(_ type: StackType) {
        switch type {
            case .mySKNodeType: cardStack.removeAll(keepingCapacity: false)
            case .saveSpriteType: savedSpriteStack.removeAll(keepingCapacity: false)
        }
    }
}

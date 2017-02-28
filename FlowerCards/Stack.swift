//
//  Stack.swift
//  JLines
//
//  Created by Jozsef Romhanyi on 27.08.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//


enum StackType: Int {
    case SavedCardType = 0, MySKCardType
}
class Stack<T> {
    fileprivate var savedCardStack: Array<SavedCard>
    fileprivate var cardStack: Array<MySKCard>
    private var lastRandomIndex = -1
    private var colorCounts:[Int] = []
    
    init() {
        savedCardStack = Array<SavedCard>()
        cardStack = Array<MySKCard>()
        for _ in 0...MaxColorValue {
            colorCounts.append(0)
        }
    }
    
    func push (card: SavedCard) {
        savedCardStack.append(card)
    }
    
    func push (card: MySKCard) {
        cardStack.append(card)
        colorCounts[card.colorIndex] += 1
    }

    func pushLast (card: MySKCard) {
        cardStack.insert(card, at: 0)
        colorCounts[card.colorIndex] += 1
    }

    func count(type: StackType)->Int {
        switch type {
            case .MySKCardType: return cardStack.count
            case .SavedCardType: return savedCardStack.count
        }
    }
    
    func count(color: Int)->Int {
        return colorCounts[color]
    }
    
    func pull () -> SavedCard? {

        if savedCardStack.count > 0 {
            let value = savedCardStack.last
            savedCardStack.removeLast()
            return value!
        } else {
            return nil
        }
    }
    
    func pull () -> MySKCard? {        
        if let card = cardStack.last {
            cardStack.removeLast()
            colorCounts[card.colorIndex] -= 1
            return card
        } else {
            return nil
        }
    }
    
    func pull (color: Int) -> MySKCard? {
        if cardStack.count > 0 {
            for index in 0..<cardStack.count {
                if cardStack[index].colorIndex == color {
                    let card = cardStack[index]
                    cardStack.remove(at: index)
                    colorCounts[color] -= 1
                    return card
                }
            }
        }
        return nil
    }
    
    func get (index: Int)-> MySKCard {
        return cardStack[index]
    }
    
    func last() -> MySKCard? {
        if cardStack.count > 0 {
            let value = cardStack.last
            return value!
        } else {
            return nil
        }
    }
    
    func random(_ random: MyRandom?)->MySKCard? {
        lastRandomIndex = random!.getRandomInt(0, max: cardStack.count - 1)
        return cardStack[lastRandomIndex]
    }
    
    func search(colorIndex: Int, value: Int)->MySKCard? {
        var returnCard: MySKCard?
        for (index, card) in cardStack.enumerated() {
            if card.minValue == value && card.colorIndex == colorIndex {
                returnCard = card
                cardStack.remove(at: index)
                colorCounts[colorIndex] -= 1
                return returnCard
            }
        }
        return nil
    }
    
    func removeAtLastRandomIndex() {
        if lastRandomIndex >= 0 {
            cardStack.remove(at: lastRandomIndex)
            lastRandomIndex = -1
        }
    }
    
    func countChangesInStack() -> Int {
        var counter = 0
        for index in 0..<savedCardStack.count {
            if !(savedCardStack[index].status == .added || savedCardStack[index].status == .addedFromCardStack) {counter += 1}
        }
        return counter
    }
    
    func removeAll(_ type: StackType) {
        switch type {
            case .MySKCardType: cardStack.removeAll(keepingCapacity: false)
            case .SavedCardType: savedCardStack.removeAll(keepingCapacity: false)
        }
    }
}

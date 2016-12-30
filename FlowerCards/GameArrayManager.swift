//
//  GameArrayManager.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 30/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

// for managing of connectibility of gameArray members
class GameArrayManager {
    struct DataForColor {
        var container: MySKCard?
        var allCards: [MySKCard]
        init() {
            allCards = []
        }
    }
    private let colorNames = ["Purple", "Blue", "Green", "Red"]
    private let purple = 0
    private let blue = 1
    private let green = 2
    private let red = 3
    private var colorArray: [DataForColor] = []
    private var allPackages: UInt8 = 0
    private var maxPackage: UInt8 = 0
    private var minPackage: UInt8 = 0
    private let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]

    init () {
        for _ in 1...4 {
            colorArray.append(DataForColor())
        }
        allPackages = 0
        for packageNr in 0..<countPackages {
            self.allPackages += bitMaskForPackages[packageNr]
        }
        maxPackage = bitMaskForPackages[countPackages - 1]
        minPackage = bitMaskForPackages[0]


    }
    func addCard(card: MySKCard) {
        colorArray[card.colorIndex].allCards.append(card)
//        print("after add allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[card.colorIndex].allCards.count)")
        analyzeColor(data: colorArray[card.colorIndex])
    }
    
    func moveCard(card: MySKCard, toCard: MySKCard) {
        deleteCard(card: card)
        if toCard.type == .containerType {
            if colorArray[toCard.colorIndex].container == nil {
                colorArray[toCard.colorIndex].container = toCard
            }
        }
        if toCard.countTransitions > 0 {
            
        }
//        print("after move allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[toCard.colorIndex].allCards.count)")
        analyzeColor(data: colorArray[card.colorIndex])
    }
    
    func removeCard(card: MySKCard) {
        deleteCard(card: card)
//        print("after remove allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[card.colorIndex].allCards.count)")
        analyzeColor(data: colorArray[card.colorIndex])
    }
    
    private func deleteCard(card: MySKCard) {
        for (index, cardInCycle) in colorArray[card.colorIndex].allCards.enumerated() {
            if card.column == cardInCycle.column && card.row == cardInCycle.row {
                colorArray[card.colorIndex].allCards.remove(at: index)
                break
            }
        }
    }
    
    private func analyzeColor(data: DataForColor) {
        var containerValues: [Int] = []
        var cardsWithTransition: [MySKCard] = []
        var countTransitions  = 0

        if data.container != nil {
            containerValues = findCardValues(card: data.container!)
        }
        if containerValues.count > 0 {
            for card in data.allCards {
                if containerValues.contains(card.minValue) || containerValues.contains(card.maxValue) {
                    card.belongsToPackageMax &= ~maxPackage & allPackages
                }
            }
        }
        for card in data.allCards {
            if card.countTransitions > 0 {
                cardsWithTransition.append(card)
                countTransitions += card.countTransitions
            }
        }
        if countTransitions == countPackages - 1 {
            var cardValues: [[Int]] = []
            var countValueCounts: [Int] = Array(repeating: 0, count: 13)
            for card in cardsWithTransition {
                cardValues.append(findCardValues(card: card))
            }
            for index in 0..<cardValues.count {
                for ind in 0..<cardValues[index].count {
                    let actValue = cardValues[index][ind]
                    countValueCounts[actValue] += 1
                }
            }
            for card in data.allCards {
                if card.countTransitions == 0 {
                    if countValueCounts[card.minValue] == countTransitions {
                        card.belongsToPackageMin = minPackage
                    }
                }
            }
        }
    }
    
    private func findCardValues(card: MySKCard)->[Int] {
        var cardValues: [Int] = []
        var value = card.minValue
        var countValues = 0
        if card.countTransitions == 0 {
            countValues = card.maxValue - card.minValue + 1
        } else {
            countValues = card.maxValue + MaxCardValue - card.minValue + 1 + (MaxCardValue * (card.countTransitions - 1))
        }
        for _ in 0..<countValues {
            cardValues.append(value)
            value += 1
            if value > LastCardValue {
                value = 0
            }
        }
        return cardValues
    }

}

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
class CardManager {
    
    struct ConnectablePair {
        var card1: MySKCard
        var card2: MySKCard
        func convertCard(card: MySKCard)->String {
            return "\(card.countTransitions)-\(card.minValue)-\(card.maxValue)-\(card.column)-\(card.row)-\(card.type)"
        }
        var printValue: String {
            get {
                let value = "\(card1.printValue) - \(card2.printValue)"
                return value
            }
        }
        var hashValue : String {
            get {
                return  convertCard(card: card1) + "-" + convertCard(card: card2)
            }
        }
        var hashValue1 : String {
            get {
                return convertCard(card: card2) + "-" + convertCard(card: card1)
            }
        }
        static func ==(left: ConnectablePair, right: ConnectablePair) -> Bool {
            return left.hashValue == right.hashValue || left.hashValue == right.hashValue1
        }

    }

    struct DataForColor {
        var colorIndex: Int
        var container: MySKCard?
        var allCards: [MySKCard]
        var cardsWithTransitions: [MySKCard]
        var connectablePairs: [ConnectablePair] = []
        var countTransitions = 0
        init(colorIndex: Int) {
            allCards = []
            cardsWithTransitions = []
            connectablePairs = []
            self.colorIndex = colorIndex
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
            colorArray.append(DataForColor(colorIndex: colorArray.count))
        }
        allPackages = 0
        for packageNr in 0..<countPackages {
            self.allPackages += bitMaskForPackages[packageNr]
        }
        maxPackage = bitMaskForPackages[countPackages - 1]
        minPackage = bitMaskForPackages[0]


    }
//    func addCard(card: MySKCard) {
//        colorArray[card.colorIndex].allCards.append(card)
////        print("after add allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[card.colorIndex].allCards.count)")
//        analyzeColor(data: &colorArray[card.colorIndex])
//    }
//    
//    func moveCard(card: MySKCard, toCard: MySKCard) {
//        deleteCard(card: card)
//        if toCard.type == .containerType {
//            if colorArray[toCard.colorIndex].container == nil {
//                colorArray[toCard.colorIndex].container = toCard
//            }
//        }
//        if toCard.countTransitions > 0 {
//            
//        }
////        print("after move allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[toCard.colorIndex].allCards.count)")
//        analyzeColor(data: &colorArray[card.colorIndex])
//    }
//    
//    func removeCard(card: MySKCard) {
//        deleteCard(card: card)
////        print("after remove allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[card.colorIndex].allCards.count)")
//        analyzeColor(data: &colorArray[card.colorIndex])
//    }
//    
    func check(card: MySKCard) {
        analyzeColor(data: &colorArray[card.colorIndex])
    }
    
    func areConnectable(first: MySKCard, second: MySKCard)->Bool {
        if first.colorIndex != second.colorIndex || first.colorIndex == NoColor {
            return false
        }
        let searchPair = ConnectablePair(card1: first, card2: second)
        var OK = false
        for pair in colorArray[first.colorIndex].connectablePairs {
            if pair == searchPair {
                OK = true
            }
        }
        let countTransitionsForColor = colorArray[first.colorIndex].countTransitions
        let OK1 = ((first.minValue == second.maxValue + 1 && first.belongsToPackageMin & second.belongsToPackageMax != 0 && second.type != .containerType) ||
            (first.maxValue == second.minValue - 1 && first.belongsToPackageMax & second.belongsToPackageMin != 0) ||
            (countPackages > 1 &&
                first.maxValue == LastCardValue &&
                second.minValue == FirstCardValue &&
                second.belongsToPackageMin & ~minPackage != 0 &&
                first.belongsToPackageMax & ~maxPackage != 0 &&
                first.countTransitions + second.countTransitions + 1 <= countPackages - 1) ||
            (countPackages > 1 &&
                first.minValue == FirstCardValue &&
                second.maxValue == LastCardValue &&
                first.belongsToPackageMin & ~minPackage != 0 &&
                second.belongsToPackageMax & ~maxPackage != 0 &&
                first.countTransitions + second.countTransitions + 1 <= countPackages - 1 &&
                countTransitionsForColor <= countPackages - 1 &&
                second.type != .containerType))
        if OK
        {
//            if !OK1 {
//                print ("calculated result (false) is false")
//            }
            return true
        }
//        if OK1 {
//            print ("calculated result (true) is false")
//        }
        
        return false
    }
    
//    private func deleteCard(card: MySKCard) {
//        for (index, cardInCycle) in colorArray[card.colorIndex].allCards.enumerated() {
//            if card.column == cardInCycle.column && card.row == cardInCycle.row {
//                colorArray[card.colorIndex].allCards.remove(at: index)
//                break
//            }
//        }
//    }
//    
    private func analyzeColor(data: inout DataForColor) {
        data.connectablePairs.removeAll()
        data.cardsWithTransitions.removeAll()
        data.countTransitions = 0
        func findContainer() {
            for container in containers {
                if container.colorIndex == data.colorIndex {
                    container.belongsToPackageMax = maxPackage
                    container.belongsToPackageMin = container.belongsToPackageMax >> UInt8(container.countTransitions)
                    data.container = container
                    data.countTransitions += container.countTransitions
                }
            }
        }
        func fillAllCards() {
            data.allCards.removeAll()
            for cardColumn in gameArray {
                for card in cardColumn {
                    if card.used && card.card.colorIndex == data.colorIndex {
                        data.allCards.append(card.card)
                        if card.card.countTransitions > 0 {
                            data.countTransitions += card.card.countTransitions
                            data.cardsWithTransitions.append(card.card)
                            card.card.belongsToPackageMax = allPackages & ~minPackage
                            card.card.belongsToPackageMin = allPackages & ~maxPackage
                        } else {
                            card.card.belongsToPackageMax = allPackages
                            card.card.belongsToPackageMin = allPackages
                        }
                    }
                }
            }
            
        }
        func findPair(card: MySKCard, startIndex: Int = -1) {
            if data.allCards.count > 0 {
                for index in startIndex + 1..<data.allCards.count {
                    let card1 = data.allCards[index]
//                    checkCardBelonging(data: &data, card: card1)
                    if card.minValue == card1.maxValue + 1 && card.belongsToPackageMin & card1.belongsToPackageMax != 0
                    ||
                        card.maxValue == card1.minValue - 1
                    ||
                        card.minValue == FirstCardValue &&
                        card1.maxValue == LastCardValue &&
                        card.belongsToPackageMin & ~minPackage != 0 &&
                        card1.belongsToPackageMax & ~maxPackage != 0
                    ||
                        card.maxValue == LastCardValue && card1.minValue == FirstCardValue && card1.belongsToPackageMax & ~minPackage != 0
                    ||
                        card.type == .containerType && card.colorIndex == NoValue && card1.maxValue == LastCardValue
                    {
                        var founded = false
                        let connectablePair = ConnectablePair(card1: card1, card2: card)
                        let searchPair = ConnectablePair(card1: card, card2: card1)
                        for foundedPair in data.connectablePairs {
                            if foundedPair == searchPair {
                                founded = true
                                break
                            }
                        }
                        if !founded {
                            data.connectablePairs.append(connectablePair)
                        }
                    }
                }
            }
        }
        func setOtherCardBelonging(cardWithTransition: MySKCard) {
            func findCardValues(card: MySKCard)->(upper:[Int], mid: [Int], lower: [Int]) {
                var upperValues: [Int] = []
                var midValues: [Int] = []
                var lowerValues: [Int] = []
                var value = card.maxValue
                var countUpperValues = 0
                var countMidValues = 0
                var countLowerValues = 0
                if card.countTransitions == 0 {
                    countUpperValues = card.maxValue - card.minValue + 1
                } else {
                    countUpperValues = card.maxValue + 1
                    countMidValues = (card.countTransitions - 1) * MaxCardValue
                    countLowerValues = LastCardValue - card.minValue + 1
                }
                for _ in 0..<countUpperValues {
                    upperValues.append(value)
                    value -= 1
                }
                value = LastCardValue
                for _ in 0..<countMidValues {
                    midValues.append(value)
                    value -= 1
                }
                value = LastCardValue
                for _ in 0..<countLowerValues {
                    lowerValues.append(value)
                    value -= 1
                }
                return (upper: upperValues, mid: midValues, lower: lowerValues)
            }
            let (upperValues, midValues, lowerValues) = findCardValues(card: cardWithTransition)
            for otherCard in data.allCards {
                if cardWithTransition != otherCard {
                    switch
                        (upperValues.contains(otherCard.maxValue),
                        upperValues.contains(otherCard.minValue),
                        data.countTransitions > 0,
                        lowerValues.contains(otherCard.maxValue),
                        lowerValues.contains(otherCard.minValue))
                    {
                    case (true, _, false, true, _):
                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    case (true, _, false, false, _):
                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3 
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    case (true, _, true, true, _):
                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    case (false, false, _, true, false):
                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMax
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    case (false, false, _, true, true):
                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMax
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)                        
                    case (false, true, _, false, _):
                        otherCard.belongsToPackageMin = allPackages & ~cardWithTransition.belongsToPackageMax
                        otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                    default:
                        break
                    }
//                    if otherCard.maxValue >= cardWithTransition.minValue {
//                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
//                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
//                    } else {
//                        otherCard.belongsToPackageMax = cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
//                        if otherCard.countTransitions > 0 {
//                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
//                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
//                        }
//                    }
                }
            }
            
        }
        

        findContainer()
        fillAllCards()
        
        if let container = data.container {
            // set the belongingsFlags by all other Cards
            setOtherCardBelonging(cardWithTransition: container)
//            for card in data.allCards {
//                if card.maxValue >= container.minValue {
//                    card.belongsToPackageMax = container.belongsToPackageMin >> 1 | container.belongsToPackageMin >> 2 | container.belongsToPackageMin >> 3
//                    card.belongsToPackageMin = card.belongsToPackageMax >> UInt8(card.countTransitions)
//                } else {
//                    card.belongsToPackageMax = container.belongsToPackageMin | container.belongsToPackageMin >> 1 | container.belongsToPackageMin >> 2 | container.belongsToPackageMin >> 3
//                    if card.countTransitions > 0 {
//                        card.belongsToPackageMin = card.belongsToPackageMax >> UInt8(card.countTransitions)
//                        card.belongsToPackageMax = card.belongsToPackageMin << UInt8(card.countTransitions)
//                    }
//                }
//            }
        }
        for card in data.cardsWithTransitions {
            setOtherCardBelonging(cardWithTransition: card)
        }

        if data.container != nil {
            findPair(card: data.container!)
        }
        for index in 0..<data.allCards.count {
            findPair(card: data.allCards[index], startIndex: index)
        }
        
        
        if data.allCards.count > 0 {
//            print("foundedPairs: \(data.connectablePairs.count) for color: \(colorNames[data.allCards[0].colorIndex])")
        }
    }
    
    
    
    
    private func checkCardBelonging(data: inout DataForColor, card: MySKCard) {
        for cardWithTransition in data.cardsWithTransitions {
            if cardWithTransition.maxValue <= card.minValue && data.countTransitions == countPackages - 1 {
                card.belongsToPackageMax = cardWithTransition.belongsToPackageMin
            }
        }
    }
    
//    private func analyzeColor(data: inout DataForColor) {
//        data.connectablePairs.removeAll()
//        data.countTransitions = 0
////        var containerValues: [Int] = []
//        var cardsWithTransition: [MySKCard] = []
//        for card in data.allCards {
//            card.belongsToPackageMin = allPackages
//            card.belongsToPackageMax = allPackages
//        }
//        
//        if data.container != nil {
//            data.countTransitions += data.container!.countTransitions
//            data.container?.belongsToPackageMax = maxPackage
//            for index in 0..<data.countTransitions {
//                data.container?.belongsToPackageMax |= maxPackage >> (UInt8(index))
//            }
//            data.container?.belongsToPackageMin = maxPackage >> UInt8((data.container!.countTransitions))
//            let (containerValuesH, _, containerValuesL) = findCardValues(card: data.container!)
//            for card in data.allCards {
//                let (cardValuesH, _, cardValuesL) = findCardValues(card: card)
//                if containerValuesH.contains(cardValuesH.first!) || containerValuesH.contains(cardValuesH.last!) {
//                    card.belongsToPackageMax &= allPackages & ~data.container!.belongsToPackageMax
//                }
//                if cardValuesL.count > 0 {
//                    if containerValuesL.contains(cardValuesL.first!) || containerValuesL.contains(cardValuesL.last!) {
//                        card.belongsToPackageMin &= allPackages & ~data.container!.belongsToPackageMin
//                    }
//                }
//            }
//
//        }
//        for card in data.allCards {
//            if card.countTransitions > 0 {
//                cardsWithTransition.append(card)
//                data.countTransitions += card.countTransitions
//            }
//        }
//        
//    }
    
    
    private func findCardValues(card: MySKCard)->([Int], [Int], [Int]) {
        var cardValuesAtLowerPackage: [Int] = []
        var cardValuesAtTheMid: [Int] = []
        var cardValuesAtHigherPackage: [Int] = []
        
        if card.countTransitions == 0 {
            for value in card.minValue...card.maxValue {
                cardValuesAtHigherPackage.append(value)
            }
        } else {
//            countValues = card.maxValue + MaxCardValue - card.minValue + 1 + (MaxCardValue * (card.countTransitions - 1))
            for value in 0...card.maxValue {
                cardValuesAtHigherPackage.append(value)
            }
            if card.countTransitions > 1 {
                for value in 0...LastCardValue {
                    cardValuesAtTheMid.append(value)
                }
            }
            for value in card.minValue...LastCardValue {
                cardValuesAtLowerPackage.append(value)
            }
        }
        return (cardValuesAtHigherPackage, cardValuesAtTheMid, cardValuesAtLowerPackage)
    }

}

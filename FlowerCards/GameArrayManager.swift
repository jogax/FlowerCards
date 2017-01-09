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
        var container: MySKCard?
        var allCards: [MySKCard]
        var connectablePairs: [ConnectablePair] = []
        var countTransitions = 0
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
        analyzeColor(data: &colorArray[card.colorIndex])
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
        analyzeColor(data: &colorArray[card.colorIndex])
    }
    
    func removeCard(card: MySKCard) {
        deleteCard(card: card)
//        print("after remove allCards.count: \(colorNames[card.colorIndex]) -> \(colorArray[card.colorIndex].allCards.count)")
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
        if OK1
        {
            if !OK {
                print ("calculated result (false) is false")
            }
            return true
        }
        if OK {
            print ("calculated result (true) is false")
        }
        
        return false
    }
    
    private func deleteCard(card: MySKCard) {
        for (index, cardInCycle) in colorArray[card.colorIndex].allCards.enumerated() {
            if card.column == cardInCycle.column && card.row == cardInCycle.row {
                colorArray[card.colorIndex].allCards.remove(at: index)
                break
            }
        }
    }
    
    private func analyzeColor(data: inout DataForColor) {
        data.connectablePairs.removeAll()
        data.countTransitions = 0
        for card in data.allCards {
            data.countTransitions += card.countTransitions
        }
        if let container = data.container {
            data.countTransitions += container.countTransitions
            container.belongsToPackageMax = maxPackage
            container.belongsToPackageMin = maxPackage >> UInt8(container.countTransitions)
            // set the belongingsFlags by all other Cards
            for card in data.allCards {
                if card.maxValue >= container.minValue {
                    card.belongsToPackageMax = container.belongsToPackageMin >> 1 | container.belongsToPackageMin >> 2 | container.belongsToPackageMin >> 3
                    card.belongsToPackageMin = card.belongsToPackageMax >> UInt8(card.countTransitions)
                } else {
                    card.belongsToPackageMax = container.belongsToPackageMin | container.belongsToPackageMin >> 1 | container.belongsToPackageMin >> 2 | container.belongsToPackageMin >> 3
                    card.belongsToPackageMin = card.belongsToPackageMax >> UInt8(card.countTransitions)
                }
            }
            findPair(data: &data, card: data.container!)
        }
        for index in 0..<data.allCards.count {
            findPair(data: &data, card: data.allCards[index], startIndex: index)
        }
        
        
        if data.allCards.count > 0 {
//            print("foundedPairs: \(data.connectablePairs.count) for color: \(colorNames[data.allCards[0].colorIndex])")
        }
    }
    
    private func findPair(data: inout DataForColor, card: MySKCard, startIndex: Int = 0) {
        if data.allCards.count > 0 {
            for index in startIndex + 1..<data.allCards.count {
                let card1 = data.allCards[index]
                if card.minValue == card1.maxValue + 1 || card.maxValue == card1.minValue - 1
                ||
                    card.minValue == FirstCardValue &&
                    card1.maxValue == LastCardValue &&
                    card.belongsToPackageMin & ~minPackage != 0 &&
                    card1.belongsToPackageMax & ~maxPackage != 0
                ||
                    card.maxValue == LastCardValue && card1.minValue == FirstCardValue ||
                    (card.type == .containerType && card.colorIndex == NoValue && card1.maxValue == LastCardValue) {
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

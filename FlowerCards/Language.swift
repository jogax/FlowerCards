//
//  Package.swift
//  JLinesV1
//
//  Created by Jozsef Romhanyi on 11.02.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//

import UIKit

enum TextConstants: Int {
    case
    tcAktLanguage = 0,
    tcLevel,
    tcLevelScore,
    tcScoreHead,
    tcCardHead,
    tcScore,
    tcTargetScore,
    tcTime,
    tcGameLost,
    tcGameLost3,
    tcTargetNotReached,
    tcSpriteCount,
    tcCardCount,
    tcReturn,
    tcok,
    tcGameComplete,
    tcNoMessage,
    tcGameAgain,
    tcTimeout,
    tcGameOver,
    tcCongratulations,
    tcChooseName,
    tcChooseLevel,
    tcVolume,
    tcCountHelpLines,
    tcLanguage,
    tcEnglish,
    tcGerman,
    tcHungarian,
    tcRussian,
    tcCancel,
    tcDone,
    tcModify,
    tcDelete,
    tcNewName,
    tcChooseLanguage,
    tcPlayer,
    tcGameModus,
    tcSoundVolume,
    tcMusicVolume,
    tcStandardGame,
    tcCardGame,
    tcPreviousLevel,
    tcNextLevel,
    tcNewGame,
    tcRestart,
    tcChooseGame,
    tcTippCount,
    tcStatistics,
    tcActScore,
    tcBestScore,
    tcActTime,
    tcAllTimeForLevel,
    tcAllTime,
    tcBestTimeForLevel,
    tcBestTime,
    tcCountPlaysForLevel,
    tcCountPlays,
    tcCountCompetitions,
    tcCountVictorys,
    tcGameCompleteWithBestScore,
    tcGameCompleteWithBestTime,
    tcGuest,
    tcAnonym,
    tcStatistic,
    tcPlayerStatisticHeader,
    tcPlayerStatisticLevel,
    tcStatisticOfGame,
    tcBestScoreOfGame,
    tcYourScore,
    tcYouAreTheBest,
    tcGameNumber,
    tcCompetition,
    tcGame,
    tcChoosePartner,
    tcWantToPlayWithYou,
    tcOpponent,
    tcOpponentHasFinished,
    tcYouHaveFinished,
    tcHeWon,
    tcYouWon,
    tcOpponentNotPlay,
    tcOpponentLevelIsLower,
    tcGameArt,
    tcVictory,
    tcStart,
    tcStopCompetition,
    tcOpponentStoppedTheGame,
    tcAreYouSureToDelete,
    tcHelpURL,
    tcj,
    tcd,
    tck,
    tcWhoIs,
    tcName,
    tcPlayerType,
    tcOpponentType,
    tcBestPlayerType,
    tcCompetitionShort,
    tcLevelAndGames,
    tcSize,
    tcPackage,
    tcHelpLines,
    tcAutoPlayNormal,
    tcAutoPlayNewTest,
    tcAutoPlayErrors,
    tcAutoPlayTable,
    tcReplay,
    tcActivateAutoPlay,
    tcLevelAndPackage,
    tcAllGamesCount,
    tc1PkgTxt,
    tc2PkgTxt,
    tc3PkgTxt,
    tc4PkgTxt
    

}

    let LanguageEN = "en" // index 0
    let LanguageDE = "de" // index 1
    let LanguageHU = "hu" // index 2
    let LanguageRU = "ru" // index 3

enum LanguageCodes: Int {
    case enCode = 0, deCode, huCode, ruCode
}


class Language {
    
    let languageNames = [LanguageEN, LanguageDE, LanguageHU, LanguageRU]
    
    let languages = [
        "de": deDictionary,
        "en": enDictionary,
        "hu": huDictionary,
        "ru": ruDictionary
    ]
    
    
    struct Callback {
        var function: ()->Bool
        var name: String
        init(function:@escaping ()->Bool, name: String) {
            self.function = function
            self.name = name
        }
    }
    var callbacks: [Callback] = []
    var aktLanguage = [TextConstants: String]()
    
    init() {
        aktLanguage = languages[getPreferredLanguage()]!
    }
    
    func setLanguage(_ languageKey: String) {        
        aktLanguage = languages[languageKey]!
        for index in 0..<callbacks.count {
            _ = callbacks[index].function()
        }
    }
    
    func setLanguage(_ languageCode: LanguageCodes) {
        aktLanguage = languages[languageNames[languageCode.rawValue]]!
        for index in 0..<callbacks.count {
            _ = callbacks[index].function()
        }
    }
    
    func getText (_ textIndex: TextConstants, values: String ...) -> String {
        return aktLanguage[textIndex]!.replace("%", values: values)
    }

    func getAktLanguageKey() -> String {
        return aktLanguage[.tcAktLanguage]!
    }
    
    func isAktLanguage(_ language:String)->Bool {
        return language == aktLanguage[.tcAktLanguage]
    }
    
    func addCallback(_ callback: @escaping ()->Bool, callbackName: String) {
        callbacks.append(Callback(function: callback, name: callbackName))
    }
    
    func removeCallback(_ callbackName: String) {
        for index in 0..<callbacks.count {
            if callbacks[index].name == callbackName {
                callbacks.remove(at: index)
                return
            }
        }
    }
    
    func getPreferredLanguage()->String {
        let deviceLanguage = Locale.preferredLanguages[0]
        let languageKey = deviceLanguage[deviceLanguage.startIndex..<deviceLanguage.characters.index(deviceLanguage.startIndex, offsetBy: 2)]
        return languageKey
    }
    
    func count()->Int {
        return languages.count
    }
    
    func getLanguageNames(_ index:LanguageCodes)->(String, Bool) {
        switch index {
            case .enCode: return (aktLanguage[.tcEnglish]!, aktLanguage[.tcAktLanguage] == LanguageEN)
            case .deCode: return (aktLanguage[.tcGerman]!, aktLanguage[.tcAktLanguage] == LanguageDE)
            case .huCode: return (aktLanguage[.tcHungarian]!, aktLanguage[.tcAktLanguage] == LanguageHU)
            case .ruCode: return (aktLanguage[.tcRussian]!, aktLanguage[.tcAktLanguage] == LanguageRU)
        }
    }
    
}



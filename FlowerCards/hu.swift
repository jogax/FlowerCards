//
//  hu.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20.09.15.
//  Copyright © 2015 Jozsef Romhanyi. All rights reserved.
//


let huDictionary: [TextConstants: String] = [
    .tcAktLanguage:      "hu",
    .tcLevel:            "Szint%",
    .tcLevelScore:       "Pontszám%",
    .tcScoreHead:        "Pontszám",
    .tcCardHead:         "Kártyák",
    .tcScore:            "Pontszám",
    .tcTime:             "Idő",
    .tcActScore:         "Az utolsó játék pontszáma: ",
    .tcTargetScore:      "Elérendö pontszám: ",
    .tcGameLost:         "Vesztettél!",
    .tcGameLost3:        "3-szor vesztettél. Előző szintre vissza!!!",
    .tcTargetNotReached: "A cél nem teljesült",
    .tcSpriteCount:      "Virágok száma:",
    .tcCardCount:        "Kártyalapok száma:",
    .tcReturn:           "Vissza",
    .tcok:               "OK",
    .tcGameComplete:     "Játék % befejezve!",
    .tcNoMessage:        "nem létező üzenet",
    .tcTimeout:          "Lejárt az időd",
    .tcGameOver:         "Vesztettél",
    .tcCongratulations:  "Gratulálok ",
    .tcChooseName:       "Játékosok listája",
    .tcVolume:           "Hangerő",
    .tcCountHelpLines:   "Segédvonalak száma",
    .tcLanguage:         "Nyelv",
    .tcEnglish:          "English (Angol)",
    .tcGerman:           "Deutsch (Német)",
    .tcHungarian:        "Magyar (Magyar)",
    .tcRussian:          "Русский (Orosz)",
    .tcCancel:           "Mégsem",
    .tcDone:             "Kész",
    .tcModify:           "Módosítás",
    .tcDelete:           "Eltávolítás",
    .tcNewName:          "Új játékos",
    .tcChooseLanguage:   "Nyelv kiválasztás",
    .tcPlayer:           "Játékos: %",
    .tcGameModus:        "Játékmód",
    .tcSoundVolume:      "Háttérzajok hangerő",
    .tcMusicVolume:      "Zene hangerő",
    .tcStandardGame:     "Játék virágokkal",
    .tcCardGame:         "Kártyajáték",
    .tcPreviousLevel:    "Előző szint",
    .tcNextLevel:        "Következő szint",
    .tcNewGame:          "Új játék",
    .tcGameAgain:        "Újra játszom",
    .tcChooseGame:       "Válassz:",
    .tcTippCount:        "Lehetséges lépések száma: ",
    .tcStatistics:       "%. játék %. szint",
    .tcActTime:          "A játék időtartama: ",
    .tcBestTimeForLevel: "A szint legjobb ideje: ",
    .tcBestTime:         "Legjobb idő",
    .tcAllTimeForLevel:  "A szint teljes játékideje: ",
    .tcAllTime:          "Idő",
    .tcCountPlaysForLevel: "Eddig % játékot játszottál",
    .tcCountPlays:        "Játékok",
    .tcCountCompetitions: "Verseny",
    .tcCountVictorys:     "Győzelem / Vereség",
    .tcBestScore:        "Legjobb pontszám",
    .tcGameCompleteWithBestScore: "Új pontszám rekord a(z) % szinten!",
    .tcGameCompleteWithBestTime:  "Legjobb idő a(z) % szinten",
    .tcGuest:            "Vendég",
    .tcAnonym:           "Anonymus",
    .tcStatistic:        "Statisztikák",
    .tcPlayerStatisticHeader: "% statisztikái",
    .tcPlayerStatisticLevel: "% statisztikái, %. szint",
    .tcStatisticOfGame:  "%. játék statistikája",
    .tcBestScoreOfGame:   "Legjobb pontszám % %",
    .tcYourScore:         "Pontszámod %",
    .tcYouAreTheBest:    "Tiéd a legjobb pontszám: %",
    .tcGameNumber:       "Játék sorszáma:",
//    .tcChooseGameNumber: "Válassz játékot",
//    .TCPlayerStatistic:  "Játékos statisztika",
//    .TCGameStatistic:    "Játék statisztika",
    .tcCompetition:      "Verseny",
    .tcCompetitionShort: "Verseny",
    .tcGame:             "Játék",
    .tcChoosePartner:    "Válassz ellenfelet:",
    .tcWantToPlayWithYou:"% szeretne veled játszani!",
    .tcOpponent:          "Ellenfél: %",
    .tcOpponentHasFinished: "% befejezte a #% játékot!\r\n" +
                            "bonuszpontjai: %\r\n" +
                            "pontszáma: %\r\n" +
                            "a te pontszámod: %\r\n ",
    .tcHeWon:               "% győzött % - %\r\n" +
                            "Sajnálom :-(",
    .tcYouWon:              "Te győztél % - %!\r\n" +
                            "Gratulálok ;-) !!!",
    .tcYouHaveFinished: "Befejezted a #% játékot!\r\n" +
                        "Bónuszpontok: %\r\n" +
                        "Pontjaid: %\r\n" +
                        "% pontjai: %\r\n ",
    .tcOpponentNotPlay: "% nem akar veled játszani!",
    .tcOpponentLevelIsLower: "% még nem érte el a szintedet",
    .tcGameArt:         "Tipus",
    .tcVictory:         "Győzelem",
    .tcStart:           "Start",
    .tcStopCompetition: "Verseny leállítása",
    .tcOpponentStoppedTheGame: "% leállította a játékot",
    .tcAreYouSureToDelete: "Biztosan törölni akarod %-t?\r\n" +
                        "Minden adata törölve lesz!",
    .tcHelpURL:         "http://jogaxplay.hu/portl/hu",
    .tcj:               "J",
    .tcd:               "Q",
    .tck:               "K",
    .tcWhoIs:           "Kicsoda",
    .tcName:            "Név",
    .tcPlayerType:      "Játékos",
    .tcOpponentType:    "Ellenfél",
    .tcBestPlayerType:  "Legjobb játékos",
    .tcChooseLevel:     "Válassz szintet és opciókat",
    .tcLevelAndGames:   "Szint (lejátszva)",
    .tcSize:            "Formátum:",
    .tcPackages:        "Kártyacsomag:",
    .tcHelpLines:       "Segédvonalak:",

]

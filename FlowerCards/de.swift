//
//  de.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20.09.15.
//  Copyright © 2015 Jozsef Romhanyi. All rights reserved.
//


let deDictionary: [TextConstants: String] = [
    .tcAktLanguage:      "de",
    .tcLevel:            "Ebene%",
    .tcLevelScore:       "Summe%",
    .tcScoreHead:        "Punkte",
    .tcCardHead:         "Karten",
    .tcScore:            "Ergebnis",
    .tcTime:             "Zeit",
    .tcActScore:         "Ergebnis des letzten Spiels: ",
    .tcBestScore:        "Beste Ergebnis",
    .tcTargetScore:      "Ziel Gesamtsumme: ",
    .tcGameLost:         "Du hast verloren!",
    .tcGameLost3:        "Du hast 3 mal verloren. Startet vorherige Level.",
    .tcTargetNotReached: "Das Ziel ist nicht erreicht.",
    .tcSpriteCount:      "Anzahl von Blumen:",
    .tcCardCount:        "Anzahl von Karten:",
    .tcReturn:           "Zurück",
    .tcok:               "OK",
    .tcGameComplete:     "Spiel % beendet!",
    .tcNoMessage:        "keine Meldung",
    .tcTimeout:          "Timeout",
    .tcGameOver:         "Spiel vorbei",
    .tcCongratulations:  "Herzliches Glückwunsch ",
    .tcChooseName:       "Wähle Name",
    .tcVolume:           "Lautstärke",
    .tcCountHelpLines:   "Anzahl Hilfslinien",
    .tcLanguage:         "Sprache",
    .tcEnglish:          "English (Englisch)",
    .tcGerman:           "Deutsch (Deutsch)",
    .tcHungarian:        "Magyar (Ungarisch)",
    .tcRussian:          "Русский (Russisch)",
    .tcCancel:           "Abbrechen",
    .tcDone:             "Fertig",
    .tcModify:           "Ändern",
    .tcDelete:           "Löschen",
    .tcNewName:          "Neuer Spieler",
    .tcChooseLanguage:   "Sprache wählen",
    .tcPlayer:           "Spieler: %",
    .tcGameModus:        "Spielmodus",
    .tcSoundVolume:      "Geräusch Lautstärke",
    .tcMusicVolume:      "Musik Lautstärke",
    .tcStandardGame:     "Spiel mit Blumen",
    .tcCardGame:         "Spiel mit Karten",
    .tcPreviousLevel:    "Vorherige Ebene",
    .tcNextLevel:        "Nächste Ebene",
    .tcNewGame:          "Neues Spiel",
    .tcGameAgain:        "Spiel wiederholen",
    .tcChooseGame:       "Wähle bitte: ",
    .tcCompetitionHeader:"Wettbewerb mit %",
    .tcTippCount:        "Anzahl der möglichen Züge: ",
    .tcStatistics:       "Statistik des Spiels % auf Ebene %",
    .tcActTime:          "Zeit für das Spiel: ",
    .tcBestTimeForLevel: "Beste Zeit der Ebene: ",
    .tcBestTime:         "Beste Zeit",
    .tcAllTimeForLevel:  "Gesamtzeit für diese Ebene: ",
    .tcAllTime:          "Zeit",
    .tcCountPlaysForLevel: "Bis jetzt % Spiele gespielt",
    .tcCountPlays:        "Spiele",
    .tcCountCompetitions: "Wettbew.",
    .tcCountVictorys:     "Sieg / Niederlage",
    .tcGameCompleteWithBestScore: "Neue Rekordsumme auf der Ebene %!",
    .tcGameCompleteWithBestTime:  "Neue Zeitrekord auf der Ebene %!",
//    .tcGuest:            "Gast",
    .tcMe:              "Ich",
    .tcAnonym:           "Anonymus",
    .tcStatistic:        "Statistiken",
    .tcPlayerStatisticHeader: "Meine Statistiken",
    .tcPlayerStatisticLevel: "Statistiken für Ebene % (%), Pakete: %",
    .tcStatisticOfGame:  "Statistik des Spiels %:",
    .tcBestScoreOfGame:   "Beste Ergebnis % %",
    .tcYourScore:         "Dein Ergebnis %",
    .tcReachedScore:      "Deine Punkte: %",
    .tcTimeBonus:         "Zeit Bonus: %",
    .tcYouAreTheBest:    "Du bist der Beste mit Ergebnis %",
    .tcGameNumber:       "Spiel: #%",
//    .tcChooseGameNumber: "Wähle ein Spiel",
//    .TCPlayerStatistic:  "Spielerstatistik",
//    .TCGameStatistic:    "Spielstatistik",
    .tcCompetition:      "Wettbewerb",
    .tcCompetitionShort: "Wettbew.",
    .tcGame:             "Spiel",
    .tcChoosePartner:    "Wähle einen Gegner:",
    .tcWantToPlayWithYou:"% will mit Dir spielen!!",
    .tcOpponent:         "Gegner: %",
    .tcOpponentHasFinished: "% hat das Spiel #% beendet!\r\n" +
                        "seine Punkte: %\r\n" +
                         "sein Zeitbonus: %\r\n" +
                         "sein Ergebnis: %\r\n" +
                         "deine Punkte: %\r\n ",
    .tcHeWon:            "% hat gewonnen % - %!\r\n" +
                         "Schade :-(",
    .tcYouWon:           "Du hast gewonnen % - %!\r\n" +
                         "Gratuliere!!!",
    .tcYouHaveFinished:  "Du hast gas Spiel #% beendet!\r\n" +
                         "Deine Punkte: %\r\n" +
                         "Dein Zeitbonus: %\r\n" +
                         "Dein Ergebnis : %\r\n" +
                         "% Punkte: %\r\n ",
    .tcOpponentNotPlay: "% will nicht mit Dir spielen!",
    .tcPeerToPeerVersionIsHigher: "% hat höhere Kommunikation Version, Du muss Flowercards updaten für ein Wettbewerb mit ihm",
    .tcPeerToPeerVersionIsLower: "% hat niedrigere Kommunikation Version, er muss Flowercards updaten  für ein Wettbewerb mit Dir",
    .tcGameArt:         "Art",
    .tcVictory:         "Sieg",
    .tcStart:           "Start",
    .tcSettings:        "Einstellungen",
    .tcHelp:            "Hilfe",
    .tcTipps:           "Tipps",
    .tcUndo:            "Zurück",
    .tcStopCompetition: "Stop Wettbewerb",
    .tcOpponentStoppedTheGame: "% hat das Spiel stopped",
    .tcAreYouSureToDelete: "Willst Du wirklich den Spieler % löschen?\r\n" +
                        "Alle seine Statistikdaten werden mitgelöscht!",
    .tcHelpURL:         "http://jogaxplay.hu/portl/de",
    .tcj:               "J",
    .tcd:               "Q",
    .tck:               "K",
    .tcWhoIs:           "Wer",
    .tcName:            "Name",
    .tcPlayerType:      "Ich",
    .tcOpponentType:    "Gegner",
    .tcBestPlayerType:  "Beste Spieler",
    .tcChooseLevel:     "Wähle Ebene und Optionen",
    .tcLevelAndGames:   "Ebene (gespielt)",
    .tcSize:            "Format:",
    .tcPackage:         "Pakete: %",
    .tcHelpLines:       "Hilfslinien:",
    .tcAutoPlayNormal:  "Start automatisches Abspielen dieses Spiels",
    .tcAutoPlayNewTest: "Start autoplay Test",
    .tcAutoPlayErrors:  "Start autoplay Fehler",
    .tcAutoPlayTable:  "Start autoplay Tabelle",
    .tcReplay:          "Wiedergabe des Spiels",
    .tcActivateAutoPlay: "Autoplay aktivieren",
    .tcLevelAndPackage: "Pakete:%, Ebene:%, Format:%",
    .tcAllGamesCount:   "Games: % / %, %",
    .tcPkgTxt:          "%. P: % / %",
    .tcNoMoreSteps:     "Hoppala! Dieser Schritt würde es unmöglich machen, das Spiel zu beenden -> so Schritt zurück",
    .tcThereIsNoPartner: "Keine Spieler in der nähe!",
    .tcIsPlayingWith:   " spielt mit %",
    .tcWriteReview:     "Bewertung im App Store",
    .tcConnectGC:       "Verbinden mit Gamecenter",
    .tcDisconnectGC:    "Trennen vom Gamecenter",
    .tcShowGameCenter:  "Zeige Game Center",
    .tcMyPlace:          "Ich (%): %. Platz: %",
    .tcBestPlace:        "(%) 1. Platz: %",
    .tcAskForGameCenter: "Sie können jetzt eine Verbindung\r\n" +
                         "zum Game Center herstellen um zu sehen, \r\n" +
                         "welche Ergebnisse andere Spieler haben.",
    .tcAskLater:        "Frag mich später",
    .tcAskNoMore:       "Frag mich nie mehr",
    .tcOnlineGame:      "Online Spiel",
    .tcMatchDisconnected: "? hat den Wettbewerb verlassen",
    .tcIChooseTheParams: "%: Pakete:%, Ebene:%\r\n" +
                            "Ich: Pakete:%, Ebene:%\r\n" +
                            "Akzeptieren seine Parameter?",
    .tcPartnerChooseTheParams: "%: Pakete:%, Ebene:%\r\n" +
                            "Ich: Pakete:%, Ebene:%%\r\n" +
                            "Warten auf %",
    .tcPartnerParametersAre: "% und Ich (%)\r\n" +
                                "haben die selbe\r\n" +
                                "Pakete:%, Ebene:%",
    .tcNoWait:              "Ich warte nicht länger!",
    .tcYes:                 "Ja",
    .tcNo:                  "Nein",
    .tcFriend:              "Freund: ",
    .tcWaitForOpponent:       "Suche nach einem Gegner\r\n" +
                            "Bitte warten!",
    .tcAllPlayers:          "Autodetect einen Spieler",
    .tcSearchOpponent:      "Suche nach Gegner über Game Center",
    .tcEnableAutoSearch:    "Autosuche Ein",
    .tcDisableAutoSearch:    "Autosuche Aus",
    .tcWantToPlayWithYouGC: "% will mit dir spielen!\r\n" +
                            "Starten das Spiel?",
    .tcCheckPartners:       "Suche nach Spielern in der Nähe",
    .tcCopyRight:           "\u{00A9} 2020 % (V %)",
]




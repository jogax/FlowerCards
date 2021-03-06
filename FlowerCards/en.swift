//
//  en.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20.09.15.
//  Copyright © 2015 Jozsef Romhanyi. All rights reserved.
//


let enDictionary: [TextConstants: String] = [
    .tcAktLanguage:      "en",
    .tcLevel:            "Level%",
    .tcLevelScore:       "Levelscore%",
    .tcScoreHead:        "Score",
    .tcCardHead:         "Cards",
    .tcScore:            "Score",
    .tcTime:             "Time",
    .tcActScore:         "Score of last Game: ",
    .tcBestScore:        "Best Score in Game Center:",
    .tcTargetScore:      "target Score:",
    .tcGameLost:         "you lost!",
    .tcGameLost3:        "You lose 3 times. Previous level starts.",
    .tcTargetNotReached: "target not reached",
    .tcSpriteCount:      "Count of Flowers:",
    .tcCardCount:        "Count of Cards:",
    .tcReturn:           "Return",
    .tcok:               "OK",
    .tcGameComplete:     "Game % completed!",
    .tcNoMessage:        "no Message",
    .tcTimeout:          "timeout",
    .tcGameOver:         "Game Over",
    .tcCongratulations:  "Congratulations ",
    .tcChooseName:       "List of player",
    .tcVolume:           "Lautstärke",
    .tcCountHelpLines:   "Count helplines",
    .tcLanguage:         "Language",
    .tcEnglish:          "English (English)",
    .tcGerman:           "Deutsch (German)",
    .tcHungarian:        "Magyar (Hungarian)",
    .tcRussian:          "Русский (Russian)",
    .tcCancel:           "Cancel",
    .tcDone:             "Done",    
    .tcModify:           "Modify",
    .tcDelete:           "Delete",
    .tcNewName:          "New Player",
    .tcChooseLanguage:   "Choose a language",
    .tcPlayer:           "Player: %",
    .tcGameModus:        "Gamemodus",
    .tcSoundVolume:      "Sound Volume",
    .tcMusicVolume:      "Musik Volume",
    .tcStandardGame:     "Game with Flowers",
    .tcCardGame:         "Game with Cards",
    .tcPreviousLevel:    "Previous Level",
    .tcNextLevel:        "Next level",
    .tcNewGame:          "New Game",
    .tcGameAgain:        "Restart Game",
    .tcChooseGame:       "Choose Please:",
    .tcCompetitionHeader: "Competition with %",
    .tcTippCount:        "Number of possible steps: ",
    .tcStatistics:       "Statistics of game % on Level %",
    .tcActTime:          "Time for game: ",
    .tcBestTimeForLevel: "Best time for this Level: ",
    .tcBestTime:         "Best time",
    .tcAllTimeForLevel:  "Total time for this level: ",
    .tcAllTime:          "Time",
    .tcCountPlaysForLevel:"Until now played % games",
    .tcCountPlays:        "Games",
    .tcCountCompetitions: "Compet.",
    .tcCountVictorys:     "Victory / Defeat",
    .tcGameCompleteWithBestScore: "New score record at level %!",
    .tcGameCompleteWithBestTime:  "New time record at level %!",
//    .tcGuest:            "Guest",
    .tcMe:              "Me",
    .tcAnonym:           "Anonymus",
    .tcStatistic:        "Statistics",
    .tcPlayerStatisticHeader: "My statistics",
    .tcPlayerStatisticLevel: "Statistics for level: % (%), packages: %",
    .tcStatisticOfGame:  "Statistic of game Nr. %",
    .tcBestScoreOfGame:   "Best score: %  %",
    .tcYourScore:           "Your score: %",
    .tcReachedScore:        "Reached Score: %",
    .tcTimeBonus:           "Time bonus: %",
    .tcYouAreTheBest:    "You are the Best with score %",
    .tcGameNumber:       "Game: #%",
//    .tcChooseGameNumber: "Choose a game",
//    .TCPlayerStatistic:  "Player statistic",
//    .TCGameStatistic:    "Game statistic",
    .tcCompetition:      "Competition",
    .tcCompetitionShort: "Compet.",
    .tcGame:             "Game",
    .tcChoosePartner:    "Choose an opponent:",
    .tcWantToPlayWithYou:"% want play with you!",
    .tcOpponent:          "Opponent: %",
    .tcOpponentHasFinished: "% has finished the Game #%!\r\n" +
                            "his score: %\r\n" +
                            "his timeBonus: %\r\n" +
                            "his total score : %\r\n" +
                            "your score: %\r\n ",
    .tcHeWon:               "% won % - %!\r\n" +
                            "Sorry :-(",
    .tcYouWon:              "You won % - %! \r\n" +
                            "Congratulations!!!",
    .tcYouHaveFinished: "You have finished the Game #%!\r\n" +
                        "your score: %\r\n" +
                        "your bonus: %\r\n" +
                        "your total score : %\r\n" +
                        "% score: %\r\n ",
    .tcOpponentNotPlay: "% does not want to play with you!",
    .tcPeerToPeerVersionIsHigher: "% has a higher Communication Version, you must update Flowercards for a competition with him",
    .tcPeerToPeerVersionIsLower: "% has a lower Communication Version, he must update Flowercards  for a competition with you",
    .tcGameArt:         "Type",
    .tcVictory:         "Victory",
    .tcStart:           "Start",
    .tcSettings:        "Settings",
    .tcHelp:            "Help",
    .tcTipps:           "Tipps",
    .tcUndo:            "Undo",
    .tcStopCompetition: "Stop competiton",
    .tcOpponentStoppedTheGame: "% has stopped the competition!",
    .tcAreYouSureToDelete: "Are you sure to delete %?\r\n" +
                        "All his data will be killed!",
    .tcHelpURL:         "http://jogaxplay.hu/portl/en",
    .tcj:               "J",
    .tcd:               "Q",
    .tck:               "K",
    .tcWhoIs:           "Who",
    .tcName:            "Name",
    .tcPlayerType:      "Me",
    .tcOpponentType:    "Opponent",
    .tcBestPlayerType:  "Best Player",
    .tcChooseLevel:     "Choose level and options",
    .tcLevelAndGames:   "Level (played)",
    .tcSize:            "Format:",
    .tcPackage:         "Packages: %",
    .tcHelpLines:       "Helplines:",
    .tcAutoPlayNormal:  "Start autoplay this Game",
    .tcAutoPlayNewTest: "Start autoplay test",
    .tcAutoPlayErrors:  "Start autoplay errors",
    .tcAutoPlayTable:  "Start autoplay table",
    .tcReplay:          "Replay",
    .tcActivateAutoPlay: "Activate Autoplay",
    .tcLevelAndPackage: "Packages:%, Level:%, Format:%",
    .tcAllGamesCount:   "Games: % / %, %",
    .tcPkgTxt:         "%. P: % / %",
    .tcNoMoreSteps:     "Oops! This step would make the game unfinishable -> undo!",
    .tcThereIsNoPartner: "No Players found!",
    .tcIsPlayingWith:   " is playing with %",
    .tcWriteReview:     "Write Review on App Store",
//    .tcConnectGC:       "Connect to Gamecenter",
//    .tcDisconnectGC:    "Disconnect from Gamecenter",
    .tcShowGameCenter:  "Show Game Center",
    .tcMyPlace:         "%. Place: % (Me - %) ",
    .tcBestPlace:       "1. Place: % (%)",
    .tcAskForGameCenter: "You can now connect to the Game Center \r\n" +
                         "to see what scores other players have.",
    .tcAskLater:        "Ask me Later",
    .tcAskNoMore:       "Ask me no more",
    .tcOnlineGame:      "Online Game",
    .tcMatchDisconnected: "% has the match disconnected",
    .tcIChooseTheParams:    "%: Packages:%, Level:%\r\n" +
                             "Me: Packages:%, Level:%\r\n" +
                             "Accept his parameters?",
    .tcPartnerChooseTheParams: "%: Packages:%, Level:%\r\n" +
                                "Me: Packages:%, Level:%\r\n" +
                                "waiting for % to choose!",
    .tcPartnerParametersAre: "% and I (%)\r\n" +
                              "have the same\r\n" +
                              "Packages:%, Level:%",
    .tcNoWait:               "Stop waiting",
    .tcYes:                     "Yes",
    .tcNo:                      "No",
    .tcFriend:              "Friend: ",
    .tcWaitForOpponent:       "Search for an opponent\r\n" +
                            "Please wait!",
    .tcAllPlayers:          "Autodetect a player",
    .tcSearchOpponent:      "searching for opponent via Game Center",
    .tcEnableAutoSearch:    "Set Auto Search",
    .tcDisableAutoSearch:    "Reset Auto Search",
    .tcWantToPlayWithYouGC: "% want play with you!\r\n" +
                            "Start the Game?",
    .tcCheckPartners:       "Search for nearby players",
    .tcCopyRight:           "\u{00A9} 2020 % (V %)",
]

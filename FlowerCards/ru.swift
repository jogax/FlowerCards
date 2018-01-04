//
//  ru.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20.09.15.
//  Copyright © 2015 Jozsef Romhanyi. All rights reserved.
//


let ruDictionary: [TextConstants: String] = [
    .tcAktLanguage:      "ru",
    .tcLevel:            "Уровень%",
    .tcLevelScore:       "Очки%",
    .tcCardHead:         "Карты",
    .tcScoreHead:        "Очки",
    .tcScore:            "Очки",
    .tcTime:             "Время",
    .tcActScore:         "Очки последней игры: ",
    .tcBestScore:        "Лучшие очки",
    .tcTargetScore:      "Получить очки: ",
    .tcGameLost:         "Ты проиграл!",
    .tcGameLost3:        "Ты проиграл в 3 раза! Назад к предыдущему уровню!",
    .tcTargetNotReached: "Цель не достигнутa",
    .tcSpriteCount:      "количество цветов:",
    .tcCardCount:        "количество карт:",
    .tcReturn:           "Назад",
    .tcok:               "OK",
    .tcGameComplete:     "Игра % завершена!",
    .tcNoMessage:        "Сообщение не найдёно",
    .tcTimeout:          "Время закончилось",
    .tcGameOver:         "Игра проиграна",
    .tcCongratulations:  "Поздравляю ",
    .tcChooseName:       "Список игроков",
    .tcVolume:           "Громкость",
    .tcCountHelpLines:   "кол. вспомогательных линий",
    .tcLanguage:         "Язык",
    .tcEnglish:          "English (Английский)",
    .tcGerman:           "Deutsch (Немецкий)",
    .tcHungarian:        "Magyar (Венгерский)",
    .tcRussian:          "Русский (Русский)",
    .tcCancel:           "Отменить",
    .tcDone:             "Готово",
    .tcModify:           "Изменить",
    .tcDelete:           "Удалить",
    .tcNewName:          "Новый игрок",
    .tcChooseLanguage:   "Выбoр языка",
    .tcPlayer:           "Игрок: %",
    .tcGameModus:        "Тип игры",
    .tcSoundVolume:      "Громкость звука",
    .tcMusicVolume:      "Громкость музыки",
    .tcStandardGame:     "Игра с цветами",
    .tcCardGame:         "Игра с картами",
    .tcPreviousLevel:    "Предыдущий уровень",
    .tcNextLevel:        "Следующий уровень",
    .tcNewGame:          "Новая игра",
    .tcGameAgain:        "Повторить игру",
    .tcChooseGame:       "Выберите пожалуйста:",
    .tcCompetitionHeader:"Соревнование c %",
    .tcTippCount:        "Kоличество возможных ходов: ",
    .tcStatistics:       "Игра % на уровне %",
    .tcActTime:          "Продолжительность игры: ",
    .tcBestTimeForLevel: "Лучшее время уровня: ",
    .tcBestTime:         "Лучшее время",
    .tcAllTimeForLevel:  "Полное время уровня: ",
    .tcAllTime:          "Bремя",
    .tcCountPlaysForLevel: "До сих пор % игр",
    .tcCountPlays:        "Игры",
    .tcCountCompetitions: "Соревн.",
    .tcCountVictorys:     "Побед / Поражений",
    .tcGameCompleteWithBestScore: "Новый рекорд очков на уровне %!",
    .tcGameCompleteWithBestTime:  "Новый рекорд времени на уровне % ",
    .tcGuest:            "Гость",
    .tcAnonym:           "Anonymus",
    .tcStatistic:        "Статистика",
    .tcPlayerStatisticHeader: "Статистика игрока %%",
    .tcPlayerStatisticLevel: "Статистика игрока %, уровень: % (%), Колоды: %",
    .tcStatisticOfGame:  "Статистика %-й игры",
    .tcBestScoreOfGame:   "Лучший результат % %",
    .tcYourScore:         "Твой результат %",
    .tcReachedScore:        "Достигнуты очки: %",
    .tcTimeBonus:           "Бонус времени: %",
    .tcYouAreTheBest:    "Вы самый лучший со счетом %",
    .tcGameNumber:       "Игра: #%",
//    .tcChooseGameNumber: "Выбери игру",
//    .TCPlayerStatistic:  "Статистика игроков",
//    .TCGameStatistic:    "Статистика игр",
    .tcCompetition:      "Соревнование",
    .tcCompetitionShort: "Соревн.",
    .tcGame:             "Игра",
    .tcChoosePartner:    "Выбери противника:",
    .tcWantToPlayWithYou:"% хочет с тобой поиграть!",
    .tcOpponent:         "Противник:%",
    .tcOpponentHasFinished: "% закончил игру #%!\r\n" +
                        "его/ee очки: %\r\n" +
                        "его/ee бонус: %\r\n" +
                        "его/ee результат: %\r\n" +
                        "твои очки: %\r\n ",
    .tcYouHaveFinished: "ты закончил игру #%!\r\n" +
                        "твои очки: %\r\n" +
                        "твой бонус: %\r\n" +
                        "твой результат: %\r\n" +
                        "% очки: %\r\n ",
    .tcHeWon:           "% победил нa % - %!\r\n" +
                        "K сожалению :-(",
    .tcYouWon:          "ты победил нa % - %! \r\n" +
                        "Поздравляю!!!",
    .tcOpponentNotPlay: "% не хочет с тобой играть!",
    .tcPeerToPeerVersionIsHigher: "Версия связи у % выше, загрузи последнюю версию игры для cоревнования с ним!",
    .tcPeerToPeerVersionIsLower: "% Версия связи у % ниже, он должен загрузить последнюю версию игры для cоревнования с тобой!",
    .tcGameArt:         "Tип",
    .tcVictory:         "Победa",
    .tcStart:           "Старт",
    .tcSettings:        "Настройки",
    .tcHelp:            "Помощь",
    .tcTipps:           "Подсказка",
    .tcUndo:            "Назад",
    .tcStopCompetition: "Стоп cоревнование",
    .tcOpponentStoppedTheGame: "% остановил игру",
    .tcAreYouSureToDelete: "Действительно удалить игрока %?\r\n" +
                           "Все его данные будут удалены!",
    .tcHelpURL:         "http://jogaxplay.hu/portl/ru",
    .tcj:               "В",
    .tcd:               "Д",
    .tck:               "К",
    .tcWhoIs:           "Кто",
    .tcName:            "Имя",
    .tcPlayerType:      "Я",
    .tcOpponentType:    "Противник",
    .tcBestPlayerType:  "Лучший игрок",
    .tcChooseLevel:     "Выберите уровень и параметры",
    .tcLevelAndGames:   "Уровень (сыграно)",
    .tcSize:            "Формат:",
    .tcPackage:         "Колоды: %",
    .tcHelpLines:       "Тип помощи:",
    .tcAutoPlayNormal:  "Автовыполнение игры",
    .tcAutoPlayNewTest: "Автотестирование",
    .tcAutoPlayErrors:  "Автовыполнение ошибочных игр",
    .tcAutoPlayTable:   "Автотестирование из таблицы",
    .tcReplay:          "Воспроизведение игры",
    .tcActivateAutoPlay:"Активировать автотест",
    .tcLevelAndPackage: "Колоды:%, Уровень:%, Формат:%",
    .tcAllGamesCount:   "Games: % / %, %",
    .tcPkgTxt:          "%. P: % / %",
    .tcNoMoreSteps:     "Упс! Этот шаг сделал бы невозможным закончить игру -> так шаг назад",
    .tcThereIsNoPartner: "Нет игроков поблизости!",
    .tcIsPlayingWith:   " играет с %",
    .tcWriteReview:     "Написать отзыв в App Store",
    .tcConnectGC:       "Подключиться к Game Center",
    .tcDisconnectGC:    "Отключиться от Game Center",
    .tcShowGameCenter:  "Покажи Game Center",
    .tcMyPlace:          "%. Место (я): %",
    .tcBestPlace:        "1. Место (%): %",
    .tcAskForGameCenter: "Теперь вы можете подключиться к Игровому центру,\r\n" +
                         "чтобы узнать, сколько очков у других игроков.",
    .tcAskLater:        "Спроси меня позже",
    .tcAskNoMore:       "Не спрашивай меня больше",
    .tcOnlineGame:      "Online Игра",
    .tcMatchDisconnected: "% вышел из игры",
    .tcIChooseTheParams: "%: Колоды:%, Уровень:%\r\n" +
                        "Я: Колоды:%, Уровень:%\r\n" +
                        "Принять его параметры?",
    .tcPartnerChooseTheParams: "%: Колоды:%, Уровень:%\r\n" +
                                "Я: Колоды:%, Уровень:%\r\n" +
                                "% будет выбирать, подожди пожалуйста!",
    .tcPartnerParametersAre: "% и Я (%)\r\n" +
                                "на том же уровне:\r\n" +
                                "Колоды:%, Уровень:%",
    .tcNoWait:                  "Я больше не буду ждать!",
    .tcYes:                     "Да",
    .tcNo:                      "Нет",
    .tcFriend:                  "Друг: ",
    .tcWaitForOpponent:           "Поиск соперника\r\n" +
                                "Подожди пожалуйста!",
    .tcAllPlayers:              "Автоопределение игрока",
    .tcSearchOpponent:          "поиск противника через Game Center",
    .tcEnableAutoSearch:        "Включить автоматический поиск противника",
    .tcDisableAutoSearch:       "Отключить автоматический поиск противника",
    .tcWantToPlayWithYouGC:     "% хочет поиграть с тобой!\r\n" +
                                "Начать игру?",
]

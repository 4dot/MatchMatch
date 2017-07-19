//
//  MatchGameManager.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/23/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import Foundation


enum TeamType : Int {
    case Red, Blue
    case Cnt
}

enum PlayType : Int {
    case Single, Multi
}

enum CheckMatchResult : Int {
    case None
    case OneFlip
    case NotMatched
    case Matched
    case GameOver
}

//
// MatchGameManager class
//
class MatchGameManager : NSObject {
    
    // default 4 * 4
    var cardRows: Int = 4
    var cardCols: Int = 4
    
    
    // create FSM
    private let gameFSM: MatchGameFSM = MatchGameFSM.shared
    
    // current state
    dynamic var currentState: Int = MatchGameState.Init.rawValue
    
    
    // cards
    var gameCards: [gameCardType] = []
    
    // timer
    dynamic var timerString: String = "00"
    var timer: Timer?
    var timerInterval: Int = 1
    
    // score
    var gameScore: [Int] = []
    dynamic var currentTurn: Int = TeamType.Red.rawValue
    
    // play type
    var playType: PlayType = .Multi
    
    // selected card index
    var selectedCardSection: Int = -1
    var selectedCardRow: Int = -1
    
    // selected card id
    var selectedCardId: String = ""
    
    
    
    
    // MARK: - Singleton
    class var shared: MatchGameManager {
        struct Singleton {
            static let instance = MatchGameManager()
        }
        return Singleton.instance
    }
    
    // MARK: initialization
    
    private override init() {
        super.init()
        
        initFSM()
        
        for _ in 0..<TeamType.Cnt.rawValue {
            gameScore.append(0)
        }
    }
    
    
    // MARK: - public functions
    
    /**
     * @desc when user selected a card
     * @param idx array index of cards
     * @return CheckMatchResult
     */
    func selectCard(section: Int, row: Int)-> CheckMatchResult {
        if section >= cardRows || row >= cardCols {
            return .None
        }
        
        // play mode only
        if getCurrentState() != .Play {
            return .None
        }
        
        // find index of cards array
        let cardIndex = (section * cardCols) + row
        var selectedCard = gameCards[cardIndex]
        
        // already opened
        if selectedCard.opend || selectedCard.matched {
            return .None
        }
        
        // select first card
        if selectedCardRow == -1 && selectedCardSection == -1 {
            gameCards[cardIndex].opend = true
            
            // save index and card id
            selectedCardRow = row
            selectedCardSection = section
            selectedCardId = selectedCard.card.id
            selectedCard.opend = true
            
            return .OneFlip
        }
        
        // check matching
        let isMatched = checkMatch(selectedCard.card.id)
        
        // change card state
        setCardStatus(isMatched: isMatched, compareIdx: cardIndex)
        
        // get result
        let result: CheckMatchResult = isMatched ? .Matched : .NotMatched
        
        
        // check game over
        if result == .Matched {
            if isGameOver() {
                // send gameover event
                runEvent(event: "GameOver")
            }
        } else if result == .NotMatched {
            if playType == .Multi {
                // change turn
                currentTurn = (currentTurn == TeamType.Red.rawValue) ? TeamType.Blue.rawValue : TeamType.Red.rawValue
            }
        }
        
        return result
    }
    /**
     @desc send event to FSM
    */
    func runEvent(event: String) {
        
        gameFSM.changeState(event: event, run: { [weak self] in
            
            switch event {
                case "Init" :
                    // reset all
                    self?.reset()
                case "Ready" :
                    // reset all
                    self?.reset()
                case "Play":
                    // start timer
                    self?.startTimer()
                case "GameOver":
                    // stop timer
                    self?.stopTimer()
                default: break
            }
            
            // update current state, notify to MainViewController
            self?.currentState = (self?.gameFSM.currState.rawValue)!
        })
    }
    
    /**
     * @brief check game over
     * @return Bool
     */
    func isGameOver()-> Bool {
        for card in gameCards {
            if card.opend == false || card.matched == false {
                return false
            }
        }
        return true
    }
    
    func getScore(_ team: TeamType)-> Int {
        return gameScore[team.rawValue]
    }
    
    func getCurrentState()-> MatchGameState {
        return MatchGameState(rawValue: currentState)!
    }
    
    // MARK: Private functions
    
    /**
     * @desc set selected card state
     * @param isMatched is matched two cards
     */
    private func setCardStatus(isMatched: Bool, compareIdx: Int) {
        
        let prevIndex = (selectedCardSection * cardCols) + selectedCardRow
        gameCards[prevIndex].opend = isMatched
        gameCards[prevIndex].matched = isMatched
        gameCards[compareIdx].opend = isMatched
        gameCards[compareIdx].matched = isMatched
        
        if isMatched {
            // save  score
            saveScore(TeamType(rawValue: currentTurn)!, 1)
        }
        
        // reset
        selectedCardSection = -1
        selectedCardRow = -1
        selectedCardId = ""
    }
    
    private func initFSM() {
        
    }
    
    private func reset() {
        // reset score
        for idx in 0..<TeamType.Cnt.rawValue {
            gameScore[idx] = 0
        }
        
        // reset matched tag
        for idx in 0..<gameCards.count {
            gameCards[idx].opend = false
            gameCards[idx].matched = false
        }
        
        selectedCardSection = -1
        selectedCardRow = -1
        
        selectedCardId = ""
        currentTurn = TeamType.Red.rawValue
        
        resetTimer()
    }
    
    private func saveScore(_ currTeam: TeamType, _ addScore: Int) {
        gameScore[currTeam.rawValue] += addScore
    }
    
    private func checkMatch(_ compareId: String)-> Bool {
        
        let isMatched = selectedCardId == compareId ? true : false
        
        // debug output
        let teamName = currentTurn == TeamType.Red.rawValue ? "Red" : "Blue"
        print("open card [\(selectedCardId), \(compareId)] -> \(isMatched) (\(teamName))")
        
        return isMatched
    }
    
    // MARK: Timer
    
    fileprivate func startTimer() {
        // create timer
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(timerInterval),
                                     target: self,
                                     selector: #selector(updateTimer),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc fileprivate func updateTimer() {
        let tick = Int(timerString)! + timerInterval
        timerString = NSString(format: "%02d", tick) as String
    }
    
    fileprivate func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerString = "00"
    }
    
    fileprivate func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

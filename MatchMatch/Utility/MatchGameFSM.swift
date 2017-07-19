//
//  MatchGameFSM.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/24/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import Foundation
import UIKit
import Transporter

typealias fatchTranslate = (()-> Void)?


// MatchMatch Game State definition
enum MatchGameState : Int {
    case Init
    case Ready
    case Play
    case Pause
    case GameOver
    
    static let all = [Init, Ready, Play, Pause, GameOver]
    
    static func printState(_ state: MatchGameState) -> String{
        switch state {
        case .Init: print("Init"); return "Init"
        case .Ready: print("Ready"); return "Ready"
        case .Play: print("Play"); return "Play"
        case .Pause: print("Pause"); return "Pause"
        case .GameOver: print("GameOver"); return "GameOver"
        }
    }
}


//
// MatchGameFSM class
//
class MatchGameFSM : NSObject {
    
    // current state
    var currState: MatchGameState = .Init
    
    
    // state machine
    var gameStateMachine: StateMachine<MatchGameState>!
    
    
    // MARK: - Singleton
    class var shared: MatchGameFSM {
        struct Singleton {
            static let instance = MatchGameFSM()
        }
        return Singleton.instance
    }
    
    // MARK: initialization
    
    private override init() {
        super.init()
        createStateMachine()
    }
    
    
    
    // MARK: private functions
    private func createStateMachine() {
        
        // create state
        let initialize = State(MatchGameState.Init)
        let ready = State(MatchGameState.Ready)
        let play = State(MatchGameState.Play)
        let pause = State(MatchGameState.Pause)
        let gameOver = State(MatchGameState.GameOver)
        
        // create event
        let readyEvent = Event(name: "Ready", sourceValues: [MatchGameState.Init], destinationValue: MatchGameState.Ready)
        let playEvent = Event(name: "Play", sourceValues: [MatchGameState.Ready], destinationValue: MatchGameState.Play)
        let pauseEvent = Event(name: "Pause", sourceValues: [MatchGameState.Play], destinationValue: MatchGameState.Pause)
        let resumeEvent = Event(name: "Resume", sourceValues: [MatchGameState.Pause], destinationValue: MatchGameState.Play)
        let cancelEvent = Event(name: "Cancel", sourceValues: [MatchGameState.Pause, MatchGameState.Play], destinationValue: MatchGameState.GameOver)
        let gameOverEvnet = Event(name: "GameOver", sourceValues: [MatchGameState.Play], destinationValue: MatchGameState.GameOver)
        let initEvnet = Event(name: "Init", sourceValues: [MatchGameState.GameOver], destinationValue: MatchGameState.Init)
        
        // create state machine
        gameStateMachine = StateMachine(initialState: initialize, states: [initialize, ready, play, pause, gameOver])
        
        gameStateMachine.addEvents([readyEvent, playEvent, pauseEvent, resumeEvent, cancelEvent, gameOverEvnet, initEvnet])
    }
    
    // MARK: public functions
    
    func changeState(event: String, run: fatchTranslate = nil) {
        let transition = gameStateMachine.fireEvent(event)
        switch transition {
        case .success(_,_):
            let state = gameStateMachine.currentState
            currState = state.value
            run?()
        case .error( _): break
        }
    }
}

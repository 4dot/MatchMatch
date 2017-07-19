//: Playground - noun: a place where people can play

import Transporter

enum MatchGameState : Int {
    case Start
    case Cancel
    case Pause
    case Resume
    case Play
    case CheckEnd
    case End
    
    static let all = [Start, Cancel, Pause, Resume, Play, CheckEnd, End]
    
    static func printState(_ state: MatchGameState) {
        switch state {
            case .Start: print("Start")
            case .Cancel: print("Cancel")
            case .Pause: print("Pause")
            case .Resume: print("Resume")
            case .Play: print("Play")
            case .CheckEnd: print("CheckEnd")
            case .End: print("End")
        }
    }
}


let start = State(MatchGameState.Start)
start.didEnterState = { _ in MatchGameState.printState(MatchGameState.Start) }
let cancel = State(MatchGameState.Cancel)
cancel.didEnterState = { _ in MatchGameState.printState(MatchGameState.Cancel) }
let pause = State(MatchGameState.Pause)
pause.didEnterState = { _ in MatchGameState.printState(MatchGameState.Pause) }
let play = State(MatchGameState.Play)
play.didEnterState = { _ in MatchGameState.printState(MatchGameState.Play) }
let end = State(MatchGameState.End)
end.didEnterState = { _ in MatchGameState.printState(MatchGameState.End) }



let playEvent = Event(name: "Play", sourceValues: [MatchGameState.Start], destinationValue: MatchGameState.Play)
let pauseEvent = Event(name: "Pause", sourceValues: [MatchGameState.Play], destinationValue: MatchGameState.Pause)
let resumeEvent = Event(name: "Resume", sourceValues: [MatchGameState.Pause], destinationValue: MatchGameState.Play)
let cancelEvent = Event(name: "Cancel", sourceValues: [MatchGameState.Pause, MatchGameState.Play], destinationValue: MatchGameState.End)

let matchGame = StateMachine(initialState: start, states: [cancel, pause, play, end])

matchGame.addEvents([playEvent, pauseEvent, resumeEvent, cancelEvent])

matchGame.fireEvent("Play")
matchGame.fireEvent("Pause")
matchGame.fireEvent("Resume")
matchGame.fireEvent("Cancel")

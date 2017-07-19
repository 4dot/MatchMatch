//
//  MainViewController.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/23/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import UIKit
import CNPPopupController
import NVActivityIndicatorView


//
// MainViewController class
//
class MainViewController: UIViewController {

    
    @IBOutlet weak var cardCollectionView: UICollectionView!
    
    // player boards (for multi)
    @IBOutlet weak var redTeamBoardView: UIView!
    @IBOutlet weak var blueTeamBoardView: UIView!
    
    @IBOutlet var playerScoreLabel: [UILabel]!
    
    // grid size (slider and size label)
    @IBOutlet weak var rowsSlider: UISlider!
    @IBOutlet weak var colsSlider: UISlider!
    @IBOutlet weak var rowsCntLabel: UILabel!
    @IBOutlet weak var colsCntLabel: UILabel!
    
    // timer label
    @IBOutlet weak var timerLabel: UILabel!
    
    // play type switch(single or multi)
    @IBOutlet weak var playTypeSwitch: UISwitch!
    
    // ready, play button
    @IBOutlet weak var playButton: UIButton!
    
    // popover view
    var popupController: CNPPopupController?
    
    // loading view
    var loadingView: NVActivityIndicatorView?
    
    // card collectionview data source
    var cardCollectionViewDataSource: MatchCollectionViewDataSource!
    
    // card game manager
    var gameMgr: MatchGameManager!
    
    deinit {
        // remove observers
        gameMgr.removeObserver(self, forKeyPath: "timerString")
        gameMgr.removeObserver(self, forKeyPath: "currentState")
        gameMgr.removeObserver(self, forKeyPath: "currentTurn")
    }
    
    
    // MARK: - override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // create game manager
        gameMgr = MatchGameManager.shared
        
        // add observers to game manager
        gameMgr.addObserver(self, forKeyPath: "timerString", options: .new, context: nil)
        gameMgr.addObserver(self, forKeyPath: "currentState", options: .new, context: nil)
        gameMgr.addObserver(self, forKeyPath: "currentTurn", options: .new, context: nil)
        
        // create loading view
        loadingView = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x-25, y: self.view.center.y-25, width: 50, height: 50),
                                              type: .ballClipRotate,
                                              color: .orange,
                                              padding: NVActivityIndicatorView.DEFAULT_PADDING)
        loadingView?.startAnimating()
        loadingView?.isHidden = true
        self.view.addSubview(loadingView!)
        
        // create data source
        cardCollectionViewDataSource = MatchCollectionViewDataSource()
        cardCollectionView.dataSource = cardCollectionViewDataSource
        
        // init UI
        // set play type
        playTypeSwitch.isOn = gameMgr.playType == .Multi ? true : false
        
        // set slider value
        rowsSlider.setValue(Float(gameMgr.cardRows/2), animated: true)
        colsSlider.setValue(Float(gameMgr.cardCols/2), animated: true)
        rowsCntLabel.text = "\(gameMgr.cardRows)"
        colsCntLabel.text = "\(gameMgr.cardCols)"
        
        // start with 'new game'
        playButton.setTitle("New Game", for: .normal)
    }

    /**
     @desc observeValue, receive notify from gameMgr (timer update, state change, turn change)
    */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[.newKey] {
            if keyPath == "timerString" {
                // update timer
                timerLabel.text = newValue as? String
            }
            else if keyPath == "currentState" {
                let state = MatchGameState(rawValue: (newValue as? Int) ?? 0)!
                changeGameState(state: state)
            }
            else if keyPath == "currentTurn" {
                setCurrentTurn(to: TeamType(rawValue: gameMgr.currentTurn)!)
            }
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    
    // MARK: public functions
        
    func requestNewCards() {
        
        // show loading hud
        loadingView?.isHidden = false
        
        // request cards (row * col)
        cardCollectionViewDataSource.requestCards(rows: gameMgr.cardRows, cols: gameMgr.cardCols,  complete: { [weak self] (success, cards) in
            
            guard let strongSelf = self else {
                return
            }
            if success {
                
                // save game cards
                strongSelf.gameMgr.gameCards = cards
                
                // update UI
                DispatchQueue.main.async {
                    strongSelf.cardCollectionView.reloadData()
                    
                    // ready to play
                    strongSelf.readyToPlay()
                }
            }
            
            // hide loading hud
            strongSelf.loadingView?.isHidden = true
        })
    }
    
    /**
     * @desc nofity form gameMgr when game state was changed
     * @param state changed state
     */
    func changeGameState(state: MatchGameState) {
        print("changed game state to \(MatchGameState.printState(state))")
        
        // disable UI
        enableUI(isEnable: false)
        
        switch state {
        case .Init:
            // request new cards
            initGame()
        case .Ready:
            // ready to start
            requestNewCards()
        case .Play:
            playGame()
        case .GameOver:
            // show popup view
            showResult()
        default:
            break
        }
    }
    
    /**
     * @desc initialize game UI
     */
    func initGame() {
        
        // set score to 0
        updateScore()
        
        // enable UI
        enableUI(isEnable: true)
        
        // flip back all
        for cell in cardCollectionView.visibleCells {
            if let cardCell = cell as? MatchCollectionViewCell {
                cardCell.flipCard(to: .Back, optiions: .transitionFlipFromRight, complete: nil)
            }
        }
    }
    
    /**
     * @desc enable/disable settings UI
     * @param isEnable true/false
     */
    func enableUI(isEnable: Bool) {
        
        // disable play type switch
        playTypeSwitch.isEnabled = isEnable
        
        // disable slider
        colsSlider.isEnabled = isEnable
        rowsSlider.isEnabled = isEnable
    }
    
    /**
     * @desc update score UI, get a score from gameMgr
     */
    func updateScore() {
        for label in playerScoreLabel {
            label.text = NSString(format: "%02d", gameMgr.gameScore[label.tag]) as String
        }
    }
    
    func readyToPlay() {
        // enable play button
        playButton.setTitle("Play", for: .normal)
        playButton.isEnabled = true
    }
    
    func playGame() {
        playButton.setTitle("GameOver", for: .normal)
        
        // show popover msg
        showResultPopup(title: NSAttributedString(string: ""), msg: NSAttributedString(string: "START"), image: "", popupStyle: .centered)
        
        // dismiss after 0.5 sec
        let when = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
            self?.popupController?.dismiss(animated: true)
        }
    }
    
    /**
     @desc show result popup view
    */
    func showResult() {
        var msg = ""
        if gameMgr.playType == .Multi {
            if gameMgr.getScore(.Red) == gameMgr.getScore(.Blue) {
                msg = "Draw!"
            } else {
                msg = gameMgr.getScore(.Red) > gameMgr.getScore(.Blue) ? "Red Team Win!" : "Blue Team Win!"
            }
        }else {
            // single play message
            msg = "Play time : \(timerLabel.text!) sec"
        }
        
        // show popup view with message
        showResultPopup(title: NSAttributedString(string: ""), msg: NSAttributedString(string: msg), image: "gameover", popupStyle: .centered)
    }
    
    /**
     @desc changed current turn
     @param turn current selected team
    */
    func setCurrentTurn(to turn: TeamType) {
        
        if gameMgr.playType == .Single {
            return
        }
        
        let isRedTurn = (turn == .Red)
        let prevTurn = isRedTurn ? blueTeamBoardView : redTeamBoardView
        let currTurn = isRedTurn ? redTeamBoardView : blueTeamBoardView
        let bgColor = isRedTurn ? UIColor.red.withAlphaComponent(0.2) : UIColor.blue.withAlphaComponent(0.2)
        
        // changing teams background color
        UIView.animate(withDuration: 0.2, animations: {
            prevTurn?.backgroundColor = .groupTableViewBackground
            currTurn?.backgroundColor = bgColor
        })
    }
    
    /**
     * @desc select a one of cards
     * @param targetCell selected collection view's cell
     * @param indexPath selected collection view's section and row
     */
    func selectCardCell(_ targetCell: MatchCollectionViewCell, _ indexPath: IndexPath) {
        
        // play mode only
        if gameMgr.getCurrentState() != .Play {
            return
        }
        
        // flip ainmation
        targetCell.flipCard(to: .Front, optiions: .transitionFlipFromLeft, complete: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            // grap a data before reset
            let prevSelectedCardRow = strongSelf.gameMgr.selectedCardRow
            let prevSelectedCardSection = strongSelf.gameMgr.selectedCardSection
            
            // get previous opend cell
            let prevCellPath = IndexPath(row: prevSelectedCardRow, section: prevSelectedCardSection)
            let prevCell = strongSelf.cardCollectionView.cellForItem(at: prevCellPath) as? MatchCollectionViewCell
            
            // open card deck
            let result = strongSelf.gameMgr.selectCard(section: indexPath.section, row: indexPath.row)
            
            // flip back two selected cards if not matched
            if result == .NotMatched {
                
                // close current selected card
                targetCell.flipCard(to: .Back, optiions: .transitionFlipFromRight, complete: nil)
                
                // close previous card
                prevCell?.flipCard(to: .Back, optiions: .transitionFlipFromRight, complete: nil)
            }
            // popup ainmation when cards ware matched
            else if (result == .Matched) {
                
                targetCell.popupCard(scale: 1.1, complete: nil)
                prevCell?.popupCard(scale: 1.1, complete: nil)
            }
            
            // update UI (score)
            strongSelf.updateScore()
        })
    }
    
    // MARK: IBActions
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        
        if gameMgr.getCurrentState() == .Init {
            gameMgr.runEvent(event: "Ready")
            return
        }

        // 'Play', 'Pause', 'Resume'
        if let btnText = sender.titleLabel?.text {
            gameMgr.runEvent(event: btnText)
        }
    }
    
    @IBAction func switchMultiModeTapped(_ sender: UISwitch) {
        
        // set a play type
        gameMgr.playType = sender.isOn ? .Multi : .Single
        
        // hide blue team
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.blueTeamBoardView.isHidden = !sender.isOn
            
            // update red team bg
            self?.redTeamBoardView.backgroundColor = (sender.isOn == false) ?
                .groupTableViewBackground : UIColor.red.withAlphaComponent(0.1)
        })
    }
    
    /**
     * @desc call when slider bar value changed, update value text and gameMgr
     * @param sender UISlider
     */
    @IBAction func cellSizeChanged(_ sender: UISlider) {
        
        // even number only (2, 4, 6, 8)
        let value = Int(sender.value) * 2
        
        // update count label
        
        // rows slider changed
        if sender.tag == 0 {
            rowsCntLabel.text = "\(value)"
            gameMgr.cardRows = value
        } else {
            colsCntLabel.text = "\(value)"
            gameMgr.cardCols = value
        }
    }
}

extension MainViewController : UICollectionViewDelegate {
    
    // MARK: - UICollectionViewDelegate
    
    /**
     * @desc when selected cell (one of cards)
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? MatchCollectionViewCell {
            selectCardCell(selectedCell, indexPath)
        }
    }
}

extension MainViewController : UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    /**
     * @desc set item size, cell align center
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let collectionViewSize = (gameMgr.cardCols < gameMgr.cardRows) ?
            collectionView.frame.size.height : collectionView.frame.size.width
        
        // 20 : left + right space
        // 10 : inset
        let cellSize = (collectionViewSize - 20) / CGFloat(max(gameMgr.cardRows, gameMgr.cardCols)) - 10
        
        // set item size
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: cellSize, height: cellSize)
            layout.invalidateLayout()
        }

        // cell align center
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: section))
        let combinedItemWidth = (numberOfItems * cellSize) + ((numberOfItems - 1)  * flowLayout.minimumInteritemSpacing)
        let padding = max(0, (collectionView.frame.width - combinedItemWidth) / 2)
        
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}

extension MainViewController : CNPPopupControllerDelegate {
    
    /**
     * @desc show result popover view
     * @param title title
     * @param msg message
     * @param popupStyle popup view style
     */
    func showResultPopup(title: NSAttributedString, msg: NSAttributedString, image: String, popupStyle: CNPPopupStyle) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0;
        titleLabel.attributedText = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Papyrus", size: 22)
        
        let lineOneLabel = UILabel()
        lineOneLabel.textAlignment = .center
        lineOneLabel.numberOfLines = 0;
        lineOneLabel.attributedText = msg;
        lineOneLabel.textColor = .white
        lineOneLabel.font = UIFont(name: "Papyrus", size: 32)
        
        let imageView = UIImageView.init(image: UIImage.init(named: image))
        imageView.frame = CGRect(x: 20, y: lineOneLabel.frame.origin.y+8, width: 300, height: 57)
        imageView.contentMode = .scaleAspectFit
        
        let popup = CNPPopupController(contents:[titleLabel, lineOneLabel, imageView])
        popup.theme = CNPPopupTheme.default()
        popup.theme.popupStyle = popupStyle
        popup.theme.backgroundColor = .black
        popup.theme.animationDuration = 0.2
        popup.delegate = self
        popupController = popup
        popupController?.present(animated: true)
    }
    
    // MARK: - CNPPopupControllerDelegate
    
    func popupControllerWillDismiss(_ controller: CNPPopupController) {
        print("Popup controller will be dismissed")
        
        if gameMgr.getCurrentState() == .Play {
            return
        }
        
        // goto init state
        gameMgr.runEvent(event: "Init")
        
        // enable play button
        playButton.isEnabled = true
        playButton.setTitle("New Game", for: .normal)
    }
    
    func popupControllerDidPresent(_ controller: CNPPopupController) {
        print("Popup controller presented")
    }
}

//
//  MatchCollectionViewCell.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/23/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import Foundation
import UIKit


let MATCH_COLLECTIONVIEW_CELL_ID = "MATCH_COLLECTIONVIEW_CELL_ID"


enum CardViewType : Int {
    case Back = 0, Front
    
    static let all = [ Back, Front]
}

//
// MatchCollectionViewCell Class
//
class MatchCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet var imageView: [UIImageView]!
    
    var currViewType: CardViewType = .Back
    /**
     @desc Clear UI
     */
    func clear() {
        for type in CardViewType.all {
            imageView[type.rawValue].image = nil
        }
        
        // hide front image
        imageView[CardViewType.Front.rawValue].isHidden = true
        imageView[CardViewType.Back.rawValue].isHidden = false
    }
    /**
     @desc flip animation
     @param options UIViewAnimationOptions
     @param complte callback
    */
    func flipCard(to: CardViewType, optiions: UIViewAnimationOptions, complete: (()->Void)?) {
        
        if currViewType == to {
            return
        }
        
        let from: CardViewType = (to == .Back) ? .Front : .Back
        currViewType = to
        
        // transition animation
        UIView.transition(with: self.contentView,
                          duration: 0.5,
                          options: optiions,
                          animations: { [weak self] in
            
                            self?.imageView[from.rawValue].isHidden = true
                            self?.imageView[to.rawValue].isHidden = false
        }, completion: { finished in
            complete?()
        })
    }
    /**
     @desc scale animation
    */
    func popupCard(scale: CGFloat, complete: (()->Void)?) {
        
        self.layer.transform = CATransform3DMakeScale(scale, scale, scale)
        UIView.animate(withDuration: 0.2, animations: {
            self.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }, completion: { finished in
            complete?()
        })
    }
}

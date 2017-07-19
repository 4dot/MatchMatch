//
//  MatchCard.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/23/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

/**
 @desc Card Data Model Class
 */
class MatchCard : NSObject {
    
    var id: String = ""
    var title: String = ""
    var placeHolderURL: String = ""
    var frontImageURL: String = ""
    
    
    // MARK: - Init
    /**
     @desc Init Movie data with id and name
     */
    init(_ id: String, _ title: String) {
        self.id = id
        self.title = title
    }
    
    /**
     @desc Init Movie data with SwiftyJON
     */
    init(with json: JSON) {
        self.id = json["id"].string ?? ""
        self.title = json["title"].string ?? ""
        self.frontImageURL = json["url_n"].string ?? ""
    }
}

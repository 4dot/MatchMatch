//
//  MatchCollectionViewDataSource.swift
//  MatchMatch
//
//  Created by Park, Chanick on 5/23/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON


// game card type
typealias gameCardType = (opend: Bool, matched: Bool, card: MatchCard)

//
// MatchCollectionViewDataSource Class
//
class MatchCollectionViewDataSource : NSObject, UICollectionViewDataSource {
    
    // game cards
    var cards: [gameCardType] = []
    
    // place hoder image
    var placeHoder: MatchCard!
    
    // total = rows * cols
    var rowsCnt: Int = 0
    var colsCnt: Int = 0
    
    /**
     @desc Request random images
     @param count request count
     */
    func requestCards(rows: Int, cols: Int, complete: @escaping (Bool, [gameCardType])->Void) {
        
        let params: [String : Any] = ["tags" : "kitten",
                                  "per_page" : (rows * cols) / 2]  // request count/2
        
        // save rows, cols count for devide sections
        rowsCnt = rows
        colsCnt = cols
        
        cards.removeAll()
        
        flickrSearch(with: params) { [weak self] (success, cards) in
            
            guard let strongSelf = self else {
                complete(success, [])
                return
            }
            
            var imageURLs: [String] = []
            
            // save 2 times and shuffle
            for card in cards {
                strongSelf.cards.append((false, false, card))
                strongSelf.cards.append((false, false, card))
                
                imageURLs.append(card.frontImageURL)
            }
            
             // shuffle
            strongSelf.cards = strongSelf.cards.shuffled()
            
            // request images
            strongSelf.requestImages(from: imageURLs, complete: { (result, images) in
                complete(result, strongSelf.cards)
            })
        }
    }
    
    /**
     @desc Request random placeholder images
     */
    func requestPlaceHoder(complete: @escaping (Bool, MatchCard)->Void) {
        
        let params: [String : Any] = ["tags" : "card deck",
                                  "per_page" : 5]       // request 5 images information
        
        flickrSearch(with: params) { (success, cards) in
            
            // select one of 5
            let placeHolder = cards[Int(arc4random_uniform(UInt32(cards.count)))]
            complete(success, placeHolder)
        }
    }
    
    // MARK: - private functions
    
    /**
     @desc Request random images
     @param count request count
     */
    private func flickrSearch(with params: [String : Any], complete: @escaping (Bool, [MatchCard])->Void) {
        
        var parameters = params
        
        // add deault params
        parameters["method"] = FlickrSearchMethod
        parameters["api_key"] = APIKey
        parameters["format"] = "json"
        parameters["extras"] = "url_n"       // URL of small, 320 on longest side size image
        parameters["nojsoncallback"] = 1
        
        // request
        Alamofire.request(FlickrRestSeerviceURL,  method: .get, parameters: parameters)
            .validate()
            .responseJSON { [weak self] (response) in
                
                var searchedCards: [MatchCard] = []
                
                // request fail
                guard let _ = self else {
                    complete(false, searchedCards)
                    return
                }
                
                switch response.result {
                case .failure(let error):
                    print(error)
                    
                case .success:
                    if let values = response.result.value {
                        let json = JSON(values)
                        print("JSON: \(json)")
                        
                        // get photo list
                        let photos = json["photos"]["photo"]
                        for (_, photoJson):(String, JSON) in photos {
                            
                            // add card data
                            let card = MatchCard(with: photoJson)
                            searchedCards.append(card)
                        }
                    }
                }
                
                // callback
                complete(true, searchedCards)
        }
    }
    
    /**
     @desc request images with URL, waiting until download all images using dispatch_group
    */
    private func requestImages(from URLs: [String], complete: @escaping (Bool, [Image])->Void) {
        
        // create dispatch group
        let downloadGroup = DispatchGroup()
        var images: [Image] = []
        
        let _ = DispatchQueue.global(qos: .userInitiated)
        DispatchQueue.concurrentPerform(iterations: URLs.count) { idx in
            let address = URLs[Int(idx)]
            downloadGroup.enter()
            
            // store to cache
            _ = CardImageManager.sharedInstance.retrieveImage(for: address, completion: { (image) in
                guard let img = image else { //?.cgImage?.copy()
                    complete(false, images)
                    return
                }
                // copy image
                //let newImage = UIImage(cgImage: img)
                
                // save
                images.append(img)
                downloadGroup.leave()
            })
        }
        
        // notifiy when finished download all
        downloadGroup.notify(queue: DispatchQueue.main) {
            complete(true, images)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if rowsCnt <= 0 {
            return 0
        }
        return cards.count / rowsCnt
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if colsCnt <= 0 {
            return 0
        }
        return cards.count / colsCnt
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MATCH_COLLECTIONVIEW_CELL_ID, for: indexPath) as! MatchCollectionViewCell
        cell.clear()
        
        // save card index
        cell.tag = indexPath.row + (indexPath.section * colsCnt)
        
        let card = cards[cell.tag]
        
        // default placeholder(back view)
        cell.imageView[CardViewType.Back.rawValue].image =
            UIImage(named: "placeHolder")?.af_imageRounded(withCornerRadius: 4.0)
        
        let imgURL = card.card.frontImageURL
        if imgURL.isEmpty {
            return cell
        }
        
        // Request image from cache (already stored cache)
        _ = CardImageManager.sharedInstance.retrieveImage(for: imgURL) { image in
            if image != nil {
                DispatchQueue.main.async {
                    // set front image
                    cell.imageView[CardViewType.Front.rawValue].image =
                        image?.af_imageRounded(withCornerRadius: 4.0)
                }
            }
        }
        
        return cell
    }
}

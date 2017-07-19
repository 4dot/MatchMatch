//
//  CardImageManager.swift
//  MatchMatch
//
//  Created by chanick park on 5/24/17.
//  Copyright © 2017 Chanick Park. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

extension UInt64 {
    
    func megabytes() -> UInt64 {
        return self * 1024 * 1024
    }
    
}

//
// CardImageManager class
// Request Image from image URL if not exist image cache
//
class CardImageManager {
    
    // MARK: - Singleton
    class var sharedInstance: CardImageManager {
        struct Singleton {
            static let instance = CardImageManager()
        }
        return Singleton.instance
    }
    
    let imageCache = AutoPurgingImageCache(
        memoryCapacity: UInt64(100).megabytes(),
        preferredMemoryUsageAfterPurge: UInt64(60).megabytes()
    )
    
    //MARK: - Image Downloading
    
    func retrieveImage(for url: String, completion: @escaping (UIImage?) -> Void) -> Request? {
        // 1. search from image cache
        if let cachedImage = cachedImage(for: url) {
            completion(cachedImage)
            return nil
        }
        // 2. request to image url
        return Alamofire.request(url, method: .get).responseImage { response in
            guard let image = response.result.value else {
                completion(nil)
                return
            }
            completion(image)
            
            // save to cache
            self.cache(image, for: url)
        }
    }
    
    //MARK: - Image Caching
    
    func cache(_ image: Image, for url: String) {
        imageCache.add(image, withIdentifier: url)
    }
    
    func cachedImage(for url: String) -> Image? {
        return imageCache.image(withIdentifier: url)
    }
}

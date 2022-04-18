//
//  CacheManager.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    // 6MB on memory, 40MB on disk
    let cacheStorage = URLCache(memoryCapacity: 6*1024*1024, diskCapacity: 40*1024*1024, diskPath: nil)
    
    /// Check if the request has cached before. If image exists return image or just return nil.
    func getImageFromCache(request: URLRequest) -> UIImage? {
        if let cachedData = self.cacheStorage.cachedResponse(for: request) {
            let image = UIImage(data: cachedData.data)
            return image
        } else {
            return nil
        }
    }
    
    /// Store image in cache
    func storeAtCache(data: CachedURLResponse, request: URLRequest) {
        self.cacheStorage.storeCachedResponse(data, for: request)
    }
}

//
//  CacheManager.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Foundation
import UIKit

/// 이미지 데이터의 캐싱을 담당하는 매니저 클래스입니다
/// 싱글톤 객체를 통해 접근이 가능합니다
class CacheManager {
    static let shared = CacheManager()
    
    // 6MB on memory, 40MB on disk
    let cacheStorage = URLCache(memoryCapacity: 6*1024*1024, diskCapacity: 40*1024*1024, diskPath: nil)
    
    /// 캐시에 이미지가 있는지 확인합니다. 캐시에 이미지가 존재한다면 이미지를, 그렇지 않다면 nil을 반환합니다
    func getImageFromCache(request: URLRequest) -> UIImage? {
        if let cachedData = self.cacheStorage.cachedResponse(for: request) {
            let image = UIImage(data: cachedData.data)
            return image
        } else {
            return nil
        }
    }
    
    /// 캐시에 이미지를 저장합니다
    func storeAtCache(data: CachedURLResponse, request: URLRequest) {
        self.cacheStorage.storeCachedResponse(data, for: request)
    }
}

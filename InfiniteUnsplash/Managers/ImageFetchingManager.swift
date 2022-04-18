//
//  ImageFetchingManager.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Foundation
import Combine
import UIKit

class ImageFetchingManager {
    /// base URL(https://api.unsplash.com)
    static var baseUrlComponents: URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        
        return urlComponents
    }
    
    /// It helps async processing of random image series retrieved from GET /photos request.
    static func fetchImageMetaData(page: Int) -> AnyPublisher<[ImageMetaData], Error> {
        var urlComponents = baseUrlComponents
        urlComponents.path = "/photos"
        urlComponents.queryItems = [
            // Query page
            URLQueryItem(name: "page", value: String(page)),
            
            // Data for a page
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Client-ID \(YOUR_API_KEY)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .retry(3)
            .tryMap { (data, response) -> Data in
                print(response)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [ImageMetaData].self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    /// Fetching each image's meta data.
    /// If image already exists in cache, return the image from the cache.
    static func downloadImage(url: String) -> AnyPublisher<UIImage, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let request = URLRequest(url: url)
            
        // Check cache
        if let image = CacheManager.shared.getImageFromCache(request: request) {
            // Hit
            return Just<UIImage>(image)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            // Miss
            return URLSession.shared.dataTaskPublisher(for: url)
                .timeout(10, scheduler: RunLoop.main, customError: { URLError(.timedOut) })
                .retry(3)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        throw URLError(.badServerResponse)
                    }
                    
                    // Save in cache
                    let cache = CachedURLResponse(response: response, data: data)
                    CacheManager.shared.storeAtCache(data: cache, request: request)

                    return data
                }
                .tryMap {
                    guard let image = UIImage(data: $0) else {
                        throw URLError(.cannotDecodeContentData)
                    }
                    
                    return image
                }
                .eraseToAnyPublisher()
        }
    }
    
    /// Caching image data. This function returns nothing and doesn't ensure success in caching.
    static func cacheImage(url: String)  {
        guard let url = URL(string: url) else {
            return
        }
        
        let request = URLRequest(url: url)
            
        // Check cache
        if CacheManager.shared.getImageFromCache(request: request) != nil {
            // Hit
            return
        } else {
            // Miss
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                if error != nil {
                    return
                }
                
                guard let response = response as? HTTPURLResponse,
                      200..<300 ~= response.statusCode
                else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                // Save in cache
                let cache = CachedURLResponse(response: response, data: data)
                CacheManager.shared.storeAtCache(data: cache, request: request)
            })
            .resume()
        }
    }
}

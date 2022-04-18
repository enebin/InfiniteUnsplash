//
//  ExploreViewModel.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Combine
import UIKit

class ExploreViewModel {
    private var subscriptions = Set<AnyCancellable>()
    private let utilityQueue = DispatchQueue(label: "utilityQueue", qos: .utility)
    
    /// Page currently loaded
    var loadedPage = 1
    /// ImageMetaData array
    let imageMetaData = CurrentValueSubject<[ImageMetaData], Never>([])
    /// Show request's process
    let process = CurrentValueSubject<Process, Never>(.ready)

    /// Fetch image data for corresponding page
    func fetchImageMetaData(page: Int) {
        ImageFetchingManager.fetchImageMetaData(page: page)
            .subscribe(on: utilityQueue)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                
                // Handle any error in here
                switch result {
                case .failure(let error):
                    self.process.send(.failedWithError(error: error))
                    break
                default:
                    self.process.send(.finished)
                }
                
                self.subscriptions.removeAll()
            }, receiveValue: { [weak self] receivedValue in
                guard let self = self else { return }
                
                if page == 1 {
                    // Overwrite when page is 1
                    self.imageMetaData.send(receivedValue)
                } else {
                    // Append when page is not 1 (more than 1)
                    let oldValue = self.imageMetaData.value
                    let newValue = oldValue + receivedValue
                    self.imageMetaData.send(newValue)
                }
            })
            .store(in: &subscriptions)
    }
    
    func preCaching(source: ImageMetaData) {
        ImageFetchingManager.cacheImage(url: source.smallSizedImageUrl)
    }
    
    init() {
        self.fetchImageMetaData(page: 1)
    }
}

//
//  ImageViewModel.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Combine
import UIKit

/// This view model should be injected from outside
/// Receiving url and author's name from outside and then handle the network event in asycn way
class ImageCellViewModel {
    private var subscriptions = Set<AnyCancellable>()
    
    let image = CurrentValueSubject<UIImage, Never>(UIImage())
    let author = CurrentValueSubject<String, Never>("")

    init(source: ImageMetaData) {
        ImageFetchingManager.downloadImage(url: source.smallSizedImageUrl)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print(error)
                default:
                    break
                }
            }, receiveValue: { [weak self] value in
                guard let self = self else { return }
                // Update image
                self.image.send(value)
                
                // Update author
                self.author.send(source.author)
            })
            .store(in: &subscriptions)
    }
}


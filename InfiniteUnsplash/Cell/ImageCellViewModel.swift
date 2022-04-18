//
//  ImageViewModel.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Combine
import UIKit

/// 각 셀에서 사용할 목적으로 주입되는 뷰 모델입니다.
/// 웹에서 이미지, 작가 정보와 같은 셀 내부 정보를 수신한 후 비동기적으로 업데이트 이벤트를 전달합니다.
class ImageCellViewModel {
    private var subscriptions = Set<AnyCancellable>()
    
    let image = CurrentValueSubject<UIImage, Never>(UIImage())
    let author = CurrentValueSubject<String, Never>("")

    // 외부에서 이미지 관련 데이터를 받아 뷰 모델 프로퍼티를 업데이트합니다
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
                // 이미지 업데이트
                self.image.send(value)
                
                // 작가 정보 업데이트
                self.author.send(source.author)
            })
            .store(in: &subscriptions)
    }
}


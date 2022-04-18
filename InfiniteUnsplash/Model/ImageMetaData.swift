//
//  Image.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Foundation
import UIKit

struct ImageMetaData: Decodable {
    let identifier = UUID()
    let height: Int
    let width: Int
    let color: String
    let user: User
    let urls: URLs
    
    /// It will be used to calculate image's height dynamically
    var imageRatio: CGFloat {
        return CGFloat(height) / CGFloat(width)
    }
    
    var author: String {
        return user.name
    }
    
    var smallSizedImageUrl: String {
        return urls.small
    }
    
    var thumbnailSizedImageUrl: String {
        return urls.thumb
    }
    
    struct URLs: Decodable {
        let small: String
        let thumb: String
    }

    struct User: Decodable {
        let name: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case height
        case width
        case color
        case user
        case urls = "urls"
    }
}

/// To use UICollectionViewDiffableDataSource, struct should be hashable
extension ImageMetaData: Hashable {
    func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    static func == (lhs: ImageMetaData, rhs: ImageMetaData) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

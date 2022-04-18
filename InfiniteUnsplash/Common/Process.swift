//
//  Process.swift
//  NewUnsplash
//
//  Created by 이영빈 on 2022/04/11.
//

import Foundation

enum Process {
    case ready
    case inProcess
    case finished
    case finishedWithEmptyResult
    case failedWithError(error: Error)
}

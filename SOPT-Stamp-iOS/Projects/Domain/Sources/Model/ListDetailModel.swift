//
//  ListDetailModel.swift
//  Presentation
//
//  Created by 양수빈 on 2022/11/28.
//  Copyright © 2022 SOPT-Stamp-iOS. All rights reserved.
//

import Foundation

public struct ListDetailModel {

    public let image, content, date: String
    public let stampId: Int

    public init(image: String, content: String, date: String, stampId: Int) {
        self.image = image
        self.content = content
        self.date = date
        self.stampId = stampId
    }
}

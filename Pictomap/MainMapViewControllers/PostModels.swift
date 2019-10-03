//
//  PostModels.swift
//  Party Time
//
//  Created by Artak on 2018-09-25.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit

class PhotosFromFeed: Codable {
    var link: String?
    var location: String?
    required init(_ link: String, location: String) {
        self.link = link
        self.location = location
    }
}


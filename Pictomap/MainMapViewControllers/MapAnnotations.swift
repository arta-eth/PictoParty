//
//  MapAnnotations.swift
//  Party Time
//
//  Created by Artak on 2018-09-25.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostAnnotation: MKPointAnnotation {
    
    var nodeName:String!
    var publisherUID:String!
    var image: UIImage?
    var likes: Int!
    var link: String?
    var city: String!
    var postCaption: String!
    var country: String!
    var timeStamp: String!
    var convertedTime: String?
    var convertedDate: String?
    var username: String!
    var fullName: String?
    var displayDate: String!
    var postID: String!
    var partyPicLink: String?
    var userImage: UIImage?
    var otherInfo: String?
    var active: Bool!
    var ambiguousTime: String!
    
    
    
    
    required init(link: String?, nodename: String, publisherUID: String, image: UIImage?, likes: Int, city: String, postID: String, country: String!, timeStamp: String!, convertedTime: String?, partyPicLink: String?, fullName: String?, username: String!, userImage: UIImage?, displayDate: String!, convertedDate: String?, otherInfo: String?, active: Bool!, ambiguousTime: String!) {
        
        self.link = link
        self.nodeName = nodename
        self.publisherUID = publisherUID
        self.image = image
        self.likes = likes
        self.city = city
        self.postID = postID
        self.country = country
        self.timeStamp = timeStamp
        self.convertedTime = convertedTime
        self.partyPicLink = partyPicLink
        self.username = username
        self.fullName = fullName
        self.userImage = userImage
        self.displayDate = displayDate
        self.convertedDate = convertedDate
        self.otherInfo = otherInfo
        self.active = active
        self.ambiguousTime = ambiguousTime
    }
    
       //fullVC.post = FeedPost(uid: selectedPost.publisherUID, isPic: true, picID: selectedPost.link, postCaption: "", uploadDate: , fullName: , username: , imageData: , userImage: , postID: , userImageID: )
    
    convenience override init() {

        self.init(link: "", nodename: "", publisherUID:  "", image: nil, likes: 0, city: "", postID: "", country: "", timeStamp: "", convertedTime:  nil, partyPicLink: nil, fullName: nil, username: nil, userImage: nil, displayDate: nil, convertedDate: nil, otherInfo: nil, active: false, ambiguousTime: nil)
    }
    
}


class SpinnerAnnotation: MKPointAnnotation {
    
    var initialSize: CGFloat!
    var finalSize: CGFloat!
    var id: String!
    var city: String!
    var country: String!
    
    required init(initialSize: CGFloat!, finalSize: CGFloat!, id: String!, city: String!, country: String!) {
        
        self.initialSize = initialSize
        self.finalSize = finalSize
        self.id = id
        self.city = city
        self.country = country
    }
    
}

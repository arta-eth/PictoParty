//
//  EventsViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-27.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SwiftKeychainWrapper
import FirebaseUI

class initState{
    
    var load = Bool()
    var unwind = Bool()
}

class UserInfo{
   
    static let uid = KeychainWrapper.standard.string(forKey: "USER")
    static var dp: UIImage?
    static var today: String?
    static var isDark: Bool?
}

class partyInfo{
    
    let reuseIdentifier = "PostsCell"
    var imageRef = String()
    var diskPartyList: [Party]! = nil
    var friendPartyList: [Party]! = nil
    var partyNode = String()
    var uid = String()
    var fromProfile = Bool()
    var image: UIImage? = nil
    
    
}

typealias DownloadComplete = () -> ()

class Party: Codable {
    let uploadDate: String
    var image: Data?
    var databaseReference: String?
    var imageLink: URL?
    
    required init(_ uploadDate: String, image: Data, databaseReference: String, imageLink: URL?) {
        self.uploadDate = uploadDate
        self.image = image
        self.databaseReference = databaseReference
        self.imageLink = imageLink
        
    }
}





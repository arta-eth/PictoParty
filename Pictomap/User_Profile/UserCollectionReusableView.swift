//
//  UserCollectionReusableView.swift
//  Pictomap
//
//  Created by Artak on 2018-09-28.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class UserCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var bioField: UITextView!
    @IBOutlet weak var editProfileBtn: UIButton!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var following: UILabel!
    
    
    override func layoutSubviews() {
        
        self.editProfileBtn.layer.cornerRadius = self.editProfileBtn.frame.height / 4
        self.editProfileBtn.clipsToBounds = true
        self.bioField.layer.cornerRadius = self.bioField.frame.height / 8
        self.bioField.clipsToBounds = true
    }
    
    
}


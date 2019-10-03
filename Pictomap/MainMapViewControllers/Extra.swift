//
//  Extra.swift
//  Pictomap
//
//  Created by Artak on 2019-07-10.
//  Copyright © 2019 artacorp. All rights reserved.
//

import Foundation
import UIKit

extension FullPostViewController{
    
    /*
    switch fromProfile {
    case false:
    if post.userImage != nil{
    
    self.userImg.image = UIImage(data: post.userImage!)
    self.usernameField.text = "@" + (post.username ?? "null")
    self.fullNameField.text = post.fullName
    
    //self.navigationItem.title = (post.fullName ?? "null") +  "'s Post"
    }
    else{
    self.downloadUserImg(uid: post.uid, completionHandler: { image, username, fullName, id in
    if image != nil{
    
    self.post.userImage = image
    self.post.username = username
    self.post.fullName = fullName
    self.post.userImageID = id
    self.userImg.image = UIImage(data: image!)
    self.usernameField.text = "@" + username
    self.fullNameField.text = fullName
    //self.navigationItem.title = (fullName) +  "'s Post"
    
    for (index, comment) in self.comments.enumerated() {
    //print("value \(index) is: \(element)")
    if comment.uid == self.post.uid{
    self.tableView.performBatchUpdates({
    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }, completion: nil)
    }
    }
    }
    })
    }
    case true:
    //self.navigationItem.title = (KeychainWrapper.standard.string(forKey: "FULL_NAME") ?? KeychainWrapper.standard.string(forKey: "USERNAME") ?? "User") +  "'s Post"
    self.usernameField.text = "@" +  (KeychainWrapper.standard.string(forKey: "USERNAME") ?? "null")
    self.fullNameField.text = KeychainWrapper.standard.string(forKey: "FULL_NAME") ?? "null"
    
    if let dp = UserInfo.dp{
    self.userImg.image = dp
    }
    else{
    self.downloadUserImg(uid: post.uid, completionHandler:{ image, username, fullName, id in
    if image != nil{
    
    KeychainWrapper.standard.set(username, forKey: "USERNAME")
    KeychainWrapper.standard.set(fullName, forKey: "FULL_NAME")
    UserInfo.dp = UIImage(data: image!)
    self.post.userImage = image
    self.post.username = username
    self.post.fullName = fullName
    self.post.userImageID = id
    self.userImg.image = UserInfo.dp
    self.usernameField.text = username
    self.fullNameField.text = fullName
    //self.navigationItem.title = (fullName) +  "'s Post"
    
    for (index, comment) in self.comments.enumerated() {
    //print("value \(index) is: \(element)")
    if comment.uid == self.post.uid{
    self.tableView.performBatchUpdates({
    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }, completion: nil)
    }
    }
    }
    })
    }
    }
 */
}

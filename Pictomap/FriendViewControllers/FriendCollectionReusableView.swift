//
//  FriendCollectionReusableView.swift
//  Pictomap
//
//  Created by Artak on 2018-09-29.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseUI
import SwiftKeychainWrapper
import OneSignal
import FirebaseFirestore

class FriendCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var biofield: UITextView!
    
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var follow: UIButton!
    var friendUID = String()
    var friendNotifID = String()
    var isFollowing = Bool()
    var woken = Bool()
    
    @IBAction func followUser(_ sender: UIButton) {
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        let notifID = KeychainWrapper.standard.string(forKey: "NOTIF")
        print(notifID ?? "")
        
        let ref = Firestore.firestore().collection("Users").document(uid!)
        let myFriendUIDRef = ref.collection("Following").document(friendUID)
        let myName = KeychainWrapper.standard.string(forKey: "USERNAME")
        
        if isFollowing{
            self.follow.updateFollowBtn(following: false)
            followUpload(uid: uid!, notifID: friendNotifID, myFriendUIDRef: myFriendUIDRef, myName: myName!, alreadyFollowing: true)
            self.isFollowing = false
        }
        else{
            self.follow.updateFollowBtn(following: true)
            followUpload(uid: uid!, notifID: friendNotifID, myFriendUIDRef: myFriendUIDRef, myName: myName!, alreadyFollowing: false)
            self.isFollowing = true
        }
    }
    
    func followUpload(uid: String, notifID: String, myFriendUIDRef: DocumentReference, myName: String, alreadyFollowing: Bool){
        

        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            switch alreadyFollowing{
            case true:
                myFriendUIDRef.delete(completion: { (err) in
                    if err != nil{
                        print(err?.localizedDescription ?? "")
                        return
                    }
                    else{
                        var currentFollowing = UserFollowing.userFollowing
                        currentFollowing.removeAll { $0 == self.friendUID }
                        UserDefaults.standard.set(currentFollowing, forKey: "followingList")
                        UserFollowing.userFollowing = currentFollowing
                        KeychainWrapper.standard.removeObject(forKey: "Following" + self.friendUID)
                    }
                })
                
            case false:
                myFriendUIDRef.setData(["UID" : friendUID], completion: { (err) in
                    
                    if err != nil{
                        print(err?.localizedDescription ?? "")
                        return
                    }
                    else{
                        var currentFollowing = UserFollowing.userFollowing
                        currentFollowing.append(self.friendUID)
                        let new = currentFollowing.removeDuplicates()
                        UserDefaults.standard.set(new, forKey: "followingList")
                        UserFollowing.userFollowing = currentFollowing
                        OneSignal.postNotification([
                            "headings": ["en": "New Follower"],
                            "contents": ["en": myName],
                            "include_player_ids": [self.friendNotifID],
                            "data": ["userID": uid]
                        ])
                    }
                })
            }
            
        }else{
            print("Internet Connection not Available!")
            follow.updateFollowBtn(following: !alreadyFollowing)
        }
    }
    
    func checkIfFollowing(uid: String){
        if UserFollowing.userFollowing.contains(friendUID){
            follow.updateFollowBtn(following: true)
            self.isFollowing = true
        }
            
        else{
            follow.updateFollowBtn(following: false)
            self.isFollowing = false
        }
        
        let ref = Firestore.firestore().collection("Users").document(uid).collection("Following").document(friendUID)
        
        ref.getDocument() { (snap, error) in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                self.isFollowing = false
                return
            }
                
            if !(snap?.exists ?? true){
                
                self.follow.updateFollowBtn(following: false)
                var currentFollowing = UserFollowing.userFollowing
                currentFollowing.removeAll { $0 == self.friendUID }
                UserDefaults.standard.set(currentFollowing, forKey: "followingList")
                UserFollowing.userFollowing = currentFollowing
                self.isFollowing = false
            }
                
            else{
                self.follow.updateFollowBtn(following: true)
                var currentFollowing = UserFollowing.userFollowing
                if !currentFollowing.contains(self.friendUID){
                    currentFollowing.append(self.friendUID)
                }
                let new = currentFollowing.removeDuplicates()
                UserDefaults.standard.set(new, forKey: "followingList")
                UserFollowing.userFollowing = currentFollowing
                self.isFollowing = true
            }
        }
    }
    
    override func layoutSubviews() {
        
        if !woken{
        super.layoutSubviews()
        self.follow.layer.cornerRadius = self.follow.frame.height / 4
        self.follow.clipsToBounds = true
        self.biofield.layer.cornerRadius = self.biofield.frame.height / 8
        self.biofield.clipsToBounds = true
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        print("yuh")
        checkIfFollowing(uid: uid!)
        woken = true
        }
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}

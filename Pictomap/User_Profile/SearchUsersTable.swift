//
//  SearchUsersTable.swift
//  Pictomap
//
//  Created by Artak on 2019-07-23.
//  Copyright © 2019 artacorp. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SDWebImage
import SwiftKeychainWrapper


class SearchedUser{
    
    var uid = String()
    var username: String? = nil
    var fullName: String? = nil
    var image: UIImage? = nil
    var bio: String?
    var dpLink: String? = nil
    var badges: [String]?
    var notifID: String?
    
    required init(uid: String, username: String?, fullName: String?, image: UIImage?, bio: String?, dpLink: String?, badges: [String]?, notifID: String?) {
        
        self.uid = uid
        self.username = username
        self.fullName = fullName
        self.image = image
        self.bio = bio
        self.dpLink = dpLink
        self.badges = badges
        self.notifID = notifID
    }
    
    convenience init() {
        self.init(uid: "", username: nil, fullName: nil, image: nil, bio: nil, dpLink: nil, badges: nil, notifID: nil)
    }
}

extension UserViewController{

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        self.downloader.cancelAllDownloads()
        
        if searchText == ""{
            self.loadedUsers.removeAll()
            self.getFollowers()
            
        }
        else{
            searchBar.isLoading = true
            let lowerCaseSearchText = searchText.lowercased()
            Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: lowerCaseSearchText).whereField("Username", isLessThanOrEqualTo: lowerCaseSearchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: { query, error in
                
                searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    self.loadedUsers.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                let uid = document.documentID
                                let username = document["Username"] as? String
                                let fullname = document["Full Name"] as? String
                                let bio = document["Bio"] as? String
                                let dpLink = document["ProfilePictureUID"] as? String
                                let badges = document["Badges"] as? [String]
                                let notifID = document["Notification ID"] as? String
                                if uid == KeychainWrapper.standard.string(forKey: "USER"){
                                    continue
                                }
                                if self.loadedUsers.contains(where: {$0.uid == uid}){
                                    continue
                                }
                                let user = SearchedUser(uid: uid, username: username, fullName: fullname, image: nil, bio: bio, dpLink: dpLink, badges: badges, notifID: notifID)
                                self.loadedUsers.append(user)
                                self.searchTable.reloadData()
                                let ref = Storage.storage().reference()
                                ref.child(uid + "/" + "profile_pic-" + (dpLink ?? "null") + ".png").downloadURL(completion: { url, error in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        self.downloader.downloadImage(with: url, options: .scaleDownLargeImages, progress: nil, completed: { (image, data, error, finished) in
                                            if error != nil{
                                                print(error?.localizedDescription ?? "")
                                                return
                                            }
                                            else{
                                                user.image = image
                                                if let index = self.loadedUsers.firstIndex(where: {$0.uid == uid}){
                                                    self.searchTable.performBatchUpdates({
                                                        
                                                        self.searchTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                                    }, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                        else{
                            self.searchTable.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    @objc func resign(){
        
        if search.isFirstResponder{
            search.endEditing(true)
            UIView.animate(withDuration: 0.2, animations: {
                self.searchTable.alpha = 0.0
            }, completion: {(finished : Bool) in
                self.searchTable.isHidden = true
            })
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        search.setShowsCancelButton(true, animated: true)
        
        searchTable.isHidden = false
        
        if let tabView = self.tabBarController as? TabBarVC{
            
            tabView.button.isHidden = true
            self.tabBarController?.tabBar.isHidden = true

            UIView.animate(withDuration: 0.2, animations: {
                
                self.searchTable.alpha = 1.0
            }, completion: {(finished : Bool) in
                if self.loadedUsers.isEmpty{
                    self.getFollowers()
                }
            })
        }
    }
    
    func getFollowers(){
        
        //print(uid!)
        

        let range = UserFollowing.userFollowing.removeDuplicates().prefix(8)
        
        if !range.isEmpty{
            for friend in range{
                Firestore.firestore().collection("Users").document(friend).getDocument(completion: { doc, err in
                    
                    if let document = doc{
                        let uid = document.documentID
                        let username = document["Username"] as? String
                        let fullname = document["Full Name"] as? String
                        let bio = document["Bio"] as? String
                        let dpLink = document["ProfilePictureUID"] as? String
                        let badges = document["Badges"] as? [String]
                        let notifID = document["Notification ID"] as? String
                        
                      
                        if self.loadedUsers.contains(where: {$0.uid == uid}){
                            return
                        }
                        let user = SearchedUser(uid: uid, username: username, fullName: fullname, image: nil, bio: bio, dpLink: dpLink, badges: badges, notifID: notifID)
                        self.loadedUsers.append(user)
                        self.searchTable.reloadData()
                        let ref = Storage.storage().reference()
                        ref.child(uid + "/" + "profile_pic-" + (dpLink ?? "null") + ".png").downloadURL(completion: { url, error in
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                self.downloader.downloadImage(with: url, options: .scaleDownLargeImages, progress: nil, completed: { (image, data, error, finished) in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                        return
                                    }
                                    else{
                                        user.image = image
                                        if let index = self.loadedUsers.firstIndex(where: {$0.uid == uid}){
                                            self.searchTable.performBatchUpdates({
                                                
                                                self.searchTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                            }, completion: nil)
                                        }
                                    }
                                })
                            }
                        })
                    }
                })
            }
        }
        else{
            self.searchTable.reloadData()
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text.contains(where: {$0.isUppercase || $0.isWhitespace}){
            return false
        }
        
        return true
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        search.endEditing(true)
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        search.setShowsCancelButton(false, animated: true)

    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        search.resignFirstResponder()
        search.setShowsCancelButton(false, animated: true)
        self.loadedUsers.removeAll()
        searchBar.isLoading = false
        searchTable.reloadData()
        searchBar.text?.removeAll()
        
        if let tabView = self.tabBarController as? TabBarVC{
            
            tabView.button.isHidden = false
            self.tabBarController?.tabBar.isHidden = false

            UIView.animate(withDuration: 0.2, animations: {
                
                self.searchTable.alpha = 0.0
            }, completion: {(finished : Bool) in
                self.searchTable.isHidden = true
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == searchTable{
            
            self.selectedUser = self.loadedUsers[indexPath.row]
            self.performSegue(withIdentifier: "friend", sender: nil)
        }
    }
    
}

//
//  FriendProfileViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-16.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import OneSignal
import SwiftKeychainWrapper
import FirebaseUI
import FirebaseFirestore




class FriendProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var userInfo = SearchedUser()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return userInfo.badges?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "BadgesCell", for: indexPath) as! UserBadgesCell
        
        if userInfo.badges?[indexPath.row] == "✓"{
            cell.badgeLabel.textColor = UIColor.white
            cell.badgeLabel.layer.cornerRadius = cell.badgeLabel.frame.height / 2
            cell.badgeLabel.clipsToBounds = true
            cell.badgeLabel.layer.borderColor = UIColor.white.cgColor
            cell.badgeLabel.layer.borderWidth = 1.0
            cell.badgeLabel.backgroundColor = UIColor(red: 0, green: 0.5902, blue: 0.9882, alpha: 1.0) /* #00b0fc */
        }
        else{
            cell.badgeLabel.textColor = UIColor.black
            cell.badgeLabel.layer.cornerRadius = 0
            cell.badgeLabel.clipsToBounds = true
            cell.badgeLabel.layer.borderWidth = 0.0
            cell.badgeLabel.backgroundColor = UIColor.white
        }
        
        cell.badgeLabel.text = userInfo.badges?[indexPath.row]
        return cell
    }
    
    var today = String()
    
    @IBOutlet weak var bioField: UITextView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.loadedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let user = self.loadedPosts[indexPath.row]
        let fullName = self.fullName.text
        let username = self.username.text
        let dp = self.profilePic.image
        
        
        //IF THE POST IS AN IMAGE-STYLE POST
        if user.isPic{
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "PictureFeedPost", for: indexPath) as? FeedPicturePostCell
            
            cell?.username.text = nil
            cell?.userImage.image = nil
            cell?.fullName.text = nil
            cell?.postPicture.image = nil
            cell?.postCaption.text = nil
            
            
            
            if user.imageData != nil{
                cell?.postPicture.image = UIImage(data: user.imageData!)
            }
            //SET CAPTION IF A CAPTION EXISTS IN POST ARRAY
            if user.postCaption != nil{
                cell?.postCaption.text = (user.uploadDate.findMonth(abbreviation: false) ?? "null") + "\n" + user.uploadTime
            }
            
            if !user.active{
                if user.uploadDate == self.today{
                    cell?.postCaption.text = "Today\n" + user.uploadTime
                }
                else{
                    cell?.postCaption.text = (user.uploadDate.findMonth(abbreviation: false) ?? "null") + "\n" + user.uploadTime
                }
            }
            
            
            if cell?.postCaption.delegate == nil{
                cell?.postCaption.delegate = self
            }
            
            
            /* SET USER IMAGE IF FULL USER DATA IS DOWNLOADED/EXISTS, LIKE:
             * USER IMAGE
             * FULL NAME
             * USERNAME
             */
            
            if dp != nil{
                cell?.userImage.image = dp
            }
            cell?.fullName.text = fullName
            cell?.username.text = username
            cell?.fullName.backgroundColor = UIColor.white
            cell?.username.backgroundColor = UIColor.white
            
            
            
            return cell!
        }
            
            // THE POST IS A TEXT STYLE POST
        else{
            
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "TextFeedPost", for: indexPath) as? FeedTextPostCell
            
            cell?.username.text = nil
            cell?.userImage.image = nil
            cell?.fullName.text = nil
            cell?.postCaption.text = nil
            
            
            //SET CAPTION IF A CAPTION EXISTS IN POST ARRAY
            if user.postCaption != nil{
                cell?.postCaption.text = (user.uploadDate.findMonth(abbreviation: false) ?? "null") + "\n" + user.uploadTime
            }
            
            if cell?.postCaption.delegate == nil{
                cell?.postCaption.delegate = self
            }
            
            /* SET USER IMAGE IF FULL USER DATA IS DOWNLOADED/EXISTS, LIKE:
             * USER IMAGE
             * FULL NAME
             * USERNAME
             */
            if dp != nil{
                cell?.userImage.image = dp
            }
            cell?.fullName.text = fullName
            cell?.username.text = username
            cell?.fullName.backgroundColor = UIColor.white
            cell?.username.backgroundColor = UIColor.white
            
            return cell!
        }
        
    }
    
    
    var friendUID = String()
    var friendNotifID = String()
    var loadedPosts = [FeedPost]()
    var isLoading = Bool()
    var downloader: SDWebImageDownloader! = nil
    var postClass: FeedPost! = nil
    var tokens: [[String : Any]]! = nil
    var profilePicToSet = UIImage()
    
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeader: UIView!
    
    @IBOutlet weak var follow: UIButton!
    var isFollowing = Bool()
    
    @IBOutlet weak var backView: UIView!
    
    override func viewDidDisappear(_ animated: Bool) {
        
        self.downloader.invalidateSessionAndCancel(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topConstraint.constant = 0//Screen.statusBarHeight
        self.navigationController?.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.follow.layer.cornerRadius = self.follow.frame.height / 4
        self.follow.clipsToBounds = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.view.backgroundColor = UIColor.black
        self.backView.roundCorners([UIRectCorner.topRight, UIRectCorner.topLeft], radius: self.view.frame.width / 20)
        self.setNavigationItem(button: .stop)
        self.today = self.getDate()
        self.username.text = "@" + (userInfo.username ?? "null")
        self.fullName.text = userInfo.fullName
        if userInfo.image != nil{
            self.profilePic.image = userInfo.image
        }
        else{
            if let picUID = userInfo.dpLink{
                let ref = Storage.storage().reference().child(userInfo.uid).child("profile_pic-" + picUID + ".png")
                self.downloadUserImg(ref: ref, completionHandler: { image in
                    if image != nil{
                        self.profilePic.image = image
                        for post in self.loadedPosts{
                            post.userImage = image?.jpegData(compressionQuality: 1.0)
                            post.userImageID = picUID
                        }
                        self.refresh(nil)
                    }
                })
            }
        }
        self.friendUID = userInfo.uid
        if let notif = userInfo.notifID{
            self.friendNotifID = notif
        }
        if let bio = self.userInfo.bio{
            self.bioField.text = bio
            self.adjustHeight()
        }
        if userInfo.badges != nil{
            self.collectionView.reloadData()
        }
        self.profilePic.layer.cornerRadius = self.profilePic.frame.height / 2
        self.profilePic.clipsToBounds = true
        //self.navigationItem.title = username
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
                                 action: #selector(refresh(_:)),
                                 for: .primaryActionTriggered)
        self.tableView.refreshControl = refreshControl
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        print("yuh")
        checkIfFollowing(uid: uid!)
        self.getPosts(refresh: refreshControl, fromInterval: "") {
            self.isLoading = false
        }
    }
    
    
    
    func setNavigationItem(button: UIBarButtonItem.SystemItem) {
        
        
        let button = UIBarButtonItem(barButtonSystemItem: button, target: self, action: #selector(self.goBack(_:)))
        button.tintColor = UIColor.lightGray
        
        self.navigationItem.leftBarButtonItem = button
    }
    
    @objc func goBack(_ sender: UIBarButtonItem){
        self.performSegue(withIdentifier: "back2friendsearch", sender: nil)
    }
    
    
    func adjustHeight(){
        
        let currentSize = self.bioField.frame.height
        
        let newSize = self.bioField.sizeThatFits(CGSize(width: self.bioField.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        var difference: CGFloat = 0
        
        if newSize > currentSize{
            difference = newSize - currentSize
            DispatchQueue.main.async {
                self.tableHeader.frame.size.height = self.tableHeader.frame.height + difference
                self.tableView.reloadData()
            }
            
        }
        else if newSize < currentSize{
            difference = currentSize - newSize
            DispatchQueue.main.async {
                self.tableHeader.frame.size.height = self.tableHeader.frame.height - difference
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func segueToChat(_ sender: UITapGestureRecognizer) {
        
        
        if sender.state == UIGestureRecognizer.State.ended {
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                //AudioServicesPlaySystemSound(1520)
                self.postClass = self.loadedPosts[indexPath.row]
                print(postClass.postCaption!)
                self.performSegue(withIdentifier: "full", sender: nil)
            }
        }
    }
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    ///* Dynamic Cell Sizing *///
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ///For every cell, retrieve the height value and store it in the dictionary
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 70.0
    }
    
    @objc func refresh(_ sender: UIRefreshControl?){
        
        self.today = self.getDate()
        Firestore.firestore().collection("Users").document(self.friendUID).getDocument(completion: { (document, err) in
            
            if err != nil{
                print(err?.localizedDescription ?? "")
            }
            else if document?.exists ?? false{
                
                if let badges = document?["Badges"] as? [String]{
                    self.userInfo.badges = badges
                    self.collectionView.reloadData()
                }
                if let username = document?["Username"] as? String{
                    self.username.text = "@" + username
                }
                if let fullname = document?["Full Name"] as? String{
                    self.fullName.text = fullname
                }
                else{
                    if let username = document?["Username"] as? String{
                        self.fullName.text = username
                    }
                }
                if let bio = document?["Bio"] as? String{
                    self.bioField.text = bio
                    self.adjustHeight()
                    
                }
                if let picUID = document?["ProfilePictureUID"] as? String{
                    
                    let ref = Storage.storage().reference().child(self.friendUID).child("profile_pic-" + picUID + ".png")
                    self.downloadUserImg(ref: ref, completionHandler: { image in
                        if image != nil{
                            self.profilePic.image = image
                            for post in self.loadedPosts{
                                post.userImage = image?.jpegData(compressionQuality: 1.0)
                                post.userImageID = picUID
                                if let index = self.loadedPosts.firstIndex(of: post){
                                    self.tableView.performBatchUpdates({
                                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                    }, completion: nil)
                                }
                            }
                        }
                    })
                }
            }
        })
        
        if sender?.isRefreshing ?? false{
            sender?.endRefreshing()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.getPosts(refresh: sender, fromInterval: "") {
                self.isLoading = false
            }
        }
    }
    
    func downloadUserImg(ref: StorageReference, completionHandler: @escaping (UIImage?) -> ()){
        
        ref.downloadURL(completion: { url, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                
                return
            }
            else{
                
                self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: nil, completed: { (image, data, error, finished) in
                    
                    if error != nil{
                        
                        print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                        
                        completionHandler(nil)
                        
                        return
                    }
                    else{
                        completionHandler(image) //PASS USER IMAGE TO COMPLETION HANDLER
                    }
                })
            }
        })
    }
    
    func downloadPostImage(index: Int, uid: String, picID: String){
        
        let ref = Storage.storage().reference()
        if self.tokens == nil{
            self.tokens = [[String : Any]]()
        }
        
        ref.child(uid + "/" + "Party-" + picID + ".jpg").downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                //SET POST IMAGE
                if let picturePost = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedPicturePostCell{
                    
                    picturePost.circularProgress.isHidden = false
                    let cp = picturePost.circularProgress
                    self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                        let dub = (Float(receivedSize) / Float(expectedSize))
                        cp.setProgressWithAnimation(duration: 0.2, value: dub, from: 0, finished: false){
                        }
                    },  completed: { (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            if data != nil{
                                cp.setProgressWithAnimation(duration: 0.2, value: 1, from: 0, finished: true){
                                    cp.removeFromSuperview()
                                    if self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) != nil || self.loadedPosts.indices.contains(index){
                                        self.loadedPosts[index].imageData = data
                                        self.tableView.performBatchUpdates({
                                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                        }, completion: nil)
                                    }
                                }
                            }
                            else{
                                picturePost.postPicture.image = image
                                if self.loadedPosts.indices.contains(index){
                                    self.loadedPosts[index].imageData = image?.jpegData(compressionQuality: 1.0)
                                }
                            }
                        }
                    })
                }
                else{
                    
                    let token = self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: nil,  completed: { (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            
                            if self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) != nil || self.loadedPosts.indices.contains(index){
                                self.loadedPosts[index].imageData = data
                                self.tableView.performBatchUpdates({
                                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                }, completion: nil)
                            }
                        }
                    })
                    if token != nil{
                        self.tokens.append(
                            ["Image ID" : picID,
                             "Token" : token!]
                        )
                    }
                }
            }
        })
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = self.loadedPosts.last{
                let interval = last.uploadDate
                self.getPosts(refresh: nil, fromInterval: interval){
                    self.isLoading = false
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if downloader == nil{
            self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
        
        
    }
    func getPosts(refresh: UIRefreshControl?, fromInterval: String, completed: @escaping DownloadComplete){
        
        
        /*
         QUERY COMMENTS:
         - ORDERING THE "Timestamp" VALUE BY THE EARLIEST TIME
         - STARTING FROM THE LOCAL \(fromInterval) VAR
         - RETRIEVING DOCUMENT SNAPSHOTS IN THE \(snapDocuments) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         - A COMMENT WILL EITHER BE A PICTURE OR TEXT, NOT BOTH
         */
        var query: Query! = nil
        
        
        if !self.isLoading{
            self.isLoading = true
            
            if refresh != nil{
                if refresh?.isRefreshing ?? true{
                    self.downloader.cancelAllDownloads()
                }
                self.loadedPosts.removeAll()
                self.cellHeights.removeAll()
                self.tableView.separatorStyle = .none
                self.tableView.reloadData()
                query = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Posts").whereField("Timestamp", isGreaterThanOrEqualTo: fromInterval).limit(to: 10).order(by: "Timestamp", descending: true)
            }
            else{
                query = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Posts").whereField("Timestamp", isLessThan: fromInterval).limit(to: 10).order(by: "Timestamp", descending: true)
            }
            completed()
            
            query.getDocuments(completion: { (snapDocuments, err) in
                
                if let err = err {
                    print("Error getting documents: \(err)")
                    return
                }
                else if snapDocuments?.isEmpty ?? true{
                    return
                }
                else {
                    
                    let fullName = self.fullName.text
                    let username = self.userInfo.username
                    guard let profilePic = self.userInfo.image?.jpegData(compressionQuality: 1.0) else{return}
                    
                    self.tableView.separatorStyle = .singleLine
                    
                    let snaps: [QueryDocumentSnapshot]? = snapDocuments?.documents
                    
                    for snap in snaps ?? []{ // LOADED DOCUMENTS FROM \(snapDocuments)
                        
                        if !self.loadedPosts.contains(where: {$0.postID == snap.documentID}){
                            let displayDate = snap["DisplayTime"] as? String // COMMENT TIMESTAMP
                            let timestamp = snap["Timestamp"] as? String // COMMENT TIMESTAMP
                            
                            let components = displayDate?.components(separatedBy: ", ")
                            var postTime = components?[1]
                            let date = components?[0]
                            
                            if postTime?.first == "0"{
                                postTime?.removeFirst()
                            }
                            
                            
                            var post = FeedPost()
                            
                            if let caption = snap["OtherInfo"] as? String{
                                
                                if let picID = snap["Picture"] as? String{
                                    
                                    post = FeedPost(uid: self.userInfo.uid, isPic: true, picID: picID, postCaption: caption, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: profilePic, postID: snap.documentID, userImageID: self.userInfo.dpLink, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                    self.downloadPostImage(index: self.loadedPosts.count - 1, uid: self.userInfo.uid, picID: picID)
                                }
                                else{
                                    
                                    post = FeedPost(uid: self.userInfo.uid, isPic: false, picID: nil, postCaption: caption, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: profilePic, postID: snap.documentID, userImageID: self.userInfo.dpLink, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                }
                            }
                            else{
                                if let picID = snap["Picture"] as? String{
                                    
                                    post = FeedPost(uid: self.userInfo.uid, isPic: true, picID: picID, postCaption: nil, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: profilePic, postID: snap.documentID, userImageID: self.userInfo.dpLink, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                    self.downloadPostImage(index: self.loadedPosts.count - 1, uid: self.userInfo.uid, picID: picID)
                                }
                            }
                            
                            let ambiguousTime = self.time(time: timestamp ?? "null")
                            let load = self.loadDate(ambiguous: true)
                            let current = self.currentDate()
                            
                            print("amb " + ambiguousTime)
                            print("curr " + current)
                            print("loa " + load)
                            if ambiguousTime <= current && ambiguousTime >= load{
                                
                                post.active = true
                            }
                            else{
                                post.active = false
                            }
                            
                            self.tableView.performBatchUpdates({
                                
                                self.tableView.insertRows(at: [IndexPath(row: self.loadedPosts.count - 1, section: 0)], with: .fade)
                            }, completion: { finished in
                                if finished{
                                    
                                }
                            })
                        }
                    }
                }
            })
        }
        else{
            if refresh?.isRefreshing ?? false{
                refresh?.endRefreshing()
            }
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
    
    override func viewDidLayoutSubviews() {
    }
    
    
    @IBAction func unwindToFriend(segue:  UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let full = segue.destination as? FullPostViewController{
            full.post = postClass
            full.fromProfile = false
            full.hidesBottomBarWhenPushed = true
        }
    }
}

extension FriendProfileViewController{
    
    
}

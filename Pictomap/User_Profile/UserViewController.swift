//
//  UserViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-06-25.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseUI
import FirebaseDatabase
import FirebaseAuth
import OneSignal
import FirebaseFirestore



class UserViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate, UITextViewDelegate, UINavigationControllerDelegate{
    
    
    @IBOutlet weak var backView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var loadedBadges = [String]()
    
    var loadedUsers = [SearchedUser]()
    
    var selectedUser: SearchedUser? = nil
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return loadedBadges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "BadgesCell", for: indexPath) as! UserBadgesCell
        
        if loadedBadges[indexPath.row] == "✓"{
            cell.badgeLabel.textColor = UIColor.white
            cell.badgeLabel.layer.cornerRadius = cell.badgeLabel.frame.height / 2
            cell.badgeLabel.clipsToBounds = true
            cell.badgeLabel.layer.borderColor = UIColor.white.cgColor
            cell.badgeLabel.layer.borderWidth = 1.0
            cell.badgeLabel.backgroundColor = UIColor(red: 0, green: 0.5902, blue: 0.9882, alpha: 1.0) /* #00b0fc */
        }
        else{
            if #available(iOS 13.0, *) {
                cell.badgeLabel.textColor = UIColor.label
            } else {
                cell.badgeLabel.textColor = UIColor.black
            }
            cell.badgeLabel.layer.cornerRadius = 0
            cell.badgeLabel.clipsToBounds = true
            cell.badgeLabel.layer.borderWidth = 0.0
        }
        
        cell.badgeLabel.text = loadedBadges[indexPath.row]
        return cell
    }
    
    var tokens: [[String : Any]]! = nil
    
    
    @IBAction func segueToChat(_ sender: UITapGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.ended {
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                //AudioServicesPlaySystemSound(1520)
                self.fullPost = self.loadedPosts[indexPath.row]
                self.performSegue(withIdentifier: "full", sender: nil)
            }
        }
    }
    
    
    
    
    
    let party = Details()
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userHeader: UIView!
    
    
    let uid = KeychainWrapper.standard.string(forKey: "USER")
    
    
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    var postClass: FeedPost! = nil
    var fullPost: FeedPost! = nil
    
    
    var loadedPosts = [FeedPost]()
    var isLoading = Bool()
    var downloader: SDWebImageDownloader! = nil
    
    
    func checkExists(){
        
        Firestore.firestore().collection("Users").document(uid!).collection("Posts").getDocuments(){  (snap, err) in
            
            if snap?.isEmpty ?? true{
                //Remove from File System
                self.removeFile(withName: "POST")
                UserDefaults.standard.set(true, forKey: "New_Post")
                self.tableView.reloadData()
                //NOT CHARGED
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cellHeights[indexPath] = cell.frame.size.height
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = self.loadedPosts.last{
                guard let interval = last.timestamp else { return }
                self.getPosts(refresh: nil, fromInterval: interval){
                    self.isLoading = false
                }
            }
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
                query = Firestore.firestore().collection("Users").document(uid!).collection("Posts").whereField("Timestamp", isGreaterThanOrEqualTo: fromInterval).limit(to: 10).order(by: "Timestamp", descending: true)
            }
            else{
                query = Firestore.firestore().collection("Users").document(uid!).collection("Posts").whereField("Timestamp", isLessThan: fromInterval).limit(to: 10).order(by: "Timestamp", descending: true)
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
                    
                    self.tableView.separatorStyle = .singleLine
                    
                    
                    let fullName = KeychainWrapper.standard.string(forKey: "FULL_NAME")
                    let username = KeychainWrapper.standard.string(forKey: "USERNAME")
                    let userImage = (self.profilePic.image ?? UIImage(named: "default_DP.png")!).jpegData(compressionQuality: 0.8)
                    
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
                                    
                                    post = FeedPost(uid: self.uid!, isPic: true, picID: picID, postCaption: caption, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: userImage, postID: snap.documentID, userImageID: nil, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                    self.downloadPostImage(index: self.loadedPosts.count - 1, uid: self.uid!, picID: picID)
                                }
                                else{
                                    
                                    post = FeedPost(uid: self.uid!, isPic: false, picID: nil, postCaption: caption, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: userImage, postID: snap.documentID, userImageID: nil, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                }
                            }
                            else{
                                if let picID = snap["Picture"] as? String{
                                    
                                    post = FeedPost(uid: self.uid!, isPic: true, picID: picID, postCaption: nil, uploadDate: date ?? "", fullName: fullName, username: username, imageData: nil, userImage: userImage, postID: snap.documentID, userImageID: nil, uploadTime: postTime ?? "", timestamp: timestamp, active: nil)
                                    
                                    self.loadedPosts.append(post)
                                    self.downloadPostImage(index: self.loadedPosts.count - 1, uid: self.uid!, picID: picID)
                                }
                            }
                            
                            let ambiguousTime = self.time(time: timestamp ?? "null")
                            let load = self.loadDate(ambiguous: true)
                            let current = self.currentDate()
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
                                    if self.loadedPosts.count == 10{
                                        self.removeFile(withName: "POSTS")
                                        self.saveAllObjects(allObjects: self.loadedPosts)
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
        else{
            if refresh?.isRefreshing ?? true{
                refresh?.endRefreshing()
            }
        }
    }
    
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView{
            return cellHeights[indexPath] ?? 70.0
        }
        else{
            return 70
        }
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
                                if let postImage = image{
                                    picturePost.postPicture.image = postImage
                                    if self.loadedPosts.indices.contains(index){
                                        
                                        self.loadedPosts[index].imageData = postImage.jpegData(compressionQuality: 1.0)
                                    }
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
                    self.tokens.append(
                        ["Image ID" : picID,
                         "Token" : token!]
                    )
                }
            }
        })
    }
    
    
    @IBAction func editProfile(_ sender: UIButton) {
        
        
        let popvc = UIStoryboard(name: "EditProfile", bundle: nil).instantiateViewController(withIdentifier: "edit") as! ProfileViewController
        self.addChild(popvc)
        popvc.hidesBottomBarWhenPushed = true
        popvc.view.frame = self.view.frame
        self.view.addSubview(popvc.view)
        popvc.didMove(toParent: self)
    }
    
    
    @IBOutlet weak var editBtn: UIButton!
    
    func adjustHeight(){
        
        let currentSize = self.bioField.frame.height
        
        let newSize = self.bioField.sizeThatFits(CGSize(width: self.bioField.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        var difference: CGFloat = 0
        
        if newSize > currentSize{
            difference = newSize - currentSize
            self.userHeader.frame.size.height = self.userHeader.frame.height + difference
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        else if newSize < currentSize{
            difference = currentSize - newSize
            self.userHeader.frame.size.height = self.userHeader.frame.height - difference
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        self.removeFile(withName: "POSTS")
        self.saveAllObjects(allObjects: self.loadedPosts)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let tabView = self.tabBarController as? TabBarVC{
            
            tabView.button.isHidden = false
            
            UIView.animate(withDuration: 0.1, animations: {
                tabView.button.alpha = 1.0
            })
        }
        
        
        if self.selectedUser != nil{
            search.becomeFirstResponder()
            self.selectedUser = nil
        }
 
        if let fullPost = self.postClass{

            if fullPost.isPic{
                
                if let samePost = self.loadedPosts.first(where: {$0.postID == fullPost.postID}){
                    
                    
                    samePost.uploadDate = fullPost.uploadDate
                    samePost.uploadTime = fullPost.uploadTime
                    samePost.postCaption = fullPost.postCaption
                    
                    if let index = self.loadedPosts.firstIndex(of: samePost){
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }, completion: nil)
                    }
                    
                    
                    if samePost.imageData != fullPost.imageData{
                        
                        samePost.imageData = fullPost.imageData
                        if let token = self.tokens.first(where: {$0["Image ID"] as? String == fullPost.picID}){
                            let tokenObject = token["Token"] as? SDWebImageDownloadToken
                            tokenObject?.cancel()
                        }
                        if let index = self.loadedPosts.firstIndex(of: samePost){
                            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedPicturePostCell{
                                cell.circularProgress.removeFromSuperview()
                            }
                            self.tableView.performBatchUpdates({
                                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                }
            }
            self.postClass = nil
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        
        if(scrollView.contentSize.height > scrollView.bounds.height){
            
            
            if(velocity.y > 1) {
                
                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                }, completion: nil)
                
            } else if (velocity.y < 0) {
                
                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                }, completion: nil)
            }
        }
        else if (self.navigationController?.navigationBar.isHidden ?? true) && scrollView.contentSize.height <= scrollView.bounds.height{
            UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
    
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func check(){
        
        let ref = Database.database().reference().child("Users").child(uid!).child("Credentials").child("Notification ID")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if !snapshot.exists(){
                return
            }
            else{
                if snapshot.value as? String != KeychainWrapper.standard.string(forKey: "NOTIF"){
                    self.loggingOut(auto: true)
                }
            }
        })
        checkExists()
        //UserDefaults.standard.set(true, forKey: "New_Post")
        
        /*
         refresh {
         print(self.loadedPosts.count)
         
         DispatchQueue.main.async {
         self.saveAllObjects(allObjects: self.loadedPosts)
         UserDefaults.standard.set(false, forKey: "New_Post")
         }
         }
         
         */
        
    }
    
    
    public func setupUserView(){
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isTranslucent = true
        let attributes = [NSAttributedString.Key.font : UIFont(name: "Futura", size: 18)!, NSAttributedString.Key.foregroundColor : UIColor.darkGray]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        self.username.text = "@" + (KeychainWrapper.standard.string(forKey: "USERNAME") ?? "null")
        self.fullName.text = KeychainWrapper.standard.string(forKey: "FULL_NAME") ?? ""
        self.bioField.text = KeychainWrapper.standard.string(forKey: "USER_BIO")
        self.adjustHeight()
        editBtn.setRadiusWithShadow()
        
        
        if let badges = UserDefaults.standard.array(forKey: "badges") as? [String]{
            self.loadedBadges = badges
            self.collectionView.reloadData()
        }
        
        self.profilePic.layer.cornerRadius = self.profilePic.frame.height / 2
        self.profilePic.clipsToBounds = true
        
        if UserInfo.dp != nil{
            
            self.profilePic.image = UserInfo.dp!
            for (index, _) in self.loadedPosts.enumerated() {
                //print("value \(index) is: \(element)")
                self.tableView.performBatchUpdates({
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }, completion: nil)
            }
        }
    }
    
    @IBOutlet weak var bioField: UITextView!
    
    @IBAction func unwindToTheViewController(segue:  UIStoryboardSegue) {
        
        
    }
    
    func animateCell(cell: UICollectionViewCell){
        
        cell.alpha = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            cell.alpha = 1.0
        })
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView{
            return loadedPosts.count
        }
        else{
    
            if search.text != ""{
                if loadedUsers.isEmpty{
                    return 1 //No results
                }
                else{
                    return loadedUsers.count //searching
                }
            }
            else{
                return loadedUsers.count //followers
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if tableView == self.tableView{
            
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
                cell?.fullName.backgroundColor = UIColor(named: "mainWhiteColor")
                cell?.username.backgroundColor = UIColor(named: "mainWhiteColor")
                
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
                cell?.fullName.backgroundColor = UIColor(named: "mainWhiteColor")
                cell?.username.backgroundColor = UIColor(named: "mainWhiteColor")
                
                return cell!
            }
        }
        else{
            
            if self.loadedUsers.isEmpty{
                let cell = tableView.dequeueReusableCell(withIdentifier: "emptySearch", for: indexPath) as? EmptySearchTableViewCell
                
                cell?.label.text = "No results found"
                
                return cell!
            }
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUsersTableViewCell
                
                
                let user = self.loadedUsers[indexPath.row]
                cell?.userImgView.image = user.image
                cell?.fullnameLbl.text = user.fullName
                cell?.usernameLbl.text = "@" + (user.username ?? "null")
                
                return cell!
            }
        }
    }
   
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView != searchTable{
            return 0
        }
        else{
            if !(search.text == ""){
                return 0
            }
            else{
                return 40
            }
        }
    }
  
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == searchTable{
            if search.text == ""{
                
                let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 40))
            
                
                let label = UILabel.init(frame: CGRect(x: 15, y: 5, width: self.view.frame.width, height: 30))
                label.textColor = UIColor.lightText
                label.font = UIFont(name: "Arial Rounded MT Bold", size: 20)
                label.text = "Following"
                
                view.addSubview(label)
                return view
            }
            return nil
        }
        return nil
    }
    
    //
    /*
     
     
     FIX CHANGING DATE WHEN GOING BACK FROM FULLPOST, DATE STILL REMAINS THE SAME WHEN SAVED, AND UPON LOAD FROM PHONE STORAGE.
     
     - MAIN CODE IN VIEWDIDAPPEAR
     - TRIED SETTING DELEGATE IN CELLFORROWAT BUT DID NOT WORK
     ***IMPORTANT!!***
     
     
     */
    @objc func refresh(_ sender: UIRefreshControl?){
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.getPosts(refresh: sender!, fromInterval: "") {
                
                if sender?.isRefreshing ?? false{
                    sender?.endRefreshing()
                }
                self.isLoading = false
            }
        }
        
        Firestore.firestore().collection("Users").document(uid!).getDocument(completion: { (document, err) in
            
            if err != nil{
                print(err?.localizedDescription ?? "")
            }
            else if document?.exists ?? false{
                
                if let badges = document?["Badges"] as? [String]{
                    self.loadedBadges = badges
                    UserDefaults.standard.set(badges,forKey: "badges")
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
                if let username = document?["Username"] as? String{
                    self.username.text = "@" + username
                    KeychainWrapper.standard.set(username, forKey: "USERNAME")
                }
                if let fullname = document?["Full Name"] as? String{
                    self.fullName.text = fullname
                    KeychainWrapper.standard.set(fullname, forKey: "FULL_NAME")
                }
                else{
                    if let username = document?["Username"] as? String{
                        self.fullName.text = username
                        KeychainWrapper.standard.set(username, forKey: "FULL_NAME")
                    }
                }
                if let bio = document?["Bio"] as? String{
                    self.bioField.text = bio
                    KeychainWrapper.standard.set(bio, forKey: "USER_BIO")
                    self.adjustHeight()
                }
                if let picUID = document?["ProfilePictureUID"] as? String{
                    
                    let ref = Storage.storage().reference().child(self.uid!).child("profile_pic-" + picUID + ".png")
                    self.downloadUserImg(ref: ref, completionHandler: { image in
                        if image != nil{
                            self.profilePic.image = image
                            let saved = self.saveImage(image ?? UIImage(named: "default_DP.png")!, name: "DP", isDP: true)
                            if saved{
                                UserInfo.dp = image
                            }
                        }
                    })
                }
            }
        })
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
    
    let search = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        searchTable.delegate = self
        searchTable.dataSource = self
        searchTable.register(SearchUsersTableViewCell.self, forCellReuseIdentifier: "search")
        searchTable.register(EmptySearchTableViewCell.self, forCellReuseIdentifier: "emptySearch")
        searchTable.separatorStyle = .none
        self.editBtn.layer.cornerRadius = self.editBtn.frame.height / 4
        self.editBtn.clipsToBounds = true
        self.bioField.layer.cornerRadius = 5
        self.bioField.clipsToBounds = true
        search.delegate = self
        self.navigationItem.titleView = search
        search.autocapitalizationType = .words
        search.prompt = ""
        search.returnKeyType = .go
        search.searchBarStyle = .minimal
        search.keyboardType = .alphabet
        search.tintColor = UIColor.white
        search.setText(color: UIColor.white)
        search.placeholder = "Find Friends"
        searchTable.isHidden = true
        self.navigationController?.delegate = self
        search.keyboardAppearance = .dark
        search.autocapitalizationType = .none
        search.autocorrectionType = .no
        
        if let backgroundView = self.collectionView.superview{
            backgroundView.layer.cornerRadius = 5
            backgroundView.clipsToBounds = true
        }
        
        backView.roundCorners([UIRectCorner.topRight, UIRectCorner.topLeft], radius: self.view.frame.width / 20)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        //refresher.attributedTitle = NSAttributedString(string: "Pull to Refresh 👽")
        
        self.tableView.refreshControl = refresher
        
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self,
                                     action: #selector(refresh(_:)),
                                     for: .primaryActionTriggered)
            self.tableView.refreshControl = refreshControl
        }
        setupUserView()
        check()
        
        if downloader == nil{
            self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
        
        if let saved = self.getAllObjects{
            self.tableView.separatorStyle = .singleLine
          
            DispatchQueue.main.async {
                for post in saved{
                    DispatchQueue.main.async {
                        self.loadedPosts.append(FeedPost(uid: post.uid, isPic: post.isPic, picID: post.picID, postCaption: post.postCaption, uploadDate: post.uploadDate, fullName: post.fullName, username: post.username, imageData: post.imageData, userImage: post.userImage, postID: post.postID, userImageID: post.userImageID, uploadTime: post.uploadTime, timestamp: post.timestamp, active: post.active))
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(row: self.loadedPosts.count - 1, section: 0)], with: .none)
                        }, completion: nil)
                        
                        if post.isPic{
                            self.downloadPostImage(index: self.loadedPosts.count - 1, uid: post.uid, picID: post.picID ?? "null")
                        }
                    }
                }
            }
        }
        else{
            self.getPosts(refresh: refresher, fromInterval: "") {
                self.isLoading = false
            }
        }
    }
    
    
    
    lazy var searchTable: UITableView = {
        
        let load = UITableView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        
        load.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(load)
        
        load.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        load.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        load.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        load.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        load.backgroundColor = UIColor.black.withAlphaComponent(0.80)
        
        //let tapper = UITapGestureRecognizer.init(target: self, action: #selector(resign))
        
        return load
    }()
    
    
    
    var getAllObjects: [FeedPost]? {
        if let objects = self.loadClass(withName: "POSTS") {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [FeedPost] {
                return objectsDecoded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func saveAllObjects(allObjects: [FeedPost]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(allObjects){
            self.saveClass(encoded, name: "POSTS")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let full = segue.destination as? FullPostViewController{
            full.post = fullPost
            full.fromProfile = true
            full.hidesBottomBarWhenPushed = true
            if let tabView = self.tabBarController as? TabBarVC{
                
                UIView.animate(withDuration: 0.2, animations: {
                    tabView.button.alpha = 0.0
                    
                }, completion: {(finished : Bool) in
                    if(finished)
                    {
                        tabView.button.isHidden = true
                    }
                })
            }
        }
        else if let navVC = segue.destination as? UINavigationController{
            
            if let friend = navVC.viewControllers.first as? FriendProfileViewController{
                friend.userInfo = selectedUser ?? SearchedUser(uid: "null", username: nil, fullName: nil, image: nil, bio: nil, dpLink: nil, badges: nil, notifID: nil)
            }
        }
    }
}

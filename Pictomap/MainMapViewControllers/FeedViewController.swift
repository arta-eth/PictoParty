//
//  FeedViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-12-17.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import SwiftKeychainWrapper
import FirebaseUI


class FeedPost: Codable, Equatable{
    
    static func == (lhs: FeedPost, rhs: FeedPost) -> Bool {
        return true
    }
    
    var uid = String()
    var isPic = Bool()
    var picID: String? = nil
    var postCaption: String? = nil
    var uploadDate = String()
    var uploadTime = String()
    var username: String? = nil
    var fullName: String? = nil
    var imageData: Data? = nil
    var userImage: Data? = nil
    var postID = String()
    var userImageID: String? = nil
    var timestamp: String! = nil
    var active: Bool! = nil
    
    init(uid: String, isPic: Bool, picID: String?, postCaption: String?, uploadDate: String, fullName: String?, username: String?, imageData: Data?, userImage: Data?, postID: String, userImageID: String?, uploadTime: String, timestamp: String!, active: Bool!) {
        
        self.uid = uid
        self.isPic = isPic
        self.picID = picID
        self.postCaption = postCaption
        self.uploadDate = uploadDate
        self.username = username
        self.fullName = fullName
        self.userImage = userImage
        self.postID = postID
        self.userImageID = userImageID
        self.uploadTime = uploadTime
        self.timestamp = timestamp
        self.active = active
    }
    
    convenience init() {
        self.init(uid: "", isPic: false, picID: nil, postCaption: nil, uploadDate: "", fullName: nil, username: "", imageData: UIImage(named: "default_DP.png")!.jpegData(compressionQuality: 0.8)!, userImage: nil, postID: "", userImageID: nil, uploadTime: "", timestamp: nil, active: nil)
    }
    
}

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    var loadedPosts = [FeedPost]()
    var isLoading = Bool()
    let uid = KeychainWrapper.standard.string(forKey: "USER")
    let downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    var tokens: [[String : Any]]! = nil
    
    var postClass: FeedPost! = nil
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return loadedPosts.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.loadedPosts[indexPath.row]
        
        //IF THE POST IS AN IMAGE-STYLE POST
        if user.isPic{
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "PictureFeedPost", for: indexPath) as? FeedPicturePostCell
            cell?.username.text = nil
            cell?.userImage.image = nil
            cell?.fullName.text = nil
            cell?.postPicture.image = nil
            cell?.postCaption.text = nil
            
            
            //IF THE POST'S IMAGE IS CACHED/DOWNLOADED, REUSE/SET THE CACHED IMAGE
            
            /* SET USER IMAGE IF FULL USER DATA IS DOWNLOADED/EXISTS, LIKE:
             * USER IMAGE
             * FULL NAME
             * USERNAME
             */
            
            
            if user.imageData != nil{
                cell?.postPicture.image = UIImage(data: user.imageData!)
            }
            if user.postCaption != nil{
                cell?.postCaption.text = user.postCaption
            }
            
            
            if user.fullName != nil && user.username != nil && user.userImage != nil{
                cell?.fullName.text = user.fullName
                cell?.fullName.backgroundColor = UIColor.white
                cell?.username.text = "@" + (user.username ?? "null")
                cell?.username.backgroundColor = UIColor.white
                cell?.userImage.image = UIImage(data: user.userImage!)
                
            }
                
                
                /*IF NOT ALL OF THE USER DATA IS DOWNLOADED/EXISTS:
                 * CHECK TO SEE IF THIS USER HAS AN ALREADY EXISTING POST IN THE FEED
                 * IF SO, REUSE THEIR INFORMATION FOR THIS CELL
                 */
            else{
                switch self.loadedPosts.contains(where: {$0.uid == user.uid}){
                case true:
                    
                    //REUSE INFORMATION
                    let cachedUserInfo = self.loadedPosts.first(where: {$0.uid == user.uid})
                    if let cachedUserImg = cachedUserInfo?.userImage{
                        user.username = cachedUserInfo?.username
                        user.userImage = cachedUserImg
                        user.fullName = cachedUserInfo?.fullName
                        user.userImageID = cachedUserInfo?.userImageID
                        cell?.userImage.image = UIImage(data: cachedUserImg)
                        cell?.fullName.text = cachedUserInfo?.fullName
                        cell?.username.text = "@" + (cachedUserInfo?.username ?? "null")
                        cell?.fullName.backgroundColor = UIColor.white
                        cell?.username.backgroundColor = UIColor.white
                    }
                    else{
                        fallthrough //IF THE USER IMAGE IS NOT YET DOWNLOADED BUT USERNAME/FULLNAME EXIST
                    }
                case false:
                    
                    /* IF USER DOES NOT YET EXIST IN THE FEED
                     * DOWNLOAD THEIR PROFILE IMAGE
                     * DOWNLOAD THEIR USERNAME
                     * DOWNLOAD THEIR USERNAME
                     */
                    self.downloadUserImg(uid: user.uid, completionHandler: { image, username, fullName, id in
                        
                        if self.loadedPosts.indices.contains(indexPath.row){ //CHECK TO SEE IF ROW'S INDEX EXISTS IN THE  POST LIST
                            user.username = username
                            user.userImage = image
                            user.fullName = fullName
                            user.userImageID = id
                            if image != nil{
                                cell?.userImage.image = UIImage(data: image!)
                            }
                            cell?.fullName.text = fullName
                            cell?.username.text = "@" + username
                            cell?.fullName.backgroundColor = UIColor.white
                            cell?.username.backgroundColor = UIColor.white
                            if image != nil{
                                cell?.userImage.image = UIImage(data: image!) // SET CELL'S USER IMAGE
                            }
                        }
                    })
                }
            }
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
                cell?.postCaption.text = user.postCaption
            }
            
            
            /* SET USER IMAGE IF FULL USER DATA IS DOWNLOADED/EXISTS, LIKE:
             * USER IMAGE
             * FULL NAME
             * USERNAME
             */
            if user.fullName != nil && user.username != nil && user.userImage != nil{
                cell?.fullName.text = user.fullName
                cell?.fullName.backgroundColor = UIColor.white
                cell?.username.text = "@" + (user.username ?? "null")
                cell?.username.backgroundColor = UIColor.white
                cell?.userImage.image = UIImage(data: user.userImage!)
                
            }
                
                /* IF NOT ALL OF THE USER DATA IS DOWNLOADED/EXISTS:
                 * CHECK TO SEE IF THIS USER HAS AN ALREADY EXISTING POST IN THE FEED
                 * IF SO, REUSE THEIR INFORMATION FOR THIS CELL
                 */
            else{
                switch self.loadedPosts.contains(where: {$0.uid == user.uid}){
                    
                case true:
                    let cachedUserInfo = self.loadedPosts.first(where: {$0.uid == user.uid})
                    
                    if let cachedUserImg = cachedUserInfo?.userImage{
                        user.username = cachedUserInfo?.username
                        user.userImage = cachedUserImg
                        user.fullName = cachedUserInfo?.fullName
                        user.userImageID = cachedUserInfo?.userImageID
                        cell?.userImage.image = UIImage(data: cachedUserImg)
                        cell?.fullName.text = cachedUserInfo?.fullName
                        cell?.username.text = "@" + (cachedUserInfo?.username ?? "null")
                        cell?.fullName.backgroundColor = UIColor.white
                        cell?.username.backgroundColor = UIColor.white
                    }
                    else{
                        fallthrough //IF THE USER IMAGE IS NOT YET DOWNLOADED BUT USERNAME/FULLNAME EXIST
                    }
                    
                case false:
                    
                    /* IF USER DOES NOT YET EXIST IN THE FEED
                     * DOWNLOAD THEIR PROFILE IMAGE
                     * DOWNLOAD THEIR USERNAME
                     * DOWNLOAD THEIR USERNAME
                     */
                    
                    self.downloadUserImg(uid: user.uid, completionHandler: { image, username, fullName, id in
                        
                        if self.loadedPosts.indices.contains(indexPath.row){ //CHECK TO SEE IF ROW'S INDEX EXISTS IN THE  POST LIST
                            user.username = username
                            user.userImage = image
                            user.fullName = fullName
                            user.userImageID = id
                            
                            if image != nil{
                                cell?.userImage.image = UIImage(data: image!)
                            }
                            cell?.fullName.text = fullName
                            cell?.username.text = "@" + username
                            cell?.fullName.backgroundColor = UIColor.white
                            cell?.username.backgroundColor = UIColor.white
                            if image != nil{
                                cell?.userImage.image = UIImage(data: image!) // SET CELL'S USER IMAGE
                            }
                        }
                    })
                }
            }
            return cell!
        }
    }
    

    func setNavigationItem(button: UIBarButtonItem.SystemItem) {
        
        
        let button = UIBarButtonItem(barButtonSystemItem: button, target: self, action: #selector(self.newPost(_:)))
        button.tintColor = UIColor.darkGray
        
        self.navigationItem.rightBarButtonItem = button
    }
    
    @objc func newPost(_ sender: UIBarButtonItem){
        
        self.performSegue(withIdentifier: "newPost", sender: nil)
    }
    
    
    @objc func refresh(_ sender: UIRefreshControl){
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.getPosts(refresh: sender, fromInterval: "") {
                if sender.isRefreshing{
                    sender.endRefreshing()
                }
                self.isLoading = false
            }
        }
    }
    
    @IBAction func unwindToFeed(segue:  UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        //refresher.attributedTitle = NSAttributedString(string: "Pull to Refresh 👽")
        
        self.tableView.refreshControl = refresher
        
        
        self.setNavigationItem(button: UIBarButtonItem.SystemItem.add)
        self.refresh(self.tableView.refreshControl ?? refresher)
        
        // Do any additional setup after loading the view.
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
    

    
    func getPosts(refresh: UIRefreshControl?, fromInterval: String, completed: @escaping DownloadComplete){
        
        
        /*
         QUERY COMMENTS:
         - ORDERING THE "Timestamp" VALUE BY THE EARLIEST TIME
         - STARTING FROM THE LOCAL \(fromInterval) VAR
         - RETRIEVING DOCUMENT SNAPSHOTS IN THE \(snapDocuments) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         - A COMMENT WILL EITHER BE A PICTURE OR TEXT, NOT BOTH
         */
        
        
        let searchDate = currentDate()
        let myFollowing = UserFollowing.userFollowing
        
        if !self.isLoading{
            self.isLoading = true
            
            var query: Query! = nil
            if refresh != nil{
                if refresh?.isRefreshing ?? true{
                    self.downloader.cancelAllDownloads()
                }
                self.loadedPosts.removeAll()
                self.cellHeights.removeAll()
                self.tableView.separatorStyle = .none
                self.tableView.reloadData()
            }
            
            
            completed()
            for followingUID in myFollowing{
                print(followingUID)
                
                if refresh != nil{
                    query = Firestore.firestore().collection("Users").document(followingUID).collection("Posts").whereField("Timestamp", isGreaterThanOrEqualTo: searchDate).limit(to: 5).order(by: "Timestamp", descending: true)

                }
                else{
                    query = Firestore.firestore().collection("Users").document(followingUID).collection("Posts").whereField("Timestamp", isLessThan: fromInterval).limit(to: 5).order(by: "Timestamp", descending: true)
                }
                
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
                        
                        let snaps: [QueryDocumentSnapshot]? = snapDocuments?.documents
                        
                        for snap in snaps ?? []{ // LOADED DOCUMENTS FROM \(snapDocuments)
                            
                            if !self.loadedPosts.contains(where: {$0.postID == snap.documentID}){
                                let date = snap["Timestamp"] as? String // COMMENT TIMESTAMP
                                
                                let timestamp = snap["Timestamp"] as? String
                                if let caption = snap["Caption"] as? String{
                                    
                                    if let picID = snap["Picture"] as? String{
                                        self.loadedPosts.append(FeedPost(uid: followingUID, isPic: true, picID: picID, postCaption: caption, uploadDate: date!, fullName: nil, username: nil, imageData: nil, userImage: nil, postID: snap.documentID, userImageID: nil, uploadTime: "", timestamp: timestamp, active: false))
                                        self.downloadPostImage(index: self.loadedPosts.count - 1, followingUID: followingUID, picID: picID)
                                        
                                    }
                                    else{
                                        self.loadedPosts.append(FeedPost(uid: followingUID, isPic: false, picID: nil, postCaption: caption, uploadDate: date!, fullName: nil, username: nil, imageData: nil, userImage: nil, postID: snap.documentID, userImageID: nil, uploadTime: "", timestamp: timestamp, active: false))
                                    }
                                }
                                else{
                                    if let picID = snap["Picture"] as? String{
                                        self.loadedPosts.append(FeedPost(uid: followingUID, isPic: true, picID: picID, postCaption: nil, uploadDate: date!, fullName: nil, username: nil, imageData: nil, userImage: nil, postID: snap.documentID, userImageID: nil,  uploadTime: "", timestamp: timestamp, active: false))
                                        self.downloadPostImage(index: self.loadedPosts.count - 1, followingUID: followingUID, picID: picID)
                                        
                                    }
                                }
                                self.tableView.performBatchUpdates({
                                    
                                    self.tableView.insertRows(at: [IndexPath(row: self.loadedPosts.count - 1, section: 0)], with: .fade)
                                    
                                }, completion: nil)
                            }
                        }
                    }
                })
            }
        }
        else{
            if refresh?.isRefreshing ?? false{
                refresh?.endRefreshing()
            }
        }
    }
    
    func downloadPostImage(index: Int, followingUID: String, picID: String){
        
        if self.tokens == nil{
            self.tokens = [[String : Any]]()
        }
        let ref = Storage.storage().reference()
        ref.child(followingUID + "/" + "Party-" + picID + ".jpg").downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                if let picturePost = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedPicturePostCell{
                    picturePost.circularProgress.isHidden = false
                    let cp = picturePost.circularProgress
                    let token = self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
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
                                    self.loadedPosts[index].imageData = image!.jpegData(compressionQuality: 1.0)
                                }
                            }
                        }
                    })
                    self.tokens.append(
                        ["Image ID" : picID,
                         "Token" : token!]
                    )
                }
                else{
                    self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: nil,  completed: { (image, data, error, finished) in
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
                }
            }
        })
    }
    
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    ///* Dynamic Cell Sizing *///
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ///For every cell, retrieve the height value and store it in the dictionary
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 70.0
    }
    
    //LOAD COMMENTER'S PROFILE PICTURE INTO THE COMMENT CELL
    func downloadUserImg(uid: String, completionHandler: @escaping (Data?, String, String, String?) -> ()){
        
        /*
         LOAD USER DOCUMENT OF COMMENTER:
         - RETRIEVING THE DOCUMENT SNAPSHOT IN THE \(documents) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         */
        
        let ref = Firestore.firestore().collection("Users").document(uid)
        
        ref.getDocument(){ (document, err) in
            
            if err != nil{
                print("Error getting documents: \(err?.localizedDescription ?? "")") // LOCALIZED DESCRIPTION OF ERROR
                
                //if self.activity.isAnimating{
                //    self.activity.stopAnimating()
                //}
                
                self.isLoading = false
                
                return
            }
            else{
                
                let dpUID = document!["ProfilePictureUID"] as? String //UID OF COMMENT IMAGE
                let ref = Storage.storage().reference().child(uid).child("profile_pic-" + dpUID! + ".png") //STORAGE REFERENCE OF COMMENT IMAGE
                let username = document!["Username"] as? String //COMMENTER'S USERNAME
                let fullName = document!["Full Name"] as? String
                /*
                 DOWNLOAD URL OF USER IMAGE:
                 - RETRIEVING THE URL IN THE \(url) VAR
                 - IF THERE IS AN ERROR, IT WILL BE IN THE \(error) VAR
                 */
                
                ref.downloadURL(completion: { url, error in
                    
                    if error != nil{
                        print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                        
                        //if self.activity.isAnimating{
                        //    self.activity.stopAnimating()
                        //}
                        
                        self.isLoading = false
                        
                        return
                    }
                    else{
                        /*
                         DOWNLOAD USER IMAGE FROM URL:
                         - RETRIEVING THE IMAGE IN THE \(image) VAR
                         - IF THERE IS AN ERROR, IT WILL BE IN THE \(error) VAR
                         - *OPTIONAL* VAR \(data) FOR IMAGE DATA
                         - *OPTIONAL* VAR \(finished) FOR FINISHED FLAG
                         */
                        
                        self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: nil, completed: { (image, data, error, finished) in
                            
                            if error != nil{
                                
                                print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                                
                                //   if self.activity.isAnimating{
                                //       self.activity.stopAnimating()
                                //  }
                                
                                completionHandler(nil, username ?? "(null)", fullName ?? "(null)", dpUID)
                                
                                return
                            }
                            else{
                                completionHandler(image!.jpegData(compressionQuality: 0.8), username ?? "(null)", fullName ?? "(null)", dpUID) //PASS USER IMAGE TO COMPLETION HANDLER
                            }
                        })
                    }
                })
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let fullPost = postClass{
            
            for (index, post) in self.loadedPosts.enumerated() {
                //print("value \(index) is: \(element)")
                if post.uid == fullPost.uid{
                    post.username = fullPost.username
                    post.fullName = fullPost.fullName
                    post.userImage = fullPost.userImage
                    
                    if post.postID == fullPost.postID{
                        post.postCaption = fullPost.postCaption
                    }
                    DispatchQueue.main.async {
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }, completion: { completed in
                            if completed{
                                if index == self.loadedPosts.count - 1{
                                    self.postClass = nil
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let full = segue.destination as? FullPostViewController{
            full.post = postClass
            postClass = nil
            full.fromProfile = false
            full.hidesBottomBarWhenPushed = true
        }
    }
}

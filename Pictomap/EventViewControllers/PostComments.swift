//
//  PostComments.swift
//  Pictomap
//
//  Created by Artak on 2018-10-31.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseUI
import SwiftKeychainWrapper
import FirebaseStorage
import FirebaseFunctions

extension FullPostViewController{
    

    /*
     THE FOLLOWING FUNCTIONS LOAD THE COMMENTS ON THE POST BY PAGINATION, BY INTERVALS OF 8.
     */
    
    
    //LOAD COMMENT INFO FUNCTION
    func getComments(fromInterval: String, completed: @escaping DownloadComplete){
        
        let ref = Firestore.firestore().collection("Users").document(uid!).collection("Posts").document(partyNode).collection("Comments") //REFERENCE TO FIRESTORE DATABASE

        /*
         QUERY COMMENTS:
         - ORDERING THE "Timestamp" VALUE BY THE EARLIEST TIME
         - STARTING FROM THE LOCAL \(fromInterval) VAR
         - RETRIEVING DOCUMENT SNAPSHOTS IN THE \(snapDocuments) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         - A COMMENT WILL EITHER BE A PICTURE OR TEXT, NOT BOTH
         */
        

        let query: Query? = ref.order(by: "Timestamp").whereField("Timestamp", isGreaterThan: fromInterval).limit(to: 8)
        
        query?.getDocuments(completion: { (snapDocuments, err) in

            if err != nil {
                print(err?.localizedDescription ?? "nil")// LOCALIZED DESCRIPTION OF ERROR
                completed() //COMPLETION
            }
            if snapDocuments?.isEmpty ?? true{
                //EMPTY SNAPSHOT
                
                completed() //COMPLETION
            }
                
            else{
                
                var com: [Comments]! = [Comments]()
                var unretrievable = Int()
                
                let snaps: [QueryDocumentSnapshot]? = snapDocuments?.documents
                
                
                for snap in snaps ?? []{ // LOADED DOCUMENTS FROM \(snapDocuments)
                    
                    let date = snap["Timestamp"] as? String // COMMENT TIMESTAMP
                    let uid = snap["UID"] as! String // UID OF COMMENTER
                    
                    if let alreadyCom = com.first(where: {$0.uid == uid}){
                        
                        self.commentSnapInfo(snap: snap, username: alreadyCom.username!, fullName: alreadyCom.fullName!, imageData: alreadyCom.imageData!, date: date!, uid: uid, handler: { (comment) in
                            
                            if comment != nil{
                                com.append(comment!)
                                self.sortAndInsertComments(snapDocuments: snapDocuments!, downloadingCommentList: com, unretrievableCommmentsCount: unretrievable){
                                    com = nil
                                    completed()
                                }
                            }
                            else{
                                unretrievable +=  1
                                self.deleteFaultyCommentFromPost(commentID: snap.documentID)
                            }
                        })
                    }
                    else if let alreadyComments = self.comments.first(where: {$0.uid == uid}){
                        
                        self.commentSnapInfo(snap: snap, username: alreadyComments.username!, fullName: alreadyComments.fullName!, imageData: alreadyComments.imageData!, date: date!, uid: uid, handler: { (comment) in
                            
                            if comment != nil{
                                com.append(comment!)
                                    self.sortAndInsertComments(snapDocuments: snapDocuments!, downloadingCommentList: com, unretrievableCommmentsCount: unretrievable){
                                        com = nil
                                        completed()
                                    }
                                
                            }
                            else{
                                unretrievable += 1
                                self.deleteFaultyCommentFromPost(commentID: snap.documentID)
                            }
                        })
                    }
                    else{
                        self.loadUserImg(id: snap.documentID, uid: uid, completionHandler: { value, username, fullName in
                            
                            self.commentSnapInfo(snap: snap, username: username, fullName: fullName, imageData: value.jpegData(compressionQuality: 1.0)!, date: date!, uid: uid, handler: { (comment) in
                                
                                if comment != nil{
                                    com.append(comment!)
                                        self.sortAndInsertComments(snapDocuments: snapDocuments!, downloadingCommentList: com, unretrievableCommmentsCount: unretrievable){
                                            com = nil
                                            completed()
                                        }
                                    
                                }
                                else{
                                    
                                    unretrievable +=  1
                                    self.deleteFaultyCommentFromPost(commentID: snap.documentID)
                                }
                            })
                        })
                    }
                }
            }
        })
    }
    
    
    func deleteFaultyCommentFromPost(commentID: String){
        
        let faultyCommentData = [
            "postOwnerUID" : uid,
            "commentID" : commentID,
            "postID" : partyNode
            ]
        
        functions.httpsCallable("deleteFaultyCommentFromPost").call(faultyCommentData) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    print(FunctionsErrorCode(rawValue: error.code) ?? "None")
                    print(error.localizedDescription)
                    print(error.userInfo[FunctionsErrorDetailsKey] ?? "None")
                }
            }
            else{
                print("Deleted Faulty Comment")
            }
        }
    }
    
    

    func commentSnapInfo(snap: DocumentSnapshot, username: String, fullName: String, imageData: Data, date: String, uid: String, handler: @escaping (Comments?) -> Void){
        
        if let commentText = snap["Text"] as? String { // IF COMMENT IS A TEXT COMMENT
            let textComment = Comments(uploadDate: date, comment: commentText, isPic: false, uid: uid, id: snap.documentID, imageData: imageData, username: username, commentImageData: Data(capacity: 0), fullName: fullName) // ADD COMMENT TO \(comments)
            handler(textComment)
        }
        else if let commentPic = snap["PhotoUID"] as? String{ // IF COMMENT IS PICTURE COMMENT
            
            let commentImage = Comments(uploadDate: date, comment: commentPic, isPic: true, uid: uid, id: snap.documentID, imageData: imageData, username: username, commentImageData: nil, fullName: fullName) // ADD COMMENT TO \(comments)
            handler(commentImage)
            
            loadCommentImage(storageUID: commentPic, completionHandler: { (image) in
                
                if let im = image{
                    commentImage.commentImageData = im.jpegData(compressionQuality: 1.0)!
                }
                else{
                    handler(nil)
                }
            })
        }
    }
    

    func sortAndInsertComments(snapDocuments: QuerySnapshot, downloadingCommentList: [Comments], unretrievableCommmentsCount: Int, completed: @escaping DownloadComplete){
        
        
        if downloadingCommentList.count == snapDocuments.documents.count - unretrievableCommmentsCount{
            print("Unretrievable: \(unretrievableCommmentsCount)")
            
            var count: Int! = 0

            UIView.setAnimationsEnabled(false)
            let sorted = (downloadingCommentList.sorted(by: { $0.uploadDate < $1.uploadDate }).filterDuplicate({$0.id}))
            for sortedComment in sorted{
                self.comments.append(sortedComment)
                self.tableView.performBatchUpdates({self.tableView.insertRows(at: [IndexPath(row: self.comments.count, section: 0)], with: UITableView.RowAnimation.none)}, completion: { (complete) in
                    // INSERT 1 ROW PER COMMENT
                    if complete{
                        
                        
                        count += 1
                        if count == sorted.count{
                            for c in self.comments{
                                print(c.uid!)
                            }
                            print((snapDocuments.documents.count))
                            UIView.setAnimationsEnabled(true)
                            print(self.comments.count)
                            count = nil
                            completed()
                        }
                    }
                })
            }
        }
    }
    
    
    //LOAD COMMENTER'S PROFILE PICTURE INTO THE COMMENT CELL
    func loadUserImg(id: String, uid: String, completionHandler: @escaping (UIImage, String, String) -> ()){
        
        /*
         LOAD USER DOCUMENT OF COMMENTER:
         - RETRIEVING THE DOCUMENT SNAPSHOT IN THE \(documents) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         */

        let ref = Firestore.firestore().collection("Users").document(uid)
        
        ref.getDocument( completion: { (document, err) in
            
            if err != nil{
                print("Error getting documents: \(err?.localizedDescription ?? "")") // LOCALIZED DESCRIPTION OF ERROR
                
    
                if (self.tableView.refreshControl?.isRefreshing) ?? false{
                    self.tableView.refreshControl?.endRefreshing()
                }
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
                        
   
                        if (self.tableView.refreshControl?.isRefreshing) ?? false{
                            self.tableView.refreshControl?.endRefreshing()
                        }
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
                                if (self.tableView.refreshControl?.isRefreshing) ?? false{
                                    self.tableView.refreshControl?.endRefreshing()
                                }
                                self.isLoading = false
                             
                                return
                            }
                            else{
                                completionHandler(image!, username ?? "null", fullName ?? "null") //PASS USER IMAGE TO COMPLETION HANDLER
                            }
                        })
                    }
                })
            }
        })
    }
    
    // LOAD IMAGE OF PICTURE STYLE COMMENT INTO THE COMMENT CELL
    func loadCommentImage(storageUID: String, completionHandler: @escaping (UIImage?) -> ()){
        
        let ref = Storage.storage().reference().child(uid!).child("Comment-" + storageUID + ".png") //REFERENCE TO FIRESTORE STORAGE
        
        /*
         DOWNLOAD URL OF COMMENT IMAGE:
         - RETRIEVING THE URL IN THE \(url) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(error) VAR
         */
        
        ref.downloadURL(completion: { url, error in
            
            if error != nil{
                
                print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR

                if (self.tableView.refreshControl?.isRefreshing) ?? false{
                    self.tableView.refreshControl?.endRefreshing()
                }
                completionHandler(nil)
            }
                
            else{
                
                /*
                 DOWNLOAD COMMENT IMAGE FROM URL:
                 - RETRIEVING THE IMAGE IN THE \(image) VAR
                 - IF THERE IS AN ERROR, IT WILL BE IN THE \(error) VAR
                 - *OPTIONAL* VAR \(data) FOR IMAGE DATA
                 - *OPTIONAL* VAR \(finished) FOR FINISHED FLAG
                 */
                
                self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: nil, completed: { (image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                        
                        if (self.tableView.refreshControl?.isRefreshing) ?? false{
                            self.tableView.refreshControl?.endRefreshing()
                        }
                    }
                    else{
                        completionHandler(image!) //PASS COMMENT IMAGE TO COMPLETION HANDLER
                    }
                })
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let comment = comments[indexPath.row]
        switch comment.isPic{
        case true:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! CommentPictureCell
            
            if post.active{
                cell.usernameLbl.textColor = activeUsernameColor
                cell.fullName.textColor = activeFullNameColor
                cell.commentImg.layer.borderColor = UIColor.white.cgColor
                cell.commentActivityView.color = UIColor.white
                
            }
            else{
                cell.usernameLbl.textColor = usernameColor
                cell.fullName.textColor = fullNameColor
                cell.commentImg.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                cell.commentActivityView.color = usernameColor

            }
            
            cell.usernameLbl.text = nil
            cell.profileImg.image = nil
            cell.fullName.text = nil
            cell.commentImg.image = UIImage(named: "blank.png")

            if comment.uid == KeychainWrapper.standard.string(forKey: "USER"){
                cell.profileImg.image = UserInfo.dp
                cell.usernameLbl.text = "@" + (KeychainWrapper.standard.string(forKey: "USERNAME") ?? "null")
                cell.fullName.text = KeychainWrapper.standard.string(forKey: "FULL_NAME")
            }
            else if comment.uid == self.post.uid{
                if post.userImage != nil{
                    cell.profileImg.image = UIImage(data: post.userImage!)
                    cell.usernameLbl.text = "@" + (self.post.username ??  "null")
                    cell.fullName.text = self.post.fullName ?? "null"
                }
            }
            else{
                
                if let data = self.comments[indexPath.row].imageData{
                    
                    cell.profileImg.image = UIImage(data: data)
                    cell.usernameLbl.text = "@" + self.comments[indexPath.row].username!
                    cell.fullName.text = self.comments[indexPath.row].fullName
                    cell.layoutIfNeeded()
                    
                }
                else{
                    
                    switch self.comments.contains(where: {$0.uid == comment.uid}){
                        
                    case true:
                        let cachedUserInfo = self.comments.first(where: {$0.uid == comment.uid})
                        
                        if let cachedUserImg = cachedUserInfo?.imageData{
                            comment.username = cachedUserInfo?.username
                            comment.imageData = cachedUserInfo?.imageData
                            comment.fullName = cachedUserInfo?.fullName
                            cell.profileImg.image = UIImage(data: cachedUserImg)
                            cell.fullName.text = cachedUserInfo?.fullName
                            cell.usernameLbl.text = "@" + (cachedUserInfo?.username ?? "null")
                        }
                        else{
                            fallthrough //IF THE USER IMAGE IS NOT YET DOWNLOADED BUT USERNAME/FULLNAME EXIST
                        }
                        
                    case false:
                        
                        
                        self.downloadUserImg(uid: comment.uid ?? "null", completionHandler: { image, username, fullName, id  in
                            
                            if self.comments.indices.contains(indexPath.row){ //CHECK TO SEE IF ROW'S INDEX EXISTS IN THE  POST LIST
                                comment.username = username
                                comment.imageData = image
                                comment.fullName = fullName
                                
                                if image != nil{
                                    cell.profileImg.image = UIImage(data: image!) // SET CELL'S USER IMAGE
                                }
                                
                                cell.fullName.text = fullName // SET CELL'S FULL NAME LABEL
                                cell.usernameLbl.text = "@" + username // SET CELL'S USERNAME LABEL
                            }
                        })
                    }
                }
            }
            
            if let commentData = comment.commentImageData{
                cell.commentImg.image = UIImage(data: commentData)
            }

            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! CommentTextCell
            cell.usernameLbl.text = nil
            cell.profileImg.image = nil
            cell.fullName.text = nil
            cell.commentTextView.text = nil
            
            
            if post.active{
                cell.usernameLbl.textColor = activeUsernameColor
                cell.fullName.textColor = activeFullNameColor
                cell.commentTextView.textColor = UIColor.white
                cell.commentBackgroundView.layer.borderColor = UIColor.white.cgColor
                cell.commentBackgroundView.backgroundColor = activeCommentColor
                cell.commentActivityView.color = UIColor.white

            }
            else{
                cell.usernameLbl.textColor = usernameColor
                cell.fullName.textColor = fullNameColor
                cell.commentTextView.textColor = infoTextColor
                cell.commentBackgroundView.layer.borderColor = infoTextColor?.withAlphaComponent(0.5).cgColor
                cell.commentBackgroundView.backgroundColor = commentColor
                cell.commentActivityView.color = usernameColor

            }
            
            if comment.uid == KeychainWrapper.standard.string(forKey: "USER"){
                cell.profileImg.image = UserInfo.dp
                cell.usernameLbl.text = "@" + (KeychainWrapper.standard.string(forKey: "USERNAME") ?? "null")
                cell.fullName.text = KeychainWrapper.standard.string(forKey: "FULL_NAME")
            }
            else if comment.uid == self.post.uid{
                
                if post.userImage != nil{
                    cell.profileImg.image = UIImage(data: post.userImage!)
                    cell.usernameLbl.text = "@" + (self.post.username ??  "null")
                    cell.fullName.text = self.post.fullName ?? "null"
                }
            }
                
            else{
                if let data = self.comments[indexPath.row].imageData{
                    cell.profileImg.image = UIImage(data: data)
                    cell.usernameLbl.text = "@" + self.comments[indexPath.row].username!
                    cell.fullName.text = self.comments[indexPath.row].fullName
                }
                else{
                    switch self.comments.contains(where: {$0.uid == comment.uid}){
                        
                    case true:
                        let cachedUserInfo = self.comments.first(where: {$0.uid == comment.uid})
                        
                        if let cachedUserImg = cachedUserInfo?.imageData{
                            comment.username = cachedUserInfo?.username
                            comment.imageData = cachedUserInfo?.imageData
                            comment.fullName = cachedUserInfo?.fullName
                            cell.profileImg.image = UIImage(data: cachedUserImg)
                            cell.fullName.text = cachedUserInfo?.fullName
                            cell.usernameLbl.text = "@" + (cachedUserInfo?.username ?? "null")
                        }
                        else{
                            fallthrough //IF THE USER IMAGE IS NOT YET DOWNLOADED BUT USERNAME/FULLNAME EXIST
                        }
                        
                    case false:
                        self.downloadUserImg(uid: comment.uid ?? "null", completionHandler: { image, username, fullName, id  in
                            
                            if self.comments.indices.contains(indexPath.row){ //CHECK TO SEE IF ROW'S INDEX EXISTS IN THE  POST LIST
                                comment.username = username
                                comment.imageData = image
                                comment.fullName = fullName
                                
                                if image != nil{
                                    cell.profileImg.image = UIImage(data: image!) // SET CELL'S USER IMAGE
                                }
                                
                                cell.fullName.text = fullName // SET CELL'S FULL NAME LABEL
                                cell.usernameLbl.text = "@" + username // SET CELL'S USERNAME LABEL
                            }
                        })
                    }
                }
            }
            
            if let caption = comment.comment{
                cell.commentTextView.text = caption
            }

            return cell
        }
    }
    
    
    
    
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
                                guard let im = image else{return}
                                completionHandler(im.jpegData(compressionQuality: 0.8), username ?? "(null)", fullName ?? "(null)", dpUID) //PASS USER IMAGE TO COMPLETION HANDLER
                            }
                        })
                    }
                })
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     
        cellHeights[indexPath] = cell.frame.size.height
        cell.backgroundColor = UIColor.clear

        /*
        if indexPath.row == self.comments.count - 1{
            print("fromTable")
            loadMoreComments(){
            }
        }
 */
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        /*
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            loadMoreComments(){
            }
        }
 */
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        return cellHeights[indexPath] ?? 250.0
    }
}



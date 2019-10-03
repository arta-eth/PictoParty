//
//  FullPostViewController.swift
//  Party Time
//
//  Created by Artak on 2018-08-06.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftKeychainWrapper
import FirebaseUI
import FirebaseFirestore
import Photos
import AudioToolbox
import FirebaseFunctions

enum DatabaseConnectionError: Error {
    case invalidLink
    case insufficientFunds(coinsNeeded: Int)
    case outOfStock
}

class Comments{
    
    var uploadDate = String()
    var comment: String?
    var isPic: Bool?
    var uid: String?
    var id: String = String()
    var imageData: Data?
    var username: String?
    var fullName: String?
    var commentImageData: Data?
    
    
    required init(uploadDate: String, comment: String, isPic: Bool, uid: String, id: String, imageData: Data?, username: String?, commentImageData: Data?, fullName: String?){
        
        self.uploadDate = uploadDate
        self.comment = comment
        self.id = id
        self.isPic = isPic
        self.uid = uid
        self.imageData = imageData
        self.username = username
        self.commentImageData = commentImageData
        self.fullName = fullName
    }
    
}

class FullPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, ListenerRegistration, UINavigationControllerDelegate{
    
    func remove() {
    }
    
    lazy var functions = Functions.functions()
    @IBOutlet weak var partyImage: UIImageView!
    @IBOutlet weak var info: UITextView!
    
    
    
    
    @IBOutlet weak var fullNameField: UILabel!
    @IBOutlet weak var usernameField: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentInputView: UITextView!
    @IBOutlet weak var barBackgroundView: UIView!
    @IBOutlet weak var postCommentBtn: UIButton!
    @IBOutlet weak var showPicsBtn: UIButton!
    @IBOutlet weak var cameraRollView: UIView!
    @IBOutlet weak var seperatorLine: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var picInfo: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var textBackgroundView: UIView!
    @IBOutlet weak var photosBtnView: UIView!
    @IBOutlet weak var cameraBtnView: UIView!
    @IBOutlet weak var toolBar: UIView!
    @IBOutlet weak var userImg: UIImageView!
    
    
    @IBOutlet weak var backView: UIView!
    
    
    
    
    var listener: ListenerRegistration! = nil
    var downloader: SDWebImageDownloader! = nil
    
    var images = [PHAsset]()
    var imageRef = String()
    var partyNode = String()
    var uid: String?
    var fromMap = Bool()
    var fromAreas = Bool()
    var fromProfile = Bool()
    let label = UILabel()
    var likes = Int()
    var displayName = String()
    var image: UIImage = UIImage(named: "default_DP.png")!
    var comments = [Comments]()
    var cellHeights: [IndexPath : CGFloat] = [:]
    var isLoading = false
    let window = UIApplication.shared.keyWindow!
    var placeholderLabel = UILabel()
    var initialBarViewHeight = CGFloat()
    var commentImage: UIImage? = nil
    var post = FeedPost()
    
    
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        if !self.cameraRollView.isHidden{
            self.postCommentBtn.isEnabled = false
            self.cameraRollHide(sender: self.showPicsBtn)
        }
        
        if !self.toolBar.isHidden{
            self.bringUpMenu(nil)
        }
        
        if self.commentImage != nil{
            self.commentImage = nil
        }
        self.bringDownCommentMenu(nil)
        
        let bottomPadding = self.view.safeAreaInsets.bottom
        print(bottomPadding)
        
        if commentInputView.isFirstResponder{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                UIView.animate(withDuration: 0.2, animations: {
                    self.postCommentBtn.alpha = 1.0
                    self.postCommentBtn.isHidden = false
                    
                    self.barBackgroundView.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                    //self.keyBoardTopView.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                    
                    print(self.tableView.contentOffset.y)
                    self.tableView.contentOffset.y += keyboardHeight - bottomPadding
                    self.tableView.contentInset.bottom = keyboardHeight - bottomPadding
                    self.tableView.scrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                })
            }
        }
    }
    
    
    @objc func appAppeared(_ notification: Notification){
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        DispatchQueue.main.async {
            self.tableView.contentInset.bottom = 0
            self.tableView.scrollIndicatorInsets.bottom = 0
            self.commentInputView.isUserInteractionEnabled = true
        }
        if post.active{
            self.animateActive(remove: false)
        }
    }
    
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if commentInputView.isFirstResponder{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                let bottomPadding = window.safeAreaInsets.bottom
                
                commentInputView.scrollRangeToVisible(NSRange(location: 0, length: 0))
                UIView.animate(withDuration: 0.2, animations: {
                    
                    if self.commentInputView.text.isEmpty{
                        
                        self.postCommentBtn.alpha = 0.0
                        self.postCommentBtn.isHidden = true
                    }
                    self.barBackgroundView.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.tableView.contentInset.bottom -= keyboardHeight - bottomPadding
                    self.tableView.scrollIndicatorInsets.bottom -= keyboardHeight - bottomPadding
                    //self.keyBoardTopView.transform = CGAffineTransform(translationX: 0, y: 0)
                    
                })
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView is UITableView{
            
            if(scrollView.contentSize.height > scrollView.bounds.height){
                if(velocity.y > 0) {
                    //self.navigationController?.setNavigationBarHidden(true, animated: true)
                    print("Hide")
                    if self.commentInputView.isFirstResponder{
                        self.commentInputView.resignFirstResponder()
                    }
                    
                } else {
                    
                    //self.navigationController?.setNavigationBarHidden(false, animated: true)
                    print("Unhide")
                }
            }
        }
    }
    
    
    @IBAction func postComment(_ sender: UIButton){
        
        sender.isEnabled = false
        if !self.commentInputView.isFirstResponder{
            sender.isHidden = true
        }
        
        var isPic = Bool()
        guard let myUID = KeychainWrapper.standard.string(forKey: "USER") else{return}
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "YYYY-MM-dd, a hh:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let uploadDate = formatter.string(from: today)
        let newDate = uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
        
        var commentData: [String:Any]? = nil
        var postingCell = UITableViewCell()
        var data = Data()
        
        
        guard let username = KeychainWrapper.standard.string(forKey: "USERNAME") else{return}
        let fullname = KeychainWrapper.standard.string(forKey: "FULL_NAME")
        
        guard let image = UserInfo.dp else{return}
        let imgData = image.jpegData(compressionQuality: 1.0)
        let ref: DocumentReference? = Firestore.firestore().collection("Users").document(uid ?? "").collection("Posts").document(partyNode).collection("Comments").document()
        
        let docID = ref?.documentID ?? ""
        
        let db = Firestore.firestore().collection("Users").document(uid ?? "").collection("Posts").document(partyNode).collection("Comments").document(ref?.documentID ?? "")
        
        if Reachability.isConnectedToNetwork(){
            switch commentImage{
                
            case nil:
                
                let text = commentInputView.text!
                isPic = false
                if !commentInputView.text.isEmpty{
                    commentData = [
                        "Text" : text,
                        "UID" : myUID,
                        "Timestamp" : newDate,
                        "isPic" : false
                    ]
                    
                    commentInputView.text.removeAll()
                    //
                    self.textViewDidChange(commentInputView)
                    
                    self.comments.append(Comments(uploadDate: newDate, comment: text, isPic: false, uid: myUID, id: docID, imageData: imgData, username: username, commentImageData: nil, fullName: fullname ?? username))
                }
                
                
            default:
                
                let imgUID = NSUUID().uuidString
                isPic = true
                commentData = [
                    "PhotoUID" : imgUID,
                    "UID" : myUID,
                    "Timestamp" : newDate,
                    "isPic" : true
                ]
                
                if let uploadData = commentImage!.jpegData(compressionQuality: 0.8){
                    self.commentImage = nil
                    data = uploadData
                    self.comments.append(Comments(uploadDate: newDate, comment: imgUID, isPic: true, uid: myUID, id: docID, imageData: imgData, username: username, commentImageData: uploadData, fullName: fullname ?? username))
                }
            }
            DispatchQueue.main.async {
                let index = IndexPath(row: self.comments.count - 1, section: 0)
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [index], with: .left)
                }, completion: { (complete) in
                    // INSERT 1 ROW PER COMMENT
                    if complete{
                        if let cell = self.tableView.cellForRow(at: index) as? CommentPictureCell{
                            postingCell = cell
                            cell.commentActivityView.startAnimating()
                        }
                        else if let cell = self.tableView.cellForRow(at: index) as? CommentTextCell{
                            postingCell = cell
                            cell.commentActivityView.startAnimating()
                        }
                        if isPic{
                            let imgID = commentData?["PhotoUID"] as! String
                            self.uploadCommentPicToStorage(imgUID: imgID, uploadData: data){
                                self.uploadCommentToPostDatabse(cell: postingCell, commentData: commentData!, db: db)
                            }
                        }
                        else{
                            self.uploadCommentToPostDatabse(cell: postingCell, commentData: commentData!, db: db)
                        }
                    }
                })
                self.tableView.scrollToRow(at: index, at: UITableView.ScrollPosition.none, animated: true)
                if !self.commentInputView.isFirstResponder{
                    if !self.cameraRollView.isHidden{
                        self.cameraRollHide(sender: self.showPicsBtn)
                    }
                    if !self.toolBar.isHidden{
                        self.bringUpMenu(nil)
                    }
                }
            }
        }
        else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                self.view.showNoWifiLabel()
                sender.isEnabled = true
                sender.backgroundColor = UserBackgroundColor().primaryColor
            }
        }
    }
    
    @objc func editCommentView(){
        
        
    }
    
    func uploadCommentPicToStorage(imgUID: String, uploadData: Data, completed: @escaping DownloadComplete){
        
        let storageRef = Storage.storage().reference().child(uid!).child("Comment-" + imgUID + ".png")
        
        storageRef.putData(uploadData, metadata: nil, completion:{ (metaData, error) in
            if error != nil{
                print(error?.localizedDescription ?? "no error")
                return
            }else{
                completed()
            }
        })
    }
    
    func uploadCommentToPostDatabse(cell: UITableViewCell, commentData: [String : Any], db: DocumentReference){
        
        db.setData(commentData, completion: { (err) in
            
            if err != nil{
                print(err?.localizedDescription ?? "")
            }
            else{
                print("here")
                if let cell = cell as? CommentTextCell{
                    
                    cell.commentActivityView.stopAnimating()
                }
                else if let cell = cell as? CommentPictureCell{
                    
                    cell.commentActivityView.stopAnimating()
                }
            }
        })
    }
    
    
    var selectedCell = UITableViewCell()
    
    var commentMenuHeight = NSLayoutConstraint()
    var initialCommentHeight = CGFloat()
    
    @objc func showCommentMenu(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                AudioServicesPlaySystemSound(1520)
                
                if self.commentInputView.isFirstResponder{
                    DispatchQueue.main.async {
                        self.commentInputView.resignFirstResponder()
                    }
                }
                
                self.selectedCell = self.tableView.cellForRow(at: indexPath)!
                self.selectedCell.contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                if let cell = selectedCell as? CommentPictureCell{
                    cell.commentImg.alpha = 0.5
                    cell.profileImg.alpha = 0.5
                }
                else if let cell = selectedCell as? CommentTextCell{
                    cell.profileImg.alpha = 0.5
                }
                self.tableView.isUserInteractionEnabled = false
                
                
                reportBtn.frame = CGRect(x: self.view.center.x - 37.5, y: self.view.frame.height + 10, width: 75, height: 75)
                
                deleteBtn.frame = CGRect(x: (reportBtn.frame.minX / 2) - 37.5, y: self.view.frame.height + 10, width: 75, height: 75)
                
                cancelBtn.frame = CGRect(x: reportBtn.frame.maxX + deleteBtn.frame.minX, y: self.view.frame.height + 10, width: 75, height: 75)
                
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    if self.post.uid == KeychainWrapper.standard.string(forKey: "USER"){
                        if self.comments[indexPath.row].uid == KeychainWrapper.standard.string(forKey: "USER"){
                            self.deleteBtn.transform = CGAffineTransform(translationX: 50, y: -175)
                            self.cancelBtn.transform = CGAffineTransform(translationX: -50, y: -175)
                        }
                        else{
                            self.deleteBtn.transform = CGAffineTransform(translationX: 0, y: -175)
                            self.reportBtn.transform = CGAffineTransform(translationX: 0, y: -180)
                            self.cancelBtn.transform = CGAffineTransform(translationX: 0, y: -175)
                        }
                    }
                    else{
                        if self.comments[indexPath.row].uid == KeychainWrapper.standard.string(forKey: "USER"){
                            self.deleteBtn.transform = CGAffineTransform(translationX: 50, y: -175)
                            self.cancelBtn.transform = CGAffineTransform(translationX: -50, y: -175)
                        }
                        else{
                            self.reportBtn.transform = CGAffineTransform(translationX: -55, y: -175)
                            self.cancelBtn.transform = CGAffineTransform(translationX: -55, y: -175)
                        }
                    }
                })
            }
        }
    }
    
    
    @objc func bringDownCommentMenu(_ sender: UIButton?){
        sender?.isEnabled = false
        self.tableView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.2, animations: {
            
            self.reportBtn.transform = CGAffineTransform(translationX: 0, y: 0)
            self.deleteBtn.transform = CGAffineTransform(translationX: 0, y: 0)
            self.cancelBtn.transform = CGAffineTransform(translationX: 0, y: 0)
            self.selectedCell.contentView.backgroundColor = UIColor.clear
            if let cell = self.selectedCell as? CommentPictureCell{
                cell.commentImg.alpha = 1.0
                cell.profileImg.alpha = 1.0
            }
            else if let cell = self.selectedCell as? CommentTextCell{
                cell.profileImg.alpha = 1.0
            }
        }, completion: {(finished : Bool) in
            if(finished)
            {
                sender?.isEnabled = true
            }
        })
    }
    
    var difference = CGFloat()
    
    @objc func deleteComment(_ sender: UIButton?){
        
        let index = self.tableView.indexPath(for: selectedCell)!
        sender?.isEnabled = false
        sender?.backgroundColor = UIColor.lightText.withAlphaComponent(0.6)
        sender?.setTitleColor(UIColor.red.withAlphaComponent(0.5), for: .normal)
        let id = self.comments[index.row].id
        
        self.comments.remove(at: index.row)
        self.cellHeights.removeValue(forKey: index)
        
        self.cameraRollHide(sender: self.showPicsBtn)
        
        DispatchQueue.main.async{
            self.tableView.performBatchUpdates({self.tableView.deleteRows(at: [index], with: UITableView.RowAnimation.left)}, completion: { (complete) in
                if complete{
                    self.bringDownCommentMenu(nil)
                    
                    if self.comments.count == 0{
                        if self.navigationController?.navigationBar.isHidden ?? true{
                            UIView.animate(withDuration: 2.5, delay: 0, options: UIView.AnimationOptions(), animations: {
                                self.navigationController?.setNavigationBarHidden(false, animated: true)
                                print("Unhide")
                            }, completion: nil)
                        }
                    }
                    
                    sender?.isEnabled = true
                    sender?.setTitleColor(UIColor.red, for: .normal)
                    sender?.backgroundColor = UIColor.lightText.withAlphaComponent(0.8)
                }
            })
        }
        Firestore.firestore().collection("Users").document(self.uid!).collection("Posts").document(self.partyNode).collection("Comments").document(id).delete(completion: { error in
            if error != nil{
                sender?.isEnabled = true
                sender?.backgroundColor = UIColor.lightText.withAlphaComponent(0.8)
                sender?.setTitleColor(UIColor.red, for: .normal)
                print(error?.localizedDescription ?? "")
            }
            else{
                
                
            }
        })
        
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func checkPhotosAccess(completed: @escaping DownloadComplete) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied:
            
            print("Denied, request permission from settings")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
            completed()
        case .restricted:
            print("Restricted, device owner must approve")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
            completed()
            
        case .authorized:
            
            print("Authorized, proceed")
            UserDefaults.standard.set(true, forKey: "AuthPhoto")
            completed()
            
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized  {
                    print("Permission granted, proceed")
                    UserDefaults.standard.set(true, forKey: "AuthPhoto")
                    if UserDefaults.standard.synchronize(){
                        completed()
                    }
                    
                } else {
                    print("Permission denied")
                    UserDefaults.standard.set(false, forKey: "AuthPhoto")
                    completed()
                    
                }
            })
        @unknown default:
            return
        }
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Sorry!",
                                                message: "Photo Library Access must be enabled from settings in order to use this feature",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    // Handle
                })
            }
        })
        self.present(alertController, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    @objc func closeKeyboard(_ sender: Any){
        
        
        if let send = sender as? UISwipeGestureRecognizer{
            if send.state == .ended{
                if self.commentInputView.isFirstResponder{
                    self.commentInputView.resignFirstResponder()
                }
            }
        }
        else if sender is UITapGestureRecognizer{
            
            if self.commentInputView.isFirstResponder{
                self.commentInputView.resignFirstResponder()
            }
        }
    }
    @IBOutlet weak var cameraRollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toolbarHeight: NSLayoutConstraint!
    
    func cameraRollPopUp(sender: UIButton?){
        
        sender?.setImage(UIImage(named: "Cancel")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
        sender?.layer.borderWidth = 0
        sender?.backgroundColor = UIColor.clear
        
        
        sender?.tintColor = commentColor
        if post.active{
            sender?.layer.borderColor = UIColor.white.cgColor
            sender?.tintColor = UIColor.white
        }
        else{
            sender?.backgroundColor = commentColor
            sender?.tintColor = UIColor.darkGray
            sender?.layer.borderColor = UIColor.darkGray.cgColor
        }
        
        
        UIView.animate(withDuration: 0.2, animations: {
            
            if self.postCommentBtn.isHidden{
                self.postCommentBtn.isHidden = false
            }
            self.cameraRollViewHeight.constant = 75
            self.cameraRollView.isHidden = false
            self.tableView.contentOffset.y += self.cameraRollViewHeight.constant
            self.postCommentBtn.isHidden = false
            self.postCommentBtn.alpha = 1.0
            
            
        }, completion: { (finished: Bool) in
            sender?.isEnabled = true
        })
    }
    
    func cameraRollHide(sender: UIButton){
        
        sender.setImage(UIImage(named: "TabCameraBtn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
        sender.layer.borderWidth = 1.5
        
        if post.active{
            sender.backgroundColor = activeCommentColor
            sender.layer.borderColor = UIColor.white.cgColor
            sender.tintColor = UIColor.white
        }
        else{
            sender.backgroundColor = UIColor.clear
            sender.tintColor = infoTextColor
            sender.layer.borderColor = infoTextColor?.cgColor
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.contentOffset.y -= self.cameraRollViewHeight.constant
            self.cameraRollViewHeight.constant = 0
            self.cameraRollView.isHidden = true
            self.postCommentBtn.isHidden = true
            self.postCommentBtn.alpha = 0.0
            
        }, completion: { (finished: Bool) in
            sender.isEnabled = true
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appAppeared(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        
    }
    
    override func viewDidLayoutSubviews() {
        
        
        self.backColorFilterView.roundCorners([UIRectCorner.topLeft, UIRectCorner.topRight, UIRectCorner.bottomLeft, UIRectCorner.bottomRight], radius: self.view.frame.width / 20)
        
    }
    
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        commentInputView.resignFirstResponder()
        if !self.cameraRollView.isHidden{
            self.cameraRollHide(sender: self.showPicsBtn)
        }
        self.commentInputView.isUserInteractionEnabled = false
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBOutlet weak var infoBackground: UIView!
    
    var today = String()
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.partyImage.backgroundColor = UIColor(hue: 128/360, saturation: 0/100, brightness: 93/100, alpha: 1.0) /* #ededed */
        
        self.setColors()
        
        
        //self.navigationController?.navigationBar.barTintColor = UIColor().mainColor()
        
        infoBackground.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        infoBackground.layer.borderWidth = 0.5
        infoBackground.layer.cornerRadius = infoBackground.frame.height / 4
        
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.attributedTitle = NSAttributedString(string: "Pull to Refresh 👽")
        
        self.cameraRollViewHeight.constant = 0
        self.toolbarHeight.constant = 0

        self.tableView.refreshControl = refresher
        self.navigationController?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        commentInputView.delegate = self
        if let nav = self.navigationController{
            if !(nav is UserNavigationController){
                if nav is MapToFullNavController{
                    self.setNavigationItem(button: .stop)
                }
                self.topConstraint.constant = 0
            }
            else{
                self.topConstraint.constant = Screen.statusBarHeight
            }
        }

        
        
        self.textBackgroundView.layer.borderWidth = 1
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.view.backgroundColor = UIColor.black
        
        postCommentBtn.layer.cornerRadius = postCommentBtn.frame.height / 6
        postCommentBtn.clipsToBounds = true
        showPicsBtn.layer.borderWidth = 1.5
        showPicsBtn.layer.cornerRadius = showPicsBtn.frame.height / 6
        showPicsBtn.clipsToBounds = true
        commentInputView.backgroundColor = UIColor.clear
        
        
        showToolbarBtn.layer.cornerRadius = showToolbarBtn.frame.height / 2
        showToolbarBtn.clipsToBounds = true
        self.userImg.layer.cornerRadius = self.userImg.frame.height / 2
        self.userImg.clipsToBounds = true
        self.userImg.layer.borderWidth = 0.5
        
        self.postCommentBtn.isHidden = true
        textBackgroundView.layer.cornerRadius = textBackgroundView.frame.height / 4
        textBackgroundView.clipsToBounds = true
        self.toolBar.layer.borderColor = UIColor.gray.cgColor
        self.toolBar.layer.borderWidth = 0.5
        self.postCommentBtn.tintColor = UserBackgroundColor().primaryColor
        
        let g = UISwipeGestureRecognizer()
        g.addTarget(self, action: #selector(closeKeyboard(_:)))
        g.direction = .down
        
        self.barBackgroundView.addGestureRecognizer(g)
        self.commentInputView.inputAccessoryView = UIView()
        self.tableView.allowsSelection = false
        
        let size = self.commentInputView.sizeThatFits(CGSize(width: self.commentInputView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        
        UIView.animate(withDuration: 0.2, animations: {
            self.barHeight.constant = size + 20
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
        
        self.initialBarViewHeight = self.barBackgroundView.frame.height
        self.initialWidth = self.commentInputView.frame.width
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showCommentMenu(_:)))
        longPressGesture.minimumPressDuration = 0.5 // 1 second lllllpress
        self.tableView.addGestureRecognizer(longPressGesture)
        
        let tapPressGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(closeKeyboard(_:)))
        self.tableView.addGestureRecognizer(tapPressGesture)
        self.reportBtn.setRadiusWithShadow()
        self.deleteBtn.setRadiusWithShadow()
        self.cancelBtn.setRadiusWithShadow()
        
        self.today = self.getDate()
    }
    
    func setColors(){
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor(named: "mainWhiteColor")
            infoTextColor = UIColor.label
            usernameColor = UIColor.secondaryLabel
            fullNameColor = UIColor.label
            commentColor = UIColor(named: "mainLabelColor")
            tintColor = UIColor.label
        } else {
            backgroundColor = UIColor.init(hue: 0.359, saturation: 0.00, brightness: 1.00, alpha: 1.00)
            infoTextColor = UIColor.init(hue: 0.148, saturation: 0.00, brightness: 0.13, alpha: 1.00)
            usernameColor = UIColor.init(hue: 0.206, saturation: 0.06, brightness: 0.56, alpha: 1.00)
            fullNameColor = UIColor.init(hue: 0.148, saturation: 0.00, brightness: 0.13, alpha: 1.00)
            commentColor = UIColor.white
            commentBorderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            tintColor = UIColor.darkGray
        }
    }
    
    
    private lazy var reportBtn: UIButton = {
        
        let button2 = UIButton.init(frame: CGRect(x: self.view.center.x - 37.5, y: self.view.frame.height + 10, width: 75, height: 75))
        
        button2.setTitle("Report", for: .normal)
        button2.backgroundColor = UIColor.lightText.withAlphaComponent(0.9)
        button2.setTitleColor(UserBackgroundColor().primaryColor, for: .normal)
        button2.layer.borderWidth = 2
        button2.layer.borderColor = UIColor.darkGray.cgColor
        
        button2.layer.cornerRadius = button2.frame.height / 2
        button2.clipsToBounds = true
        self.window.addSubview(button2)
        
        return button2
        
    }()
    
    private lazy var cancelBtn: UIButton = {
        
        
        let button3 = UIButton.init(frame: CGRect(x: reportBtn.frame.maxX + deleteBtn.frame.minX, y: self.view.frame.height + 10, width: 75, height: 75))
        button3.setTitle("Cancel", for: .normal)
        button3.backgroundColor = UIColor.lightText.withAlphaComponent(0.9)
        button3.setTitleColor(UIColor.blue, for: .normal)
        button3.addTarget(self, action: #selector(bringDownCommentMenu(_:)), for: UIControl.Event.touchUpInside)
        button3.layer.borderWidth = 2
        button3.layer.borderColor = UIColor.darkGray.cgColor
        
        button3.layer.cornerRadius = button3.frame.height / 2
        button3.clipsToBounds = true
        self.window.addSubview(button3)
        
        return button3
    }()
    
    private lazy var deleteBtn: UIButton = {
        
        let button = UIButton.init(frame: CGRect(x: (reportBtn.frame.minX / 2) - 37.5, y: self.view.frame.height + 10, width: 75, height: 75))
        
        button.setTitle("Delete", for: .normal)
        button.backgroundColor = UIColor.lightText.withAlphaComponent(0.9)
        button.setTitleColor(UIColor.red, for: .normal)
        
        button.addTarget(self, action: #selector(deleteComment(_:)), for: UIControl.Event.touchUpInside)
        
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.darkGray.cgColor
        
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        self.window.addSubview(button)
        
        return button
    }()
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        if self.downloader != nil{
            self.downloader.invalidateSessionAndCancel(true)
        }
        
        if self.commentInputView.isFirstResponder{
            self.commentInputView.resignFirstResponder()
        }
        
        
        self.animateActive(remove: !post.active)
        
        
        
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
        self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        
        self.usernameField.text = "@" + (post.username ?? "null")
        self.fullNameField.text = post.fullName
        self.userImg.image = UIImage(data:
            post.userImage ?? ((UIImage(named: "default_DP.png"))?.jpegData(compressionQuality: 1.0))!
        )
        
        let date = post.uploadDate
        let time = post.uploadTime
        let info = post.postCaption ?? ""
        
        
        self.info.text = info
        
        
        if !post.active{
            if date == self.today{
                self.dateView.text = "Today\n" + time
            }
            else{
                let displayDate = date.findMonth(abbreviation: false)
                self.dateView.text = (displayDate ?? "null") + "\n" + time
            }
        }
        
        
        
        switch post.isPic{
        case true:
            print("isPic")
            if post.imageData != nil{
                self.partyImage.image = UIImage(data: post.imageData!)
            }
            else{
                self.downloadPostImage(completionHandler: { image in
                    
                    if image != nil{
                        self.partyImage.image = image
                    }
                })
            }
            
        default:
            self.partyImage.isHidden = true
        }
        
        self.uid = post.uid
        self.partyNode = post.postID
        self.adjustHeight()
        
        let db = Firestore.firestore().collection("Users").document(uid!).collection("Posts").document(partyNode).collection("Comments")
        
        self.listener = db.order(by: "Timestamp", descending: true).limit(to: 20 + self.comments.count).addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            snapshot.documentChanges.reversed().forEach { diff in
                
                let document = diff.document
                
                if (diff.type == .added){
                    
                    let date = document["Timestamp"] as? String
                    let uid = document["UID"] as? String
                    
                    if !self.comments.contains(where: {$0.id == document.documentID}){
                        if let commentText = document["Text"] as? String { // IF COMMENT IS A TEXT COMMENT
                            let textComment = Comments(uploadDate: date!, comment: commentText, isPic: false, uid: uid!, id: document.documentID, imageData: nil, username: nil, commentImageData: nil, fullName: nil) // ADD COMMENT TO \(comments)
                            self.comments.append(textComment)
                        }
                        else if let commentPic = document["PhotoUID"] as? String{ // IF COMMENT IS PICTURE COMMENT
                            let commentImage = Comments(uploadDate: date!, comment: commentPic, isPic: true, uid: uid!, id: document.documentID, imageData: nil, username: nil, commentImageData: nil, fullName: nil) // ADD COMMENT TO \(comments)
                            self.comments.append(commentImage)
                            
                            self.loadCommentImage(storageUID: commentPic, completionHandler: { (image) in
                                if let index = self.comments.firstIndex(where: {$0.id == document.documentID}){
                                    
                                    if image != nil{
                                        self.comments[index].commentImageData = image!.jpegData(compressionQuality: 1.0)
                                        self.tableView.performBatchUpdates({
                                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                                        }, completion: { finished in
                                            if finished{
                                            }
                                        })
                                    }
                                }
                            })
                        }
                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .left)
                        }, completion: { finished in
                            if finished{
                                print("Finished Insert")
                            }
                        })
                    }
                }
                if(diff.type == .removed) {
                    
                    if self.comments.contains(where: {$0.id == document.documentID}){
                        
                        if let index = self.comments.firstIndex(where: {$0.id == document.documentID}){
                            self.comments.remove(at: index)
                            self.tableView.performBatchUpdates({
                                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                            }, completion: nil)
                        }
                    }
                    
                }
            }
        }
    }
    
    
    func downloadPostImage(completionHandler: @escaping (UIImage?) -> ()){
        
        let ref = Storage.storage().reference()
        ref.child(post.uid + "/" + "Party-" + post.picID! + ".jpg").downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                //SET POST IMAGE
                let cp = CircularProgress(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                cp.progressColor = UIColor.white /* #e0e0e0 */
                cp.trackColor = UIColor.clear
                self.partyImage.addSubview(cp)
                cp.center.y = self.partyImage.center.y - 50
                cp.center.x = self.partyImage.center.x
                self.downloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                    let dub = (Float(receivedSize) / Float(expectedSize))
                    cp.setProgressWithAnimation(duration: 0.2, value: dub, from: 0, finished: false){
                    }
                },  completed: { (image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        cp.setProgressWithAnimation(duration: 0.2, value: 1, from: 0, finished: true){
                            cp.removeFromSuperview()
                            completionHandler(image)
                        }
                    }
                })
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        listener.remove()
        downloader.invalidateSessionAndCancel(true)
        
        if !(self.navigationController is MapToFullNavController){
            self.comments.removeAll()
            self.cellHeights.removeAll()
            self.tableView.reloadData()
            
            if commentInputView.isFirstResponder{
                commentInputView.resignFirstResponder()
            }
            
            NotificationCenter.default.removeObserver(self)
            
            self.bringDownCommentMenu(nil)
        }
    }
    
    @IBOutlet weak var dateView: UITextView!
    
    func adjustHeight(){
        
        
        let newSize = self.info.sizeThatFits(CGSize(width: self.info.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        let dateSize = self.dateView.sizeThatFits(CGSize(width: self.dateView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        
        DispatchQueue.main.async {
            
            if self.partyImage.isHidden{
                self.headerView.frame.size.height = newSize + 129.5 + dateSize
            }
            else{
                self.headerView.frame.size.height = self.partyImage.frame.height + newSize + 129.5 + dateSize
            }
            self.tableView.reloadData()
        }
        
        //self.animate(username: true, image: true, description: true)
        
        /*
         if !self.isLoading{
         self.isLoading = true
         self.activity.startAnimating()
         self.getComments(fromInterval: ""){
         self.activity.stopAnimating()
         print("refresh ended")
         self.tableView.refreshControl?.endRefreshing()
         self.isLoading = false
         
         if !self.commentInputView.text.isEmpty || self.commentImage != nil{
         self.postCommentBtn.isEnabled = true
         }
         }
         }
         
         */
    }
    
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        self.today = self.getDate()
        
        guard let userUID = uid else{ refreshControl.endRefreshing(); return }
        
        let ref = Firestore.firestore().collection("Users").document(userUID).collection("Posts").document(self.post.postID)
        ref.getDocument(){ (querySnapshot, err) in
            if err != nil {
                print("Error getting documents: \(err?.localizedDescription ?? "")")
            } else {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    if refreshControl.isRefreshing{
                        refreshControl.endRefreshing()
                    }
                }
                
                let infoString = querySnapshot!["OtherInfo"] as? String
                self.post.postCaption = infoString
                self.likes = querySnapshot!["Likes"] as? Int ?? 0
                let displayDate = querySnapshot?["DisplayTime"] as? String
                let timestamp = querySnapshot?["Timestamp"] as? String
                
                let components = displayDate?.components(separatedBy: ", ")
                var postTime = components?[1]
                let date = components?[0]
                
                if postTime?.first == "0"{
                    postTime?.removeFirst()
                }
                
                self.post.uploadDate = date ?? "null"
                self.post.uploadTime = postTime ?? "null"
                
                
                if date == self.today{
                    self.dateView.text = "Today\n" + (postTime ?? "null")
                }
                else{
                    let displayDate = date?.findMonth(abbreviation: false)
                    self.dateView.text = (displayDate ?? "null") + "\n" + (postTime ?? "null")
                }
                
                let ambiguousTime = self.time(time: timestamp ?? "null")
                
                
                let load = self.loadDate(ambiguous: true)
                let current = self.currentDate()
                
                
                if ambiguousTime <= current && ambiguousTime >= load{
                    
                    self.post.active = true
                    self.animateActive(remove: false)
                }
                else{
                    self.post.active = false
                    self.animateActive(remove: true)
                }
                
                self.info.text = infoString
                
                self.adjustHeight()
            }
        }
        
        self.downloadUserImg(uid: self.post.uid, completionHandler: { userImg, username, fullName, id in
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                if refreshControl.isRefreshing{
                    refreshControl.endRefreshing()
                }
            }
            if userImg != nil{
                //SET USER IMG
                self.post.userImage = userImg
                self.post.userImageID = id
                self.post.username = username
                self.post.fullName = fullName
                self.userImg.image = UIImage(data: userImg!)
                self.usernameField.text = "@" + username
                self.fullNameField.text = fullName
                
                if let match = self.comments.first(where: {$0.uid == self.post.uid}){
                    if userImg != match.imageData || username != match.username || fullName != match.fullName{
                        for comment in self.comments{
                            if comment.uid == self.post.uid{
                                if let index = self.comments.firstIndex(where: {$0.id == comment.id}){
                                    comment.username = username
                                    comment.fullName = fullName
                                    comment.imageData = userImg
                                    self.tableView.performBatchUpdates({
                                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                    }, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    @IBOutlet weak var backColorFilterView: UIView!
    
    var backgroundColor: UIColor? = UIColor()
    var infoTextColor: UIColor? = UIColor()
    var usernameColor: UIColor? = UIColor()
    var fullNameColor: UIColor? = UIColor()
    var commentColor: UIColor? = UIColor()
    var commentBorderColor: CGColor?
    var tintColor: UIColor? = UIColor()
    
    
    let activeBackgroundColor = UIColor.black.withAlphaComponent(0.3)
    let activeUsernameColor = UIColor.init(hue: 0.359, saturation: 0.00, brightness: 1.00, alpha: 1.00)
    let activeFullNameColor = UIColor.init(hue: 0.206, saturation: 0.06, brightness: 0.56, alpha: 1.00)
    let activeCommentColor = UIColor.white.withAlphaComponent(0.2)
    let activeCommentBorderColor = UIColor.white
    let activeTintColor = UIColor.init(hue: 0.359, saturation: 0.00, brightness: 1.00, alpha: 1.00)
    
    /*
     
    
     
     */
    
    
    @IBOutlet weak var camBtn: UIButton!
    
    func animateActive(remove: Bool){
        
        
        if remove{
            
            self.backView.layer.removeAllAnimations()
            
            if self.post.uploadDate == self.today{
                self.dateView.text = "Today\n" + self.post.uploadTime
            }
            else{
                let displayDate = self.post.uploadDate.findMonth(abbreviation: false)
                self.dateView.text = (displayDate ?? "null") + "\n" + self.post.uploadTime
            }
            
        
            dateView.textColor = infoTextColor
            info.textColor = infoTextColor
            usernameField.textColor = usernameColor
            fullNameField.textColor = fullNameColor
            self.barBackgroundView.backgroundColor = backgroundColor
            self.toolBar.backgroundColor = backgroundColor
            //self.keyBoardTopView.backgroundColor = backgroundColor
            self.backColorFilterView.backgroundColor = UIColor.clear
            self.tableView.backgroundColor = backgroundColor
            self.checkDarkModeKeyboard(activeParty: false)

            self.backView.backgroundColor = backgroundColor
            self.commentInputView.textColor = infoTextColor
            self.textBackgroundView.layer.borderColor = infoTextColor?.cgColor
            self.textBackgroundView.backgroundColor = commentColor
            
            self.navigationController?.navigationBar.tintColor = tintColor
            
            showPicsBtn.setImage(UIImage(named: "TabCameraBtn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
            
            camBtn.setImage(UIImage(named: "CommentCamBtn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
            
            self.camBtn.tintColor = infoTextColor
            camBtn.backgroundColor = UIColor.clear
            self.showPicsBtn.backgroundColor = UIColor.clear
            self.showPicsBtn.layer.borderColor = infoTextColor?.cgColor
            self.showPicsBtn.tintColor = infoTextColor
            self.setPlaceholder(textView: commentInputView, textColor: usernameColor)
            self.userImg.layer.borderColor = tintColor?.cgColor
            
        }
        else{
            self.dateView.text = "Happening Now\n" + (post.uploadTime)
            dateView.textColor = UIColor.white
            info.textColor = UIColor.white
            usernameField.textColor = activeUsernameColor
            fullNameField.textColor = activeFullNameColor
            self.barBackgroundView.backgroundColor = activeBackgroundColor
            self.toolBar.backgroundColor = activeBackgroundColor
            //self.keyBoardTopView.backgroundColor = activeBackgroundColor
            self.backColorFilterView.backgroundColor = UIColor.darkGray
            self.tableView.backgroundColor = UIColor.clear
            self.checkDarkModeKeyboard(activeParty: true)
            
            self.commentInputView.textColor = UIColor.white
            self.userImg.layer.borderColor = UIColor.white.cgColor
            self.textBackgroundView.layer.borderColor = UIColor.white.cgColor
            self.textBackgroundView.backgroundColor = activeCommentColor
            self.partyImage.backgroundColor = UIColor.black
            
            self.navigationController?.navigationBar.tintColor = activeTintColor
            
            showPicsBtn.setImage(UIImage(named: "TabCameraBtn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
            
            camBtn.setImage(UIImage(named: "CommentCamBtn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
            
            self.camBtn.tintColor = UIColor.white
            self.showPicsBtn.backgroundColor = activeCommentColor
            self.showPicsBtn.layer.borderColor = UIColor.white.cgColor
            self.showPicsBtn.tintColor = UIColor.white
            self.setPlaceholder(textView: commentInputView, textColor: commentColor?.withAlphaComponent(0.5))
            
            
            UIView.animate(withDuration: 1, delay: 0, options:
                [.allowUserInteraction,
                 .repeat,
                 .autoreverse],
                           animations: {
                            self.backView.backgroundColor = UIColor.init(red: 0.3, green: 0.0, blue: 0.8, alpha: 0.2)
                            self.backView.backgroundColor = UIColor.init(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.2)
            }, completion:nil )
        }
    }
    
    func checkDarkModeKeyboard(activeParty: Bool){
      
        if #available(iOS 12.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                self.commentInputView.keyboardAppearance = .dark
            case .light, .unspecified:
                fallthrough
            @unknown default:
                if activeParty{
                    self.commentInputView.keyboardAppearance = .dark
                }
                else{
                    self.commentInputView.keyboardAppearance = .light
                }
            }
        } else {
            if activeParty{
                self.commentInputView.keyboardAppearance = .dark
            }
            else{
                self.commentInputView.keyboardAppearance = .light
            }
        }
    }
    
    func animate(username: Bool, image: Bool, description: Bool){
        
        if username{
            
            usernameField.alpha = 0.0
            UIView.animate(withDuration: 0.5, animations: {
                self.usernameField.alpha = 1.0
            })
        }
        
        if image{
            
            partyImage.alpha = 0.0
            UIView.animate(withDuration: 0.5, animations: {
                self.partyImage.alpha = 1.0
            })
        }
        
        
        if description{
            info.alpha = 0.0
            UIView.animate(withDuration: 0.5, animations: {
                self.info.alpha = 1.0
            })
        }
    }
    
    @objc func unwindToMap(){
        self.performSegue(withIdentifier: "toFeed", sender: nil)
    }
    
    func setNavigationItem(button: UIBarButtonItem.SystemItem) {
        
        
        let button = UIBarButtonItem(barButtonSystemItem: button, target: self, action: #selector(self.unwindToMap))
        button.tintColor = UIColor.darkGray
        
        
        self.navigationItem.leftBarButtonItem = button
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if let vc = viewController as? FeedViewController{
            vc.postClass = post
        }
        else if let areaVC = viewController as? AreaPostsViewController{
            areaVC.postClass = post
        }
        else if let myVC = viewController as? UserViewController{
            myVC.postClass = post
        }
        else if let vc = viewController as? FriendProfileViewController{
            self.navigationController?.delegate = vc
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
    }
    @IBOutlet weak var barHeight: NSLayoutConstraint!
    
    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Leave a comment.."
        placeholderLabel.font = UIFont.systemFont(ofSize: 15.0)
        placeholderLabel.sizeToFit()
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.textColor = textColor
        
        if !textView.subviews.contains(placeholderLabel){
            textView.addSubview(placeholderLabel)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor,  constant: 5).isActive = true
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        
    }
    
    var previousHeight: CGFloat! = nil
    var initialWidth = CGFloat()
    
    var textViewEditingWidth = CGFloat()
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
    }
    
    
    @IBOutlet weak var showToolbarBtn: UIButton!
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        self.initialWidth = textView.frame.width
        self.previousHeight = textView.frame.height
        
        print("changed text")
        
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        if (textView.sizeThatFits(CGSize(width: self.initialWidth, height: CGFloat.greatestFiniteMagnitude)).height + 20) < self.initialBarViewHeight + 100{
            print("reducing")
            textView.isScrollEnabled = false
            let size = textView.sizeThatFits(CGSize(width: self.initialWidth, height: CGFloat.greatestFiniteMagnitude)).height
            self.barHeight.constant = size + 20
            
            DispatchQueue.main.async {
                
                if self.barHeight.constant > self.previousHeight{
                    print("greater")
                    let difference = self.barHeight.constant - self.previousHeight
                    self.tableView.contentOffset.y += difference
                    
                }
                    
                else if self.barHeight.constant < self.previousHeight{
                    print("less")
                    let difference = self.previousHeight - self.barHeight.constant
                    self.tableView.contentOffset.y -= difference
                }
            }
            self.previousHeight = self.barHeight.constant
            self.barBackgroundView.setNeedsLayout()
            self.barBackgroundView.layoutIfNeeded()
            
        }
        else{
            print("expanding")
            let string = textView.text.replacingOccurrences(of: " ", with: "")
            if string.count > 1000{
                textView.text.removeLast(textView.text.count - 1000)
            }
            
            if !textView.isScrollEnabled{
                DispatchQueue.main.async {
                    textView.isScrollEnabled = true
                    self.barHeight.constant = 100 + self.initialBarViewHeight
                    let difference = (self.initialBarViewHeight + 100) - self.previousHeight
                    print("Difference: \(difference)")
                    self.tableView.contentOffset.y += difference
                    self.barBackgroundView.setNeedsLayout()
                    self.barBackgroundView.layoutIfNeeded()
                }
            }
        }
        
        if !textView.text.isEmpty{
            if !self.showToolbarBtn.isHidden{
                self.postCommentBtn.tintColor = UserBackgroundColor().primaryColor
                self.postCommentBtn.isEnabled = true
                UIView.animate(withDuration: 0.1, animations: {
                    self.showToolbarBtn.alpha = 0.0
                    self.showToolbarBtn.isHidden = true
                })
            }
        }
        else{
            if self.showToolbarBtn.isHidden{
                self.postCommentBtn.isEnabled = false
                UIView.animate(withDuration: 0.1, animations: {
                    self.showToolbarBtn.alpha = 1.0
                    self.showToolbarBtn.isHidden = false
                })
            }
        }
        
    }
    
    
    
    @IBAction func bringUpMenu(_ sender: UIButton?) {
        
        
        if self.toolBar.isHidden{
            self.commentInputView.resignFirstResponder()
            
            DispatchQueue.main.async {
                
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.toolBar.isHidden = false
                    self.toolbarHeight.constant = 40
                    
                }, completion: {(finished : Bool) in
                    if(finished)
                    {
                        
                        self.tableView.contentOffset.y += self.toolbarHeight.constant
                        self.cameraBtnView.isHidden = false
                        self.photosBtnView.isHidden = false
                    }
                })
            }
        }
        else{
            
            if !self.cameraRollView.isHidden{
                self.cameraRollHide(sender: self.showPicsBtn)
            }
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.toolBar.isHidden = true
                    self.toolbarHeight.constant = 0
                    self.tableView.contentOffset.y -= self.toolbarHeight.constant
                    self.cameraBtnView.isHidden = true
                    self.photosBtnView.isHidden = true
                }, completion: {(finished : Bool) in
                    if(finished)
                    {
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    }
                })
            }
        }
    }
}




extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }
        
        return arrayOrdered
    }
}

extension Array
{
    func filterDuplicate<T>(_ keyValue:(Element)->T) -> [Element]
    {
        var uniqueKeys = Set<String>()
        return filter{uniqueKeys.insert("\(keyValue($0))").inserted}
    }
}

extension UITextView {
    
    func centerText() {
        
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect
        self.contentInset.top = topCorrect
    }
}

extension UIView{
    
    
    func addShadowBehindBar(){
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 10
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        
    }
}

extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension String{
    
    func findMonth(abbreviation: Bool) -> String?{
        
        let dateCmpnts = self.components(separatedBy: "-")
        let year = dateCmpnts[0]
        var month = dateCmpnts[1]
        let day = dateCmpnts[2]
        var monthCheck: String! = nil
        
        switch month{
            
        case "01":
            monthCheck = "January"
        case "02":
            monthCheck = "February"
        case "03":
            monthCheck = "March"
        case "04":
            monthCheck = "April"
        case "05":
            monthCheck = "May"
        case "06":
            monthCheck = "June"
        case "07":
            monthCheck = "July"
        case "08":
            monthCheck = "August"
        case "09":
            monthCheck = "September"
        case "10":
            monthCheck = "October"
        case "11":
            monthCheck = "November"
        case "12":
            monthCheck = "December"
        default:
            monthCheck = "null"
        }
        
        if abbreviation{
            
            if monthCheck == "September"{
                month = monthCheck.substring(to: 3) + "."
            }
            else{
                month = monthCheck.substring(to: 2) + "."
            }
        }
        else{
            month = monthCheck
        }
        
        let newDate = month + " " + day + ". " + year
        
        return newDate
    }
}

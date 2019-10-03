//
//  ProfileViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-16.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftKeychainWrapper
import FirebaseStorage
import FirebaseUI
import FirebaseMessaging
import OneSignal
import FirebaseFirestore
/*
 

 */
class ProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    var userLoaded = String()
    var nameLoaded = String()
    var url = ""
    var dp: UIImage = UIImage(named: "default_DP")!
    let uid = KeychainWrapper.standard.string(forKey: "USER")
    let activityView = UIActivityIndicatorView()
    var changedDP = Bool()
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet var chooseSource: [UIButton]!
    @IBOutlet weak var bottom: UITextField!
    @IBOutlet weak var chooseDP: UIButton!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var fullName: UITextField!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var bioField: UITextView!
    
    typealias DownloadComplete = () -> ()
    
    @IBAction func removePhoto(_ sender: UIButton) {
        
        addDesign()
        activityView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { //
            self.profilePic.image = UIImage(named: "default_DP")
            self.activityView.stopAnimating()
        }
    }
    
    @IBAction func profileButtonPressed(_ sender: UIButton) {
        
        chooseSource.forEach{ (sourceBtn) in
            UIView.animate(withDuration: 0.25, animations: {
                sourceBtn.isHidden = !sourceBtn.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func crop(image: UIImage) -> UIImage? {
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }
        let size = CGSize(width: imageWidth, height: imageHeight)
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            let cropped = UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
            return cropped
        }
        return nil
    }
    
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.view.alpha = 0.0
        UIView.animate(withDuration: 0.30, animations: {
            self.view.alpha = 1.0
            //let vc = self.parent as? UserViewController
            //vc?.titleItem.title = "Edit Profile"
        
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0
            
        }, completion: {(finished : Bool) in
            if(finished)
            {
                self.willMove(toParent: nil)
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        })
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showAnimate()
        
        
        profilePic.image = UserInfo.dp
        bottom.text = KeychainWrapper.standard.string(forKey: "USERNAME")
        fullName.text = KeychainWrapper.standard.string(forKey: "FULL_NAME")
        bioField.text = KeychainWrapper.standard.string(forKey: "USER_BIO")
        
        
        profilePic.layer.cornerRadius = self.profilePic.frame.size.width / 2;
        profilePic.clipsToBounds = true;
        self.navigationController?.isNavigationBarHidden = false
        chooseDP.layer.cornerRadius = chooseDP.frame.height / 2.0
        chooseSource.forEach{ (sourceBtn) in
            sourceBtn.layer.cornerRadius = sourceBtn.frame.height / 2.0
            sourceBtn.isHidden = true
        }
        bottom.layer.cornerRadius = bottom.frame.height / 2.0
        
        cancelBtn.layer.cornerRadius = cancelBtn.frame.height / 2
        cancelBtn.clipsToBounds = true
        
        saveBtn.layer.cornerRadius = saveBtn.frame.height / 2
        saveBtn.clipsToBounds = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appAppeared(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        chooseSource.forEach{ (sourceBtn) in
            sourceBtn.layer.cornerRadius = sourceBtn.frame.height / 2.0
            sourceBtn.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        self.bioField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        let bottomPadding = self.view.safeAreaInsets.bottom
        print(bottomPadding)
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollView.contentInset.bottom = keyboardHeight - bottomPadding
                self.scrollView.scrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
            })
        }
    }
    
    
    @objc func appAppeared(_ notification: Notification){
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        DispatchQueue.main.async {
            self.scrollView.contentInset.bottom = 0
        
            
            self.scrollView.scrollIndicatorInsets.bottom = 0
            self.bioField.isUserInteractionEnabled = true
        }
    }
    
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            let bottomPadding = self.view.safeAreaInsets.bottom
            
            self.bioField.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.animate(withDuration: 0.2, animations: {
                
                self.scrollView.contentInset.bottom -= keyboardHeight - bottomPadding
                self.scrollView.scrollIndicatorInsets.bottom -= keyboardHeight - bottomPadding
            })
        }
        
    }
    
    @IBAction func unwindToEditController(segue:  UIStoryboardSegue) {
        
        updatePhoto()
    }

    @IBAction func startChoosing(_ sender: UITextField, forEvent event: UIEvent){
        
        bottom.placeholder = "Username"
    }
    
    @IBAction func chosen(_ sender: UITextField, forEvent event: UIEvent) {
        
        userLoaded = bottom.text!
    }
    
    func updatePhoto(){
        
        
        profilePic.image = dp
    }
    
    
    
    func save(uid: String, username: String, dpURL: String, imageUid: String, name: String, bio: String?, profileImage: Data){
        
        if KeychainWrapper.standard.object(forKey: "NOTIF") == nil{
            saveNotificationToken()
        }
        let user = Firestore.firestore().collection("Users").document(uid)
        var userData = [String : Any]()
        switch changedDP{
        case true:
            let savedImageCompletion = self.saveImage(profilePic.image!, name: "DP", isDP: true)
            if(savedImageCompletion){
                userData["ProfilePictureUID"] = imageUid
                KeychainWrapper.standard.set(imageUid, forKey: "IMAGE_UID")
                UserDefaults.standard.set(true, forKey: "DP_CHANGE")
            }
        default:
            break
        }
        if name != KeychainWrapper.standard.string(forKey: "FULL_NAME"){
            userData["Full Name"] = name
            KeychainWrapper.standard.set(name, forKey: "FULL_NAME")
        }
        if bio != KeychainWrapper.standard.string(forKey: "USER_BIO"){
            userData["Bio"] = bio
            KeychainWrapper.standard.set(bio!, forKey: "USER_BIO")
        }

        
        if username != KeychainWrapper.standard.string(forKey: "USERNAME"){
            Firestore.firestore().collection("Users").whereField("Username", isEqualTo: username).getDocuments { (querySnap, err) in
                
                if let err = err{
                    print(err.localizedDescription)
                }
                if querySnap?.isEmpty ?? false{
                    //NOT CHARGED
                    userData["Username"] = username
                    print(userData)
                    user.updateData(userData, completion: { (error) in
                        if let err = error{
                            print(err.localizedDescription)
                        }
                        else{
                            KeychainWrapper.standard.set(username, forKey: "USERNAME")
                            self.rewindBack()
                        }
                    })
                }
                else{
                    print(querySnap?.documents ?? [])
                    print("has already")
                    return
                }
            }
        }
        else{
            if !userData.isEmpty{
                print(userData)
                user.updateData(userData)
            }
            rewindBack()
        }
    }
    
    func rewindBack(){
        
        self.activityView.stopAnimating()
        let vc =  self.parent as? UserViewController
        let vc2 = self.parent?.tabBarController?.viewControllers?.first as? MapViewController
        vc?.setupUserView()
        //vc?.collectionView?.reloadData()
        removeAnimate()
    }
    
    func saveNotificationToken(){
        
        print("nah")
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId
        print("userID = \(userID ?? "no")")
        let pushToken = status.subscriptionStatus.pushToken
        print("pushToken = \(pushToken ?? "")")
        if pushToken != nil {
            if let playerID = userID {
                Firestore.firestore().collection("Users").document(uid!).updateData([
                    "Notification ID" : playerID
                    ])
                KeychainWrapper.standard.set(playerID, forKey: "NOTIF")//  *********SAVED HERE
            }
        }
    }
    
    @IBAction func resignKeyboard(_ sender: UITapGestureRecognizer) {
        
        if self.bioField.isFirstResponder{
            self.bioField.resignFirstResponder()
        }
        else if self.fullName.isFirstResponder{
            self.fullName.resignFirstResponder()
        }
        else if self.bottom.isFirstResponder{
            self.bottom.resignFirstResponder()
        }
    }
    @IBAction func cancel(_ sender: UIButton) {
        
        self.bioField.resignFirstResponder()
        let vc =  self.parent as? UserViewController
        removeAnimate()
        vc?.setupUserView()
    }
    
    @IBAction func save(_ sender: UIButton) {
        if let uid = KeychainWrapper.standard.string(forKey: "USER"){
            self.bioField.resignFirstResponder()
            addDesign()
            activityView.startAnimating()
            guard let username = bottom.text else{return}
            let name = fullName.text
            let bio = bioField.text
            //let phoneNumber = KeychainWrapper.standard.string(forKey: "PHONE_NUM") ?? ""
            
            if(changedDP){
                let imgUid = NSUUID().uuidString
                let storageRef = Storage.storage().reference().child(uid).child("profile_pic-" + imgUid  + ".png")
                if let currentDP = self.profilePic.image{
                    guard let cropped = crop(image: (currentDP)) else{return}
                    if let uploadData = cropped.jpegData(compressionQuality: 0.8){
                        storageRef.putData(uploadData, metadata: nil, completion:{ (metaData, error) in
                            if error != nil{
                                print(error?.localizedDescription ?? "no error")
                                return
                            }else{
                                storageRef.downloadURL { (url, error) in
                                    if let dpURL = url{
                                        self.save(uid: uid, username: username, dpURL: dpURL.absoluteString, imageUid: imgUid, name: name ?? username, bio: bio, profileImage: uploadData)
                                    }
                                }
                            }
                        })
                    }
                }
            }
                
            else{
                
                let data = Data()
                
                self.save(uid: uid, username: username, dpURL: "", imageUid: "", name: name!, bio: bio, profileImage: data)
            }
        }
        
    }
    
    func addDesign(){
        
        activityView.color  = UIColor.gray
        activityView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityView)
        designConstraints()
    }
    
    func designConstraints(){
        
        //activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //activityView.centerYAnchor.constraint(equalTo: logOut.centerYAnchor, constant: 15).isActive = true
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //let profileVC = segue.destination as? UserViewController
        
        let tabVC = segue.destination as? PhotosTabVC
        
        tabVC?.fromProfile = true
    }
    
}



//
//  RetrieveUserFromLogInVC.swift
//  Pictomap
//
//  Created by Artak on 2018-07-09.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseStorage
import FirebaseMessaging
import OneSignal
import FirebaseFirestore


class RetrieveUserFromLogInVC: UIViewController {
    
    //let penguin = UIImageView()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var fullNameField: UILabel!
    @IBOutlet weak var usernameField: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    private var nextViewNumber = Int()
    private var unwinded = Bool()
    var username: String! = nil
    var fullName: String! = nil


    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.color = UIColor.darkGray
        profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2
        profilePicture.clipsToBounds = true
        activityIndicator.startAnimating()
        print("load")
        
        // Do any additional setup after loading the view.
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        retrieveUser(uid: uid!)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func retrieveUser(uid: String){
        
        let account = Firestore.firestore().collection("Users").document(uid)
        
        account.getDocument(completion: { (snap, err) in
            
            if err != nil || !(snap?.exists ?? true){
                
                print(err?.localizedDescription ?? "No User")
                let data = ["Username" : self.username ?? "",
                            "Full Name" : self.fullName ?? ""]
                Firestore.firestore().collection("Users").document(uid).setData(data, completion: {(error) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        KeychainWrapper.standard.set(self.username!, forKey: "USERNAME")
                        KeychainWrapper.standard.set(self.fullName!, forKey: "FULL_NAME")

                        self.performSegue(withIdentifier: "toUser", sender: nil)
                    }
                })
            }
            
            else{
                let primaryColor = snap?["Primary Background Color"] as? String
                let secondaryColor = snap?["Secondary Background Color"] as? String
                UserDefaults.standard.set(primaryColor, forKey: "PrimaryUserColor")
                UserDefaults.standard.set(secondaryColor, forKey: "SecondaryUserColor")
                self.saveNotificationToken()
                let username = snap!["Username"] as? String
                let fullName = snap!["Full Name"] as? String
                let imageID = snap!["ProfilePictureUID"]  as? String
                let userBio = snap!["Bio"] as? String
                let badges = snap!["Badges"] as? [String]
                
                //let phoneNumber = snap!["Phone Number"] as? String
                KeychainWrapper.standard.set(imageID ?? "", forKey: "IMAGE_UID")
                KeychainWrapper.standard.set(username ?? "", forKey: "USERNAME")
                UserDefaults.standard.set(badges, forKey: "badges")

                //KeychainWrapper.standard.set(phoneNumber ?? "", forKey: "PHONE_NUM")
                KeychainWrapper.standard.set(fullName ?? "", forKey: "FULL_NAME")
                KeychainWrapper.standard.set(userBio ?? "", forKey: "USER_BIO")

                var followingList = [String]()
            Firestore.firestore().collection("Users").document(uid).collection("Following").getDocuments() { (query, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else if !(query?.isEmpty ?? true) {
                        for followingUID in query?.documents ?? [] {
                            followingList.append(followingUID.documentID)
                        }
                        UserDefaults.standard.set(followingList, forKey: "followingList")
                        UserFollowing.userFollowing = followingList
                    }
                    let ref = Storage.storage().reference()
                    ref.child(uid + "/" + "profile_pic-" + (imageID ?? "") + ".png").downloadURL(completion: { url, error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            return
                        }
                        else{
                            self.retrieve(url: (url?.absoluteString)!)
                        }
                    })
                }
            }
        })
    }
    
    func saveNotificationToken(){
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {

                Firestore.firestore().collection("Users").document(uid!).updateData(["Notification ID" : playerID], completion: { (err) in
                    
                    if err != nil{
                        print(err?.localizedDescription ?? "")
                    }
                    else{
                        KeychainWrapper.standard.set(playerID, forKey: "NOTIF")//  *********SAVED HERE
                    }
                })
            }
        }
    }
    
    func retrieve(url: String){
        
        let httpsReference = Storage.storage().reference(forURL: url)
        httpsReference.getData(maxSize: 1 * 2048 * 2048, completion: { (data, error) in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }else{
                
                if let picData = data{
                    
                    guard let image = UIImage(data: picData) else{return}
                    let saved = self.saveImage(image, name: "DP", isDP: true)
                    
                    if(saved){
                        self.activityIndicator.stopAnimating()
                        self.performSegue(withIdentifier: "toUser", sender: nil)
                    }
                }
            }
        })
    }
    
    
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        


     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
    
    
}

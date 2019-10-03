//
//  EventDescriptionViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-13.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseDatabase
import FirebaseStorage
import OneSignal


class EventDescriptionViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var eventDate: UITextView!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    @IBOutlet weak var eventInfo: UITextView!
    let placeholderLabel = UILabel()
    let done = UIButton()
    let centerText = UIButton()
    var privateMode: Bool = true
    var address = String()
    var city = String()
    var uploader = String()
    var chosen = Bool()
    var date: String?
    var time: String?
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var fullnameField: UILabel!
    @IBOutlet weak var usernameField: UILabel!
    
    @IBOutlet weak var showFiltersBtn: UIButton!
    
    @IBOutlet weak var retakePhotoBtn: UIButton!
    
    @IBOutlet weak var removePhotoBtn: UIButton!
    
    
    @IBOutlet weak var partyPic: UIImageView!
    @IBOutlet weak var privacySwitch: UISwitch!
    var followerNotifIDs = [String]()
    var image: UIImage? = nil
    
    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventInfo.delegate = self
        
        //setPlaceholder()
        
        self.showFiltersBtn.isHidden = true
        self.removePhotoBtn.isHidden = true
        self.retakePhotoBtn.isHidden = true
        self.userImageView.image = UserInfo.dp
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height / 2
        self.userImageView.clipsToBounds = true
        
        self.usernameField.text = "@" + (KeychainWrapper.standard.string(forKey: "USERNAME") ?? "null")
        self.fullnameField.text = KeychainWrapper.standard.string(forKey: "FULL_NAME")
        self.containerView.isHidden = true
        if image != nil{
            self.partyPic.image = image
        }
        else{
            self.partyPic.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
    }
    @IBAction func showButtons(_ sender: UITapGestureRecognizer) {
        
        
        if showFiltersBtn.isHidden{
            self.animBtns(buttons: [showFiltersBtn, removePhotoBtn, retakePhotoBtn], show: true)
        }
        else{
            self.animBtns(buttons: [showFiltersBtn, removePhotoBtn, retakePhotoBtn], show: false)
        }
    }
    @IBOutlet weak var partyPicView: UIView!
    
    @IBAction func retakePhoto(_ sender: UIButton) {
    }
    
    func animBtns(buttons: [UIButton], show: Bool){
        if show{
            for button in buttons{
                button.isHidden = false
                button.alpha = 0.0
                
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 1.0
                })
            }
        }
        else{
            for button in buttons{
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 0.0
                }, completion: {(finished : Bool) in
                    button.isHidden = true
                })
            }
        }
    }
    
    @IBAction func removePhoto(_ sender: UIButton) {
        
        if self.partyPic.image != nil{
            UIView.animate(withDuration: 0.1, animations: {
                self.partyPic.alpha = 0.0
                
            }, completion: {(finished : Bool) in
                self.partyPic.image = nil
                self.partyPicView.isHidden = true
            })
        }
    }
    
    @IBAction func showFilters(_ sender: UIButton) {
        
        
        if self.containerView.isHidden{
            self.containerView.isHidden = false
            self.containerView.alpha = 0.0
            if let vc = self.children.first as? PhotoFiltersViewController{
                self.animBtns(buttons: [removePhotoBtn, retakePhotoBtn], show: false)
                vc.showFilters()
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.containerView.alpha = 1.0
            })
        }
        else{
            self.animBtns(buttons: [removePhotoBtn, retakePhotoBtn], show: true)
            UIView.animate(withDuration: 0.2, animations: {
                self.containerView.alpha = 0.0
            }, completion: {(finished : Bool) in
                self.containerView.isHidden = true
            })
        }
    }
    
    func setPicture(){
        
        if (chosen){
            if let chosen = UserDefaults.standard.object(forKey: "CHOSE") as? Data{
                
                partyPic.image = UIImage(data: chosen)
                
            }
        }
        else{
            
            partyPic.image = UIImage(named: "default_DP.png")
        }
    }
    
    func setPlaceholder(){
        
        placeholderLabel.text = "Additional info about this event ...."
        placeholderLabel.font = UIFont.init(name: "Lato-Regular", size: 15.0) ?? UIFont.boldSystemFont(ofSize: 14.0)
        placeholderLabel.sizeToFit()
        
        eventInfo.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (eventInfo.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !eventInfo.text.isEmpty
    }
    
    func setToolbar(){
        
        let customView = UIToolbar()
        customView.sizeToFit()
        customView.backgroundColor = UIColor.red
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.doneBtnFromKeyboardClicked))
        
        
        customView.items = [btnDoneOnKeyboard]
        
        
        eventInfo.inputAccessoryView = customView
        
        
    }
    @IBAction func partyPicture(_ sender: UIButton) {
        
        
    }
    
    @IBAction func doneBtnFromKeyboardClicked (sender: Any) {
        print("Done Button Clicked.")
        //Hide Keyboard by endEditing or Anything you want.
        self.view.endEditing(true)
    }
    
    
    //Delegate Method.
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    
    @IBAction func privateMode(_ sender: UISwitch) {
        
        switch privacySwitch.isOn{
            
        case true:
            
            let alert = UIAlertController(title: "Change Privacy?", message: "Only your followers will receive an invite notification to this event.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.privacySwitch.isOn = true
                self.privateMode  = true
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                self.privacySwitch.isOn = false
                self.privateMode = false
            }))
            self.present(alert, animated: true, completion: nil)
            
        case false:
            
            let alert = UIAlertController(title: "Change Privacy?", message: "Anyone within a radius of 50km from this event's address will receive an invite notification to this event.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.privacySwitch.isOn = false
                self.privateMode = false;
                //Privacy Mode Off
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                self.privacySwitch.isOn = true
                self.privateMode = true
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func publishEvent(_ sender: UIButton) {
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        
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
        
        
        print(newDate)
        
        let n = NSUUID().uuidString
        
        guard let image = partyPic.image ?? UIImage(named: "default_DP.png") else{return}
        
        
        let storageRef = Storage.storage().reference().child(uid!).child("Party-" + n + ".jpg")
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        if let uploadData = image.jpegData(compressionQuality: 0.8){
            storageRef.putData(uploadData, metadata: nil, completion:{ (metaData, error) in
                if error != nil{
                    print(error?.localizedDescription ?? "no error")
                    return
                }else{
                    UserDefaults.standard.removeObject(forKey: "POSTS")
                    
                    storageRef.downloadURL { (url, error) in
                        
                        if(self.privateMode){
                            
                            let baseRef = Database.database().reference()
                            baseRef.child("Users").child(uid!).child("Followers").observeSingleEvent(of: .value, with: {(snapshot) in
                                if !snapshot.exists(){
                                    
                                    print("no snap")
                                    
                                    self.uploadToDatabase(picRef: n, newDate: newDate, uid: uid!)
                                }
                                    
                                else{
                                    
                                    for userFollowers in snapshot.children.allObjects as! [DataSnapshot] {
                                        print(userFollowers.key)
                                        baseRef.child("Users").child(userFollowers.key).child("Credentials").child("Notification ID").observeSingleEvent(of: .value, with: {(snap) in
                                            
                                            
                                            if !snap.exists(){
                                                
                                            }
                                                
                                            else{
                                                
                                                let username = KeychainWrapper.standard.string(forKey: "USERNAME")
                                                OneSignal.postNotification([
                                                    
                                                    "headings": ["en": "New Party"],
                                                    "contents": ["en": "by " + username!],
                                                    "include_player_ids": [snapshot.value as? String],
                                                    "data": [
                                                        "UID": self.address,
                                                        "Node" : newDate]
                                                    ])
                                            }
                                            
                                            self.uploadToDatabase(picRef: n, newDate: newDate, uid: uid!)
                                        })
                                    }
                                }
                            })
                        }else{
                            
                            //Public Mode
                            
                        }
                        
                        
                        
                        
                    }
                }
                
            })
        }
        
        
    }
    
    func uploadToDatabase(picRef: String, newDate: String, uid: String){
        
        let newId = NSUUID().uuidString
        
        let baseRef = Database.database().reference().child("Users").child(uid).child("Created Parties").child(newId)
        
        let data = [
            "Picture" : picRef,
            "Timestamp" : newDate,
            "Caption" : self.eventInfo.text ?? "",
            "Address" : self.address,
            "City" : self.city,
            ] as [String : Any]
        
        baseRef.setValue(data)
        UserDefaults.standard.set(true, forKey: "New_Post")
        
        
        self.performSegue(withIdentifier: "posted", sender: nil)
    }
    
    @IBAction func choosePicture(_ sender: UIButton) {
        
        
    }
    
    @IBAction func unwindPhoto(segue: UIStoryboardSegue){
        
        chosen = true
        setPicture()
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        //let vc = segue.destination as? MapViewController
        
        //vc?.unwindAddress = city + ", " + address
        
    }
    
    
}


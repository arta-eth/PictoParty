//
//  PhotoFinalTouchesViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-10-05.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper
import FirebaseStorage
import MapKit


class PhotoFinalTouchesViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var imageToPost: UIImageView!
    @IBOutlet weak var photoCaptionView: UITextView!
    var location: String! = nil
    var image: UIImage?
    var city: String! = nil
    var postLong: CLLocationDegrees! = nil
    var postLat: CLLocationDegrees! = nil

    var newDate: String! = nil
    
    func getAddress(lat: CLLocationDegrees, lon: CLLocationDegrees, gettingUserLocation: Bool, handler: @escaping (String) -> Void){
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                var placeMark: CLPlacemark?
                placeMark = placemarks?.first
                
                // Address dictionary
                // Location name
                // City
                
                if let city = placeMark?.locality {
                    
                    print(city)
                    handler(city)
                }
                /*
                if !gettingUserLocation{
                    if let country = placeMark?.country{
                        address += ", " + country
                    }
                }
 */
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appAppeared(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        self.photoCaptionView.resignFirstResponder()
        
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
            self.photoCaptionView.isUserInteractionEnabled = true
        }
    }
    
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            let bottomPadding = self.view.safeAreaInsets.bottom
            
            self.photoCaptionView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.animate(withDuration: 0.2, animations: {
                
                self.scrollView.contentInset.bottom -= keyboardHeight - bottomPadding
                self.scrollView.scrollIndicatorInsets.bottom -= keyboardHeight - bottomPadding
            })
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageToPost.image = image
        postButton.isEnabled = false
        photoCaptionView.delegate = self
        if let userLat = UserDefaults.standard.object(forKey: "userLAT") as? CLLocationDegrees{
            
            let userLong = UserDefaults.standard.object(forKey: "userLONG") as! CLLocationDegrees
            
            self.getAddress(lat: userLat, lon: userLong, gettingUserLocation: true, handler: { city in
                
                if city.isEmpty{
                    
                    return
                }
                else{
                    self.city = city
                    self.postLong = userLong
                    self.postLat = userLat
                    self.postButton.isEnabled = true
                    //print(self.city)
                }
            })
        }
    }
    
    
    @IBAction func postPicture(_ sender: UIButton) {
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "YYYY-MM-dd, a hh:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        
        let uploadDate = formatter.string(from: today)
        
        
        
        newDate = uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
        
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        
        let n = NSUUID().uuidString

        
        let data = [
            
            "Timestamp" : newDate ?? "",
            "City" : city ?? "",
            "LONG" : self.postLong ?? "",
            "LAT" : self.postLat ?? "",
            "Likes" : 0,
            "Caption" : photoCaptionView.text ?? "",
            "Picture" : n
            
            ] as [String : Any]

        
        let storageRef = Storage.storage().reference().child(uid!).child("Party-" + n + ".jpg")
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        if let uploadData = (image ?? UIImage(named: "WHITE")!).jpegData(compressionQuality: 0.8){
            storageRef.putData(uploadData, metadata: metaData, completion:{ (metaData, error) in
                if error != nil{
                    print(error?.localizedDescription ?? "no error")
                    return
                }else{
                    
                    if UserDefaults.standard.object(forKey: "POSTS") != nil{
                        UserDefaults.standard.removeObject(forKey: "POSTS")
                    }
                    
                    //if UserDefaults.standard.bool(forKey: "New_Post"){
                        //UserDefaults.standard.removeObject(forKey: "New_Post")
                    //}
                    Firestore.firestore().collection("Users").document(uid!).collection("Posts").addDocument(data: data, completion: { (error) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            self.performSegue(withIdentifier: "back2feed", sender: nil)
                        }
                    })
                }
            })
        }
    }

    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let mapVC = segue.destination as? MapViewController{
            
            
            mapVC.unwindCity = city
            mapVC.unwindTime = newDate
            mapVC.unwindLong = postLong
            mapVC.unwindLat = postLat
        }
    }
}

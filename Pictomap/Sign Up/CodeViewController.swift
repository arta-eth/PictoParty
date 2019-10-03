//
//  CodeViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-21.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SwiftKeychainWrapper
import FirebaseMessaging
import OneSignal

class CodeViewController: UIViewController {
    
    var phoneNumber = String()
    
    @IBOutlet weak var verification: UITextField!
    
    @IBOutlet weak var enter: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        verification.layer.cornerRadius = verification.frame.height / 2
        
        verification.borderStyle = .roundedRect
        
        
        enter.layer.borderWidth = 2.5
        enter.layer.borderColor = UIColor.black.cgColor
        
        enter.layer.cornerRadius = enter.frame.height / 2.0
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        verification.becomeFirstResponder()
        
    }
    
    @IBAction func enter(_ sender: Any) {
        
        let disableMyButton = sender as? UIButton
        disableMyButton?.isEnabled = false
        let verificationID = UserDefaults.standard.string(forKey: "VerificationID")
        let verificationField = verification.text
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID!,
            verificationCode: verificationField!)
        if KeychainWrapper.standard.string(forKey: "PHONE_NUM") == nil{
            
            Auth.auth().signIn(with: credential, completion: { (authResult, error) in
                
                
                if error != nil {
                    print("error")
                    disableMyButton?.isEnabled = true
                    return
                }
                else{
                    print("Saved UID")
                    let uid = Auth.auth().currentUser?.uid
                    KeychainWrapper.standard.set(uid!, forKey: "USER")
                    KeychainWrapper.standard.set(self.phoneNumber, forKey: "PHONE_NUM")
                    self.performSegue(withIdentifier: "toProfile", sender: nil)
                }
            })
        }
        
        else{
            
            Auth.auth().currentUser?.updatePhoneNumber(credential, completion: {(error) in
                
                if error != nil{
                    disableMyButton?.isEnabled = true
                    print(error?.localizedDescription ?? "")
                    return
                }
                
                else{
                    
                    //KeychainWrapper.standard.set(self.phoneNumber, forKey: "PHONE_NUM")
                    self.performSegue(withIdentifier: "Updated Phone Number", sender: nil)
                }
            })
            
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

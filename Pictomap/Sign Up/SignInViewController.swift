//
//  SignInViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-11-20.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SwiftKeychainWrapper

class SignInViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    @IBAction func signIn(_ sender: UIButton) {
        
        sender.isEnabled = false
       
        Firestore.firestore().collection("Users").whereField("Username", isEqualTo: usernameField.text ?? "").getDocuments(completion: { (querySnap, err) in
            
            if err != nil{
                print(err?.localizedDescription ?? "")
                sender.isEnabled = true

            }
            else{
                
                let email = querySnap?.documents.first?["Email"] as? String
                
                Auth.auth().signIn(withEmail: email ?? "", password: self.passwordField.text ?? "", completion: { (authResult, error) in
                    
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        sender.isEnabled = true

                    }
                    else{
                        sender.isEnabled = true
                        let uid = Auth.auth().currentUser?.uid
                        KeychainWrapper.standard.set(uid!, forKey: "USER")
                        self.performSegue(withIdentifier: "toProfile", sender: nil)
                    }
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

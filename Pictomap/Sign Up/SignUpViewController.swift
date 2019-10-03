//
//  SignUpViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-11-20.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SwiftKeychainWrapper

class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    @IBOutlet weak var createAccountBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
        // Do any additional setup after loading the view.
        emailField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPasswordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        createAccountBtn.isEnabled = false

    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if (!(emailField.text?.isEmpty ?? true)) && (passwordField.text?.count ?? 0) >= 8{
            
            createAccountBtn.isEnabled = true
            
        }
        else{
            createAccountBtn.isEnabled = false
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        
        emailField.becomeFirstResponder()
    }
    
    
    @IBAction func createAccount(_ sender: UIButton) {
        
        if confirmPasswordField.text == passwordField.text{
            sender.isEnabled = false
            Auth.auth().createUser(withEmail: emailField.text ?? "", password: passwordField.text ?? "", completion: { (authResult, error) in
                
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    sender.isEnabled = true
                    
                }
                else{
                    let uid = Auth.auth().currentUser?.uid
                    KeychainWrapper.standard.set(uid ?? "", forKey: "USER")
                    self.performSegue(withIdentifier: "toSetup", sender: nil)
                    sender.isEnabled = true
                    
                }
            })
        }
        else{
            //DO
        }
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

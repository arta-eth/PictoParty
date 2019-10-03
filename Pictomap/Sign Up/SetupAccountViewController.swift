//
//  SetupAccountViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-11-20.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper

class SetupAccountViewController: UIViewController {

    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    let uid = KeychainWrapper.standard.string(forKey: "USER")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func uploadUsernameAndSignIn(_ sender: UIButton) {
        
        if !((usernameField.text?.isEmpty ?? true)) && !((fullNameField.text?.isEmpty ?? true)){
            self.performSegue(withIdentifier: "retrieve", sender: nil)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let secondVC = segue.destination as? RetrieveUserFromLogInVC{
            secondVC.username = usernameField.text ?? nil
            secondVC.fullName = fullNameField.text ?? nil

        }
    }
    

}

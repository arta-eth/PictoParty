//
//  ViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-13.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import SwiftKeychainWrapper

class ViewController: UIViewController {
    
    //Check if user does exists
    @IBOutlet weak var getStarted: UIButton!
    
    var userLoaded: String = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        UserDefaults.standard.set(true, forKey: "New_Post")

        getStarted.layer.borderWidth = 2.5
        getStarted.layer.borderColor = UIColor.black.cgColor
        getStarted.layer.cornerRadius = getStarted.frame.height / 2.0
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        UserDefaults.standard.set(true, forKey: "hasRunBefore")

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    
    }
    
    
    @IBAction func SignUp(_ sender: UIButton) {
        
        let disableMyButton = sender as UIButton
        disableMyButton.isEnabled = false
        disableMyButton.isEnabled = true
        
    }
    
    @IBAction func unwindToViewController(segue:  UIStoryboardSegue) {
        
        print("Signed Out")
        do {
            try Auth.auth().signOut()
        }catch {}
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}

struct Screen {
    static var width: CGFloat {
        return UIScreen.main.bounds.width
    }
    static var height: CGFloat {
        return UIScreen.main.bounds.height
    }
    static var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
}

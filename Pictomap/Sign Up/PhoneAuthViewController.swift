//
//  PhoneAuthViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-21.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SwiftKeychainWrapper

struct Country: Decodable{
    
    let name: String
    let dial_code: String
    let code: String
    let flag: String
}


class PhoneAuthViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let countryDisplay = UIPickerView()
    @IBOutlet weak var sendCode: UIButton!
    @IBOutlet weak var codeDisplay: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var backToEdit: UIButton!
    
    var countries = [Country]()
    var code: String = ""
    var verificationid: String = ""
    var phoneNum  = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countryDisplay.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.7)

        sendCode.layer.cornerRadius = sendCode.frame.height / 2
        backToEdit.layer.cornerRadius = backToEdit.frame.height / 2
        codeDisplay.layer.borderWidth = 1.5
        codeDisplay.layer.borderColor = UIColor.black.cgColor
        codeDisplay.layer.cornerRadius = codeDisplay.frame.height / 5.5
        codeDisplay.borderStyle = .roundedRect
        phoneNumber.layer.borderWidth = 1.5
        phoneNumber.layer.borderColor = UIColor.black.cgColor
        phoneNumber.layer.cornerRadius = phoneNumber.frame.height / 9
        phoneNumber.borderStyle = .roundedRect
        self.navigationController?.isNavigationBarHidden = true
        codeDisplay.inputView = countryDisplay
        let locale = Locale.current
        print(locale.regionCode ?? "N/A")
        countryDisplay.delegate = self
        countryDisplay.dataSource = self
        let path = Bundle.main.path(forResource: "countries", ofType: "json")
        let url = URL(fileURLWithPath: path!)
        do {
            let data = try Data(contentsOf: url)
            self.countries = try JSONDecoder().decode([Country].self, from: data)
        }
        catch{}
        for currentCountry in countries{
            if(currentCountry.code == locale.regionCode){
                print(currentCountry.dial_code)
                codeDisplay.text = currentCountry.code + " " + currentCountry.dial_code + " " + currentCountry.flag
                code = currentCountry.dial_code
            }
        }
        DispatchQueue.main.async {
            self.countryDisplay.reloadComponent(0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if KeychainWrapper.standard.string(forKey: "PHONE_NUM")  == nil{
            phoneNumber.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let num = KeychainWrapper.standard.string(forKey: "PHONE_NUM"){
            let newString = num.replacingOccurrences(of: code, with: "", options: .literal, range: nil)
            phoneNumber.text = newString
        }
        else{
            backToEdit.isEnabled = false
            backToEdit.isUserInteractionEnabled = false
            backToEdit.isHidden = true
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        
        return countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return countries[row].flag + " " + countries[row].name + " " + countries[row].dial_code
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        codeDisplay.text = countries[row].code + " " + countries[row].dial_code + " " + countries[row].flag
        code = countries[row].dial_code
    }
    
    @IBAction func sendCode(_ sender: UIButton) {
        
        sender.isEnabled = false
        let phoneNumber = code + self.phoneNumber.text!
        phoneNum = phoneNumber.stripped
        Auth.auth().languageCode = "en";
        print(phoneNum)
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNum, uiDelegate: nil) { (verificationID, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                sender.isEnabled = true
                return
            }
            else{
                self.performSegue(withIdentifier: "toCode", sender: nil)
                UserDefaults.standard.set(verificationID, forKey: "VerificationID")
                print("SMS Sent")
                sender.isEnabled = true
            }
        }
    }
    
    @IBAction func unwindToViewController(segue:  UIStoryboardSegue) {
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Create a variable that you want to send
        let vc = segue.destination as? CodeViewController
        vc?.phoneNumber = phoneNum
    }
}







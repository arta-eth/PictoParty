//
//  NewEventViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-13.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import MapKit


class NewEventViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var dateTime: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var streetField: UITextField!
    @IBOutlet weak var map: MKMapView!
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    var selectedDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        map.layer.cornerRadius = map.frame.height / 3
        dateTime.layer.cornerRadius = dateTime.frame.height / 2
        cityField.layer.cornerRadius = cityField.frame.height / 2
        streetField.layer.cornerRadius = streetField.frame.height / 2
        continueBtn.layer.cornerRadius = continueBtn.frame.height / 2


        

        map.clipsToBounds = true
        cityField.delegate = self
        streetField.delegate = self
        
        // Create a DatePicker
        let datePicker: UIDatePicker = UIDatePicker()

        
        // Posiiton date picket within a view
        datePicker.frame = CGRect(x: 10, y: 50, width: self.view.frame.width, height: 200)
        
        // Set some of UIDatePicker properties
        datePicker.timeZone = NSTimeZone.local
        datePicker.backgroundColor = UIColor.white
        
        // Add an event to call onDidChangeDate function when value is changed.
        datePicker.addTarget(self, action: #selector(NewEventViewController.datePickerValueChanged(_:)), for: .valueChanged)
        
        dateTime.inputView = datePicker
        // Add DataPicker to the view
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        
        let today = formatter.string(from: date)
        
        print(today)

        dateTime.text = today
    
        // Do any additional setup after loading the view.
        
    }
    
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if cityField.text != "" && streetField.text != ""{
            
            let address = streetField.text! + ", " + cityField.text!
            
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(address) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                    else {
                        print("better location please")
                        // handle no location found
                        return
                        
                }
                let viewRegion = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
                self.map.setRegion(viewRegion, animated: true)
                // Use your location
            }

        }
    }
    

    
    @objc func datePickerValueChanged(_ sender: UIDatePicker){
        
        // Create date formatter
        let dateFormatter: DateFormatter = DateFormatter()
        
        // Set date format
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        // Apply date format
         dateTime.text = dateFormatter.string(from: sender.date)
        
        self.selectedDate = sender.date
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        UserDefaults.standard.removeObject(forKey: "CHOSE")
       
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

    @IBAction func lastStep(_ sender: Any) {
        

        self.performSegue(withIdentifier: "finalStep", sender: nil)
        
    }
    

    
    @IBAction func unwindEvent(segue: UIStoryboardSegue){
        
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        let navVC = segue.destination as? UINavigationController
        
        let newVC = navVC?.viewControllers.first as? EventDescriptionViewController
        newVC?.address = streetField.text!
        newVC?.city = cityField.text!


        newVC?.date = self.dateTime.text!
        
    }
    

   
}

//
//  MapViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-12.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import SwiftKeychainWrapper
import FirebaseStorage
import FirebaseFirestore
import FirebaseUI
import AudioToolbox
import AVFoundation



class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIScrollViewDelegate, UISearchBarDelegate, UISearchResultsUpdating{
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    @IBOutlet weak var callOutImage: UIImageView!
    
    
    @IBOutlet weak var directionMenu: UIStackView!
    
    let notificationCenter = NotificationCenter.default
    
    var unwindCity = String() //
    var unwindAddress = String() //
    
    @IBOutlet weak var map: MKMapView!
    private var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var photo = [PhotosFromFeed]()
    typealias DownloadComplete = () -> ()
    let speechSynth = AVSpeechSynthesizer()
    
    var annotationNode = String() //
    var uidRef = String() //
    var imageRef = String() //
    
    var reuseIdentifier = String()
    var tileRenderer: MKTileOverlayRenderer!
    var username = String()
    var count = 0
    
    var unwindTime = String() //
    var unwindLong = CLLocationDegrees() //
    var unwindLat = CLLocationDegrees() //
    let search = UISearchBar()
    
    @IBOutlet weak var startNavBtn: UIButton!
    
    var spinner: MapSpinnerView! = nil
    var mapSpinner: MapSpinnerView! = nil
    
    
    var pts: [PostAnnotation]! = nil
    var upts: [PostAnnotation]! = nil
    
    //var shimmerRenderer: ShimmerRenderer!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        search.delegate = self
        self.navigationItem.titleView = search
        
        directionViewBottom.constant = -(UserDefaults.standard.object(forKey: "barHeight") as? CGFloat ?? 0)
            
        self.map.userTrackingMode = .followWithHeading
        search.autocapitalizationType = .words
        search.prompt = ""
        search.returnKeyType = .go
        search.searchBarStyle = .minimal
        search.keyboardType = .alphabet
        search.tintColor = UIColor.white
        search.setText(color: UIColor.white)
        self.directionMenu.isHidden = true
        self.directionView.isHidden = true
        self.calloutView.isHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.view.backgroundColor = UIColor.black
        self.map.addSubview(searchScreen)
        searchScreen.isHidden = true
        searchScreen.alpha = 0.0
        self.search.keyboardAppearance = .dark
        self.callOutImage.layer.cornerRadius = 4
        self.startNavBtn.layer.cornerRadius = self.startNavBtn.frame.height / 4
        self.startNavBtn.clipsToBounds = true

        if #available(iOS 13.0, *) {
            self.callOutImage.layer.borderColor = UIColor.tertiaryLabel.cgColor
            self.callOutImage.backgroundColor = UIColor.secondarySystemBackground
        } else {
            self.callOutImage.layer.borderColor = UIColor.darkGray.cgColor
            self.callOutImage.backgroundColor = UIColor.lightGray
        }
        self.callOutImage.layer.borderWidth = 1.0
        self.callOutImage.clipsToBounds = true
    
        
        spinner = MapSpinnerView.init(frame: CGRect(x: 17.5, y: 17.5, width: 75, height: 75))
        
        mapSpinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        
        self.map.addSubview(mapSpinner)
        mapSpinner.isHidden = true
        spinner.alpha = 0.5
        
        
        if downloader == nil{
            
            self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
            //self.downloader = SDWebImageDownloader.init(sessionConfiguration: URLSessionConfiguration.background(withIdentifier: "MapPostsDownloader"))
        }
        
        UserDefaults.standard.set(self.tabBarController?.tabBar.frame.height, forKey: "barHeight")
        
        
        print(UIColor.red)
        
        map.roundCorners([UIRectCorner.topRight, UIRectCorner.topLeft], radius: self.view.frame.width / 20)
        
        
        print("load")
        switch UIScreen.main.scale{
        case 3.0:
            size = CGSize(width: 60, height: 60)
        case 2.0:
            size = CGSize(width: 40, height: 40)
        case 1.0:
            size = CGSize(width: 20, height: 20)
        default: break
        }
        
        loadUp()
    }
    var size = CGSize()
    
    
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    @IBAction func unwindToUserViewController(segue:  UIStoryboardSegue) {
        
        //self.rewinded = true
        let viewRegion = MKCoordinateRegion.init(center: CLLocationCoordinate2D(latitude: self.unwindLat, longitude: self.unwindLong), latitudinalMeters: 500, longitudinalMeters: 500)
        self.map.setRegion(viewRegion, animated: true)
        self.myPosts(city: self.unwindCity, country: "", newPost: true, newDate: self.unwindTime){
        }
    }
    @IBOutlet weak var calloutInfoArea: UIView!
    
    @IBOutlet weak var loadPicCalloutView: UIView!
    @IBOutlet weak var calloutView: UIView!
    
    override func viewDidLayoutSubviews() {
        
        
        self.calloutInfoArea.layer.cornerRadius = self.calloutInfoArea.frame.height / 16
        self.calloutInfoArea.clipsToBounds = true
        
        if !self.callOutImage.subviews.contains(spinner){
            self.callOutImage.addSubview(spinner)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        if UserInfo.dp != nil{
            
            for annotation in self.map.annotations{
                
                if let postAnnotation = annotation as? PostAnnotation{
                    if postAnnotation.publisherUID == KeychainWrapper.standard.string(forKey: "USER"){
                        postAnnotation.userImage = UserInfo.dp
                        if let postView = self.map.view(for: postAnnotation){
                            postView.image = self.addAnnotationImage(clustered: false, image: UserInfo.dp!)
                        }
                    }
                }
                else if let clusteredAnnotation = annotation as? MKClusterAnnotation{
                    for memberAnnotation in (clusteredAnnotation.memberAnnotations as? [PostAnnotation] ?? []){
                        
                        if memberAnnotation.publisherUID == KeychainWrapper.standard.string(forKey: "USER"){
                            memberAnnotation.userImage = UserInfo.dp
                            if let memberView = self.map.view(for: memberAnnotation){
                                memberView.image = self.addAnnotationImage(clustered: false, image: UserInfo.dp!)
                            }
                            
                            if !(((clusteredAnnotation.memberAnnotations as? [PostAnnotation])?.contains(where: {$0.likes > memberAnnotation.likes})) ?? false){
                                if let clusteredView = self.map.view(for: clusteredAnnotation){
                                    clusteredView.image = self.addAnnotationImage(clustered: true, image: UserInfo.dp!)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    lazy var searchScreen: UIView = {
        
        let load = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        
        load.backgroundColor = UIColor.black.withAlphaComponent(0.80)
        
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(resign))
        
        load.addGestureRecognizer(tapper)
        
        return load
    }()
    
    @IBAction func segueToPost(_ sender: UITapGestureRecognizer) {
        
        self.performSegue(withIdentifier: "full", sender: nil)
        
    }
    
    func loadUp(){
        
        //setupTileRenderer()
        map.delegate = self
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Check for Location Services
        locationManager.delegate = self
        if let userLat = UserDefaults.standard.object(forKey: "userLAT") as? CLLocationDegrees{
            let userLong = UserDefaults.standard.object(forKey: "userLONG") as! CLLocationDegrees
            let userLoc = CLLocationCoordinate2D(latitude: userLat, longitude: userLong)
            let region = MKCoordinateRegion.init(center: userLoc, latitudinalMeters: 5000, longitudinalMeters: 5000)
            self.map.setRegion(region, animated: false)
        }
        if let city = UserDefaults.standard.object(forKey: "currentCity") as? String{
            search.inputAccessoryView = UIView()
            search.placeholder = city
        }
        
        if !Reachability.isConnectedToNetwork(){
            self.view.showNoWifiLabel()
        }
        else{
            self.findLocation()
        }
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        search.placeholder = "Type in a place..."
        search.setShowsCancelButton(true, animated: true)
        
        searchScreen.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            
            self.searchScreen.alpha = 1.0
        }, completion: {(finished : Bool) in
        })
    }
    
    @objc func resign(){
        
        if search.isFirstResponder{
            search.endEditing(true)
            if let city = UserDefaults.standard.object(forKey: "currentCity") as? String{
                
                search.placeholder = city
            }
            UIView.animate(withDuration: 0.2, animations: {
                
                self.searchScreen.alpha = 0.0
            }, completion: {(finished : Bool) in
                self.searchScreen.isHidden = true
            })
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        var address = String()
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(searchBar.text ?? "null") { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
            }
            
            geoCoder.reverseGeocodeLocation(location, completionHandler: {
                placemarks, error in
                
                if error == nil{
                    
                    if let city = placemarks?.first?.locality{
                        address += city
                    }
                    if let province = placemarks?.first?.administrativeArea{
                        address += " - " + province
                    }
                    
                    let components = address.components(separatedBy: " - ")
                    
                    let final = components.filter({$0.count != 0})
                    if final.count == 1{
                        
                        self.search.placeholder = final.first
                    }
                    else{
                        
                        self.search.placeholder = address
                    }
                    
                    if let country = placemarks?.first?.country{
                        address += " - " + country
                    }
                    
                    self.map.removeAnnotations(self.map.annotations)
                    let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
                    self.map.setRegion(region, animated: true)
                    searchBar.endEditing(true)
                    self.search.text?.removeAll()
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        
                        self.searchScreen.alpha = 0.0
                    }, completion: {(finished : Bool) in
                        self.searchScreen.isHidden = true
                    })
                    self.refresh(address: address, annotation: nil)
                }
            })
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        search.setShowsCancelButton(false, animated: true)
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        search.resignFirstResponder()
        search.setShowsCancelButton(false, animated: true)
        if let city = UserDefaults.standard.object(forKey: "currentCity") as? String{
            
            search.placeholder = city
        }
        UIView.animate(withDuration: 0.2, animations: {
            
            self.searchScreen.alpha = 0.0
        }, completion: {(finished : Bool) in
            self.searchScreen.isHidden = true
        })
    }
    
    func findLocation(){
        
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func getAddress(lat: CLLocationDegrees, lon: CLLocationDegrees, isNavigating: Bool, handler: @escaping (String?, String?, String?) -> Void){
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            if error != nil{
                handler("", "", "")
            }
            else{
                var placeMark: CLPlacemark?
                placeMark = placemarks?[0]
                
                // Address dictionary
                // Location name
                // City
                
                if isNavigating{
                    let street = placeMark?.thoroughfare
                    handler(street, nil, nil)
                }
                else{
                    let city = placeMark?.locality
                    
                    let province = placemarks?.first?.administrativeArea
                    
                    let country = placemarks?.first?.country
                    // Passing address back
                    handler(city, province, country)
                }
            }
        })
    }
    
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        
        for k in views{
            k.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.15, animations: {
                k.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: { finished in
                
                
            })
        }
    }
    
    @IBOutlet weak var navTextView: UITextView!
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        switch UIScreen.main.scale{
        case 3.0:
            size = CGSize(width: 60, height: 60)
        case 2.0:
            size = CGSize(width: 50, height: 50)
        case 1.0:
            size = CGSize(width: 20, height: 20)
        default: break
        }
        
        if let clusteredAnnotation = annotation as? MKClusterAnnotation {
            
            if clusteredAnnotation.memberAnnotations is [PostAnnotation]{
                let identifier = "Clusters"
                var annotationV = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationV == nil {
                    annotationV = MKAnnotationView(annotation: clusteredAnnotation, reuseIdentifier: identifier)
                } else {
                    annotationV?.annotation = clusteredAnnotation
                }
                
                if let customed = (clusteredAnnotation.memberAnnotations as? [PostAnnotation])?.sorted(by: { $0.likes > $1.likes }){
                    
                    var image = UIImage()
                    
                    if customed.first?.userImage != nil{
                        image = (customed.first?.userImage)!
                        annotationV?.image = self.addAnnotationImage(clustered: true, image: image)
                        annotationV?.alpha = 1.0
                    }
                    else{
                        annotationV?.image = self.addAnnotationImage(clustered: true, image: UIImage(named: "loadingAnnotation")!)
                        annotationV?.alpha = 0.25
                    }
                    annotationV?.setRadiusWithShadow()
                }
                
                return annotationV
            }
            else{
                let identifier = "SpinClusters"
                var annotationV = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if annotationV == nil {
                    annotationV = MKAnnotationView(annotation: clusteredAnnotation, reuseIdentifier: identifier)
                } else {
                    annotationV?.annotation = clusteredAnnotation
                }
                
                return annotationV
            }
        }
        
        if let photoAnnotation = annotation as? PostAnnotation{
            self.reuseIdentifier = "pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.clusteringIdentifier = "clust"
            if photoAnnotation.userImage == nil{
                annotationView?.image = self.addAnnotationImage(clustered: false, image: UIImage(named: "loadingAnnotation")!)
                annotationView?.alpha = 0.25
            }
            else{
                annotationView?.image = self.addAnnotationImage(clustered: false, image: photoAnnotation.userImage!)
                annotationView?.collisionMode = .rectangle
                annotationView?.alpha = 1.0
            }
            annotationView?.setRadiusWithShadow()
            
            
            return annotationView
        }
        
        if annotation is SpinnerAnnotation{
            self.reuseIdentifier = "spin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.clusteringIdentifier = "spinner"
            
            annotationView?.collisionMode = .rectangle
            annotationView?.isUserInteractionEnabled = false
            
            if annotationView?.subviews.count == 0{
                let spin = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                spin.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
                spin.layer.cornerRadius = spin.frame.height / 2
                spin.clipsToBounds = true
                annotationView?.addSubview(spin)
            }
            
            return annotationView
        }
        
        return nil
    }
    
    
    
    
    @objc func selected(_ sender: UITapGestureRecognizer){
        
        if let n = sender.view as? MKAnnotationView{
            guard let annotation = n.annotation else {return}
            var region = map.region  // get the current region
            region.center = annotation.coordinate
            map.setRegion(region, animated: true)
        }
    }
    
    @IBAction func cancelDirections(_ sender: UIButton) {
        self.navigatingPost = nil
        self.startingCoord = nil
        self.directionMenu.isHidden = true
        self.directionView.isHidden = true
        

        for overlay in self.map.overlays{
            self.map.removeOverlay(overlay)
        }
        
        guard let post = selectedPost else{return}
             self.map.selectAnnotation(post, animated: true)
    }
    
    @IBOutlet weak var directionViewBottom: NSLayoutConstraint!
    
    
    @IBOutlet weak var directionView: UIView!
    
    @IBAction func startNavigation(_ sender: UIButton?) {
        self.directionView.isHidden = false
        
        if let coord = startingCoord{
            let region = MKCoordinateRegion.init(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
            self.map.setRegion(region, animated: true)

        }
        for i in 0..<self.directions.count{
            let step = self.routes[0].steps[i]
            let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
            self.locationManager.startMonitoring(for: region)
        }
        
        setDirections(index: 0)
    }
    
    var currentIndex = 0
    
    func setDirections(index: Int){
        
        if let displayDirection = self.directions[index]["Steps"] as? String{
            
            if let distance = self.directions[index]["Distance"] as? Double{
                
                var unit = String()
                var displayDistance = Double()
                
                if distance >= 1000.0{
                    
                    displayDistance = distance / 1000
                    unit = "km"
                }
                else{
                    displayDistance = distance
                    unit = "m"
                }
                let fullDirection = "In " + "\(displayDistance.rounded())" + " \(unit), " + displayDirection
                
                let speechDirection = fullDirection
                    .replacingOccurrences(of: "ON-", with: "Highway ")
                    .replacingOccurrences(of: " W", with: " West")
                    .replacingOccurrences(of: " N", with: " North")
                    .replacingOccurrences(of: " S", with: " South")
                    .replacingOccurrences(of: " E", with: " East")
                print(speechDirection)
                
                self.navTextView.text = fullDirection
                let speech = AVSpeechUtterance(string: speechDirection)
                self.speechSynth.speak(speech)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.currentStep += 1
        
        if currentStep < directions.count{
            self.navTextView.text = "Turn"
            let speech = AVSpeechUtterance(string: "Done")
            self.speechSynth.speak(speech)
            //self.setDirections(index: self.currentStep)
        }else{
            self.navTextView.text = "Done"
            locationManager.monitoredRegions.forEach({ locationManager.stopMonitoring(for: $0)})
        }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        guard let userLoc = currentLocation?.coordinate else {return}
        self.getAddress(lat: userLoc.latitude, lon: userLoc.longitude, isNavigating: true, handler: { (street, unused, unused2) in
            if let street2Check = street{
                if self.currentStep == 0{
                    return
                }
                let index = self.currentStep - 1
                if let step = self.directions[index]["Steps"] as? String{
                    print(step)
                    print(street)
                    if step.hasSuffix(street2Check){
                        self.setDirections(index: self.currentStep)
                    }
                    else{
                        self.navTextView.text = "Recalculating"
                        let speech = AVSpeechUtterance(string: "Recalculating")
                        self.speechSynth.speak(speech)
                        self.getDirections(nil)
                    }
                }
            }
        })
    }
    
    var currentStep = 0
    var directions = [[String : Any]]()
    var startingCoord: CLLocationCoordinate2D? = nil
    
    @IBAction func getDirections(_ sender: UIButton?) {
        
        guard let fromCoord = currentLocation?.coordinate else{return}
        self.startingCoord = fromCoord

        for overlay in self.map.overlays{
            self.map.removeOverlay(overlay)
        }
        
        guard let toCoord = selectedPost?.coordinate else{return}
        
        self.directionMenu.isHidden = false
        self.navigatingPost = selectedPost
        self.map.deselectAnnotation(selectedPost, animated: false)
        
        self.calloutView.isHidden = true
        let to = MKMapItem(placemark: MKPlacemark(coordinate: toCoord))
        let from = MKMapItem(placemark: MKPlacemark(coordinate: fromCoord))
            
        let request = MKDirections.Request()
        request.source = from
        request.destination = to
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            self.displayRoute(index: 0, routes: unwrappedResponse.routes)
        }
    }
    
    func displayRoute(index: Int, routes: [MKRoute]){
        
        self.directions.removeAll()
        self.routes.removeAll()
        self.locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
        
        for route in routes {
            self.routes.append(route)
        }
        let displayRoute = self.routes[index]
        self.map.addOverlay(displayRoute.polyline)
        self.map.setVisibleMapRect(displayRoute.polyline.boundingMapRect, animated: true)
        
        for step in displayRoute.steps {
            print(step.instructions)
            print(step.distance.magnitude)
            let direction = [
                "Steps" : step.instructions,
                "Distance" : step.distance.magnitude
            ] as [String:Any]
            
            if step.distance.magnitude == 0.0{
                continue
            }
            self.directions.append(direction)
        }
        if !self.directionView.isHidden{
            self.startNavigation(nil)
        }
    }
    
    
    @IBAction func reloadPosts(_ sender: UILongPressGestureRecognizer) {
        
        
        if sender.state == .began{
            
            let touchLocation = sender.location(in: map)
            
            let spinLoc = CGPoint(x: touchLocation.x - 25, y: touchLocation.y - 25)
            let labelLoc = CGPoint(x: touchLocation.x, y: touchLocation.y + 85)
            
            
            let labelCoordinate = map.convert(labelLoc, toCoordinateFrom: map)
            let spinCoordinate = map.convert(spinLoc, toCoordinateFrom: map)
            
            let id = NSUUID().uuidString
            
            let spinner = SpinnerAnnotation(initialSize: size.width, finalSize: size.height, id: id, city: nil, country: nil)
            spinner.coordinate = spinCoordinate
            print(spinCoordinate)
            
            self.map.addAnnotation(spinner)
            
            let queue = DispatchQueue(label: "refresh")
            queue.asyncAfter(deadline: .now() + 0.15, execute: {
                AudioServicesPlaySystemSound(1520)
            })
            if !Reachability.isConnectedToNetwork(){
                self.view.showNoWifiLabel()
            }
            getAddress(lat: labelCoordinate.latitude, lon: labelCoordinate.longitude, isNavigating: false, handler: { (city, province, country) in
                
                for spin in self.map.annotations.filter({$0.isKind(of: SpinnerAnnotation.self)}){
                    if let an = spin as? SpinnerAnnotation{
                        
                        if an.city != nil && an.country != nil{
                            
                            if an.city == city && an.country == country && id != an.id{
                                
                                let annView = self.map.view(for: an)
                                UIView.animate(withDuration: 0.5, animations: {
                                    annView?.alpha = 0.0
                                }, completion: {(finished : Bool) in
                                    if(finished){
                                        annView?.alpha = 1.0
                                        
                                        self.map.removeAnnotation(an)
                                    }
                                })
                            }
                        }
                        else{
                            self.getAddress(lat: an.coordinate.latitude, lon: an.coordinate.longitude, isNavigating: false, handler: { (city2, province2, country2) in
                                if country == country2 && city == city2 && id != an.id{
                                    
                                    let annView = self.map.view(for: an)
                                    UIView.animate(withDuration: 0.5, animations: {
                                        annView?.alpha = 0.0
                                    }, completion: {(finished : Bool) in
                                        if(finished){
                                            annView?.alpha = 1.0
                                            
                                            self.map.removeAnnotation(an)
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
                
                if country == ""{
                    print("no addy")
                    let annView = self.map.view(for: spinner)
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        annView?.alpha = 0.0
                    }, completion: {(finished : Bool) in
                        if(finished){
                            annView?.alpha = 1.0
                            
                            self.map.removeAnnotation(spinner)
                        }
                    })
                }
                else{
                    self.downloader.cancelAllDownloads()
                    spinner.city = city
                    spinner.country = country
                    print(city)
                    
                    DispatchQueue.main.async {
                        
                        
                        let labe = UILabel()
                        labe.textColor = UIColor.black
                        labe.text = city
                        let labeSize = labe.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20))
                        labe.frame = CGRect.init(x: labelLoc.x - labeSize.width / 2, y: labelLoc.y - labeSize.height / 2, width: labeSize.width, height: labeSize.height)
                        labe.translatesAutoresizingMaskIntoConstraints = false
                        var view: UIView? = UIView.init(frame: CGRect(x: labe.frame.minX - 10, y: labe.frame.minY - 10, width: labe.frame.width + 20, height: labe.frame.height + 20))
                        view?.backgroundColor = UIColor.white.withAlphaComponent(0.95)
                        view?.alpha = 0.9
                        view?.addSubview(labe)
                        labe.centerXAnchor.constraint(equalTo: (view?.centerXAnchor)!).isActive = true
                        labe.centerYAnchor.constraint(equalTo: (view?.centerYAnchor)!).isActive = true
                        labe.leadingAnchor.constraint(equalTo: (view?.leadingAnchor)!, constant: 10).isActive = true
                        labe.trailingAnchor.constraint(equalTo: (view?.trailingAnchor)!, constant: -10).isActive = true
                        labe.topAnchor.constraint(equalTo: (view?.topAnchor)!, constant: 10).isActive = true
                        labe.bottomAnchor.constraint(equalTo: (view?.bottomAnchor)!, constant: -10).isActive = true
                        view?.layer.cornerRadius = (view?.frame.height)! / 2
                        view?.clipsToBounds = true
                        self.view.addSubview(view!)
                        UIView.animate(withDuration: 0.6, animations: {
                            view?.transform = CGAffineTransform(translationX: 0, y: -60).scaledBy(x: 1.2, y: 1.2)
                        }, completion: {(finished : Bool) in
                            UIView.animate(withDuration: 0.25, animations: {
                                view?.alpha = 0.0
                            }, completion: {(finished : Bool) in
                                view?.removeFromSuperview()
                                view = nil
                            })
                        })
                    }
                    
                    guard let city2Check = city else{return}
                    guard let country2Check = country else{return}
                    guard let province2Check = province else{return}
                    
                    let address = city2Check + " - " + province2Check + " - " + country2Check
                    
                    var newArr = self.map.annotations
                    newArr.removeAll(where: {$0.isKind(of: SpinnerAnnotation.self)})
                    
                    var contains = Bool()
                    for arr in newArr{
                        
                        if let cluster = arr as? MKClusterAnnotation{
                            if let memb = cluster.memberAnnotations as? [PostAnnotation]{
                                if memb.contains(where: {$0.city == city && $0.country == country}){
                                    contains = true
                                    
                                    break
                                }
                            }
                        }
                        else if let post = arr as? PostAnnotation{
                            if post.city == city && post.country == country{
                                contains = true
                                
                                break
                            }
                        }
                    }
                    if contains{
                        
                        
                        
                        let annots = self.map.annotations.filter({$0.isKind(of: PostAnnotation.self) || $0.isKind(of: MKClusterAnnotation.self)})
                        
                        var counter: Int! = annots.count
                        
                        for arr in annots{
                            let annView = self.map.view(for: arr)
                            if let clust = arr as? MKClusterAnnotation{
                                
                                if let k = clust.memberAnnotations as? [PostAnnotation]{
                                    if let g = k.first{
                                        if g.city == city{
                                            print("Clust")
                                            UIView.animate(withDuration: 0.5, animations: {
                                                annView?.alpha = 0.0
                                            }, completion: {(finished : Bool) in
                                                if(finished){
                                                    annView?.alpha = 1.0
                                                    counter -= 1
                                                    if counter == 0{
                                                        
                                                        counter = nil
                                                        for annot in annots{
                                                            self.map.removeAnnotation(annot)
                                                        }
                                                        
                                                        self.refresh(address: address, annotation: spinner)
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                            else if let k = arr as? PostAnnotation{
                                
                                if k.city == city{
                                    print("No Clust")
                                    UIView.animate(withDuration: 0.5, animations: {
                                        annView?.alpha = 0.0
                                    }, completion: {(finished : Bool) in
                                        if(finished){
                                            annView?.alpha = 1.0
                                            counter -= 1
                                            if counter == 0{
                                                
                                                counter = nil
                                                for annot in annots{
                                                    self.map.removeAnnotation(annot)
                                                }
                                                
                                                self.refresh(address: address, annotation: spinner)
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    }
                    else{
                        
                        self.refresh(address: address, annotation: spinner)
                    }
                }
            })
        }
    }
  
    
    func photoDetailsSegue(){
        self.performSegue(withIdentifier: "full", sender: nil)
    }
    
    
    func addAnnotation(postLong: CLLocationDegrees, postLat: CLLocationDegrees, nodeName: String, uid: String, likes: Int, city: String, postID: String, country: String, timeStamp: String, link: String?, displayDate: String, info: String?){
        
        
        if (self.map.annotations as? [PostAnnotation])?.contains(where: {$0.nodeName == nodeName}) ?? false{
            return
        }
        else if !((self.map.annotations as? [PostAnnotation])?.contains(where: {$0.postID == postID}) ?? false){
            
            let ambiguousTime = time(time: timeStamp)
            
            let annotation = PostAnnotation(link: nil, nodename: nodeName, publisherUID: uid, image: nil, likes: likes, city: city, postID: postID, country: country, timeStamp: timeStamp, convertedTime: nil, partyPicLink: link, fullName: nil, username: nil, userImage: nil, displayDate: displayDate, convertedDate: nil, otherInfo: info, active: nil, ambiguousTime: ambiguousTime)
            
            
            print(timeStamp)
            
            let load = loadDate(ambiguous: true)
            let current = currentDate()
            
            
            if ambiguousTime <= current && ambiguousTime >= load{
                
                annotation.active = true
            }
            else{
                annotation.active = false
            }
            
            let components = annotation.displayDate.components(separatedBy: ", ")
            var time = components[1]
            let origDate = components[0]
            
            if time.first == "0"{
                time.removeFirst()
            }
            
            annotation.convertedTime = time
            annotation.convertedDate = origDate
            
            
            annotation.coordinate = CLLocationCoordinate2D(latitude: postLat, longitude: postLong)
            
            self.map.addAnnotation(annotation)
            
            switch annotation.publisherUID{
            case KeychainWrapper.standard.string(forKey: "USER"):
                annotation.userImage = UserInfo.dp
                self.updatePostImage(image: annotation.userImage, url: nil, postID: postID, annotation: annotation)
            default:
                if let sameUser = (self.map.annotations as? [PostAnnotation])?.first(where: {$0.publisherUID == uid}){
                    annotation.userImage = sameUser.userImage
                    annotation.link = sameUser.link
                    if annotation.userImage != nil{
                        self.updatePostImage(image: annotation.userImage, url: URL(string: annotation.link ?? "nil"), postID: postID, annotation: annotation)
                    }
                    else{
                        self.downloadImageIfFirstPost(uid: uid, annotation: annotation, postID: postID)
                    }
                }
                else{
                    self.downloadImageIfFirstPost(uid: uid, annotation: annotation, postID: postID)
                }
            }
        }
    }
    
    var downloader: SDWebImageDownloader! = nil
    
    
    func downloadImageIfFirstPost(uid: String, annotation: PostAnnotation, postID: String){
        
        for anno in self.map.annotations{
            if let clusteredAnnotation = anno as? MKClusterAnnotation{
                if let postAnnotation = (clusteredAnnotation.memberAnnotations as? [PostAnnotation])?.first(where: {$0.publisherUID == uid}){
                    
                    annotation.userImage = postAnnotation.userImage
                    annotation.link = postAnnotation.link
                    break
                }
            }
            else if let postAnnotation = anno as? PostAnnotation{
                if postAnnotation.publisherUID == uid{
                    
                    annotation.userImage = postAnnotation.userImage
                    annotation.link = postAnnotation.link
                    break
                }
            }
        }
        
        if annotation.userImage != nil{
            self.updatePostImage(image: annotation.userImage, url: URL(string: annotation.link ?? "nil"), postID: postID, annotation: annotation)
        }
        else{
            
            Firestore.firestore().collection("Users").document(uid).getDocument(completion: { (snap, err) in
                
                if !(snap?.exists ?? false){
                    self.map.removeAnnotations([annotation])
                }
                else{
                    if let pictureID = snap?["ProfilePictureUID"] as? String{
                        
                        let ref = Storage.storage().reference()
                        
                        ref.child(uid + "/" + "profile_pic-" + pictureID + ".png").downloadURL(completion: { url, error in
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                self.downloader.downloadImage(with: url, options: .scaleDownLargeImages, progress: nil, completed: { (image, data, error, finished) in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                        return
                                    }
                                    else{
                                        self.updatePostImage(image: image, url: url, postID: postID, annotation: annotation)
                                    }
                                })
                            }
                        })
                    }
                }
            })
        }
    }
    
    func updatePostImage(image: UIImage?, url: URL?, postID:  String, annotation: PostAnnotation){
        
        for anno in self.map.annotations{
            if let clusteredAnnotation = anno as? MKClusterAnnotation{
                if let postAnnotation = (clusteredAnnotation.memberAnnotations as? [PostAnnotation])?.first(where: {$0.postID == postID}){
                    postAnnotation.userImage = image
                    postAnnotation.link = url?.absoluteString
                    let view = self.map.view(for: postAnnotation)
                    view?.image = self.addAnnotationImage(clustered: false, image: image!)
                    view?.alpha = 1.0
                    
                    if !((clusteredAnnotation.memberAnnotations as? [PostAnnotation])?.contains(where: {$0.likes > annotation.likes}) ?? true){
                        let view = self.map.view(for: clusteredAnnotation)
                        view?.image = self.addAnnotationImage(clustered: true, image: image!)
                        view?.alpha = 1.0
                    }
                }
            }
            else if let postAnnotation = anno as? PostAnnotation{
                if postAnnotation.postID == postID{
                    postAnnotation.userImage = image
                    postAnnotation.link = url?.absoluteString
                    let view = self.map.view(for: postAnnotation)
                    view?.image = self.addAnnotationImage(clustered: false, image: image!)
                    view?.alpha = 1.0
                }
            }
        }
        
    }
    
    
    func addAnnotationImage(clustered: Bool, image: UIImage) -> UIImage{
        
        switch clustered{
            
        case true:
            let newImage = image.circleImage(2.0, size: CGSize(width: self.size.width * 1.5, height: self.size.height * 1.5), color: UIColor.white, width: 0)
            return newImage!
            
        case false:
            
            let newImage = image.circleImage(2.0, size: self.size, color: UIColor.white, width: 0)
            return newImage!
        }
    }
    
    @objc func refresh(address: String, annotation: SpinnerAnnotation?){
        
        
        if Reachability.isConnectedToNetwork(){
            
            if annotation != nil{
                
                let annView = self.map.view(for: annotation!)
                
                UIView.animate(withDuration: 0.5, animations: {
                    annView?.alpha = 0.0
                }, completion: {(finished : Bool) in
                    if(finished){
                        annView?.alpha = 1.0
                        
                        self.map.removeAnnotation(annotation!)
                    }
                })
            }
            
            print("Internet Connection Available!")
            
            let locationComponents = address.components(separatedBy: " - ")
            
            let city = locationComponents[0]
            let country = locationComponents[2]
            
            print(city)
            print(country)
            
            
            self.loadFriendPosts(city: city, country: country){
            }
            self.myPosts(city: city, country: country, newPost: false, newDate: nil){
            }
        }
            
        else{
            
            print("Internet Connection not Available!")
            if annotation != nil{
                
                let annView = self.map.view(for: annotation!)
                
                UIView.animate(withDuration: 0.5, animations: {
                    annView?.alpha = 0.0
                }, completion: {(finished : Bool) in
                    if(finished){
                        annView?.alpha = 1.0
                        self.map.removeAnnotation(annotation!)
                    }
                })
            }
            self.view.showNoWifiLabel()
        }
    }
    @IBAction func refreshLocation(_ sender: UIButton) {
        
        self.downloader.cancelAllDownloads()
        findLocation()
    }
    
    
    
    
    func setupTileRenderer() {
        // 1
        let template = "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png"
        
        // 2
        let overlay = MKTileOverlay(urlTemplate: template)
        
        // 3
        overlay.canReplaceMapContent = true
        
        // 4
        map.addOverlay(overlay, level: .aboveLabels)
        
        //5
        tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)
    }
    
    
    @objc func appMovedToForeground() {
        print("App moved to foreground!")
        self.spinner.removeFromSuperview()
        
        if !self.callOutImage.subviews.contains(spinner){
            
            spinner = MapSpinnerView(frame: CGRect(x: 17.5, y: 17.5, width: 75, height: 75))
            self.callOutImage.addSubview(spinner)
            
            switch self.callOutImage.image{
            case nil:
                self.spinner.isHidden = false
                
            default:
                self.spinner.isHidden = true
            }
        }
        findLocation()
    }
    
    // MARK - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        defer { currentLocation = locations.last }
        if currentLocation == nil {
            // Zoom to user location
            if let userLocation = locations.last {
                currentLocation = userLocation
                getAddress(lat: (userLocation.coordinate.latitude), lon: (userLocation.coordinate.longitude), isNavigating: false) { (city, province, country) in
                    if country == ""{
                    }
                    else{
                        self.map.removeAnnotations(self.map.annotations)
                        let region = MKCoordinateRegion.init(center: userLocation.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
                        
                        guard let city2Check = city else{return}
                        guard let country2Check = country else{return}
                        guard let province2Check = province else{return}

                        self.map.setRegion(region, animated: true)
                        UserDefaults.standard.set(userLocation.coordinate.latitude, forKey: "userLAT")
                        UserDefaults.standard.set(userLocation.coordinate.longitude, forKey: "userLONG")
                        let address2Set = (city ?? "") +  " - " + (province ?? "")
                        UserDefaults.standard.set(address2Set, forKey: "currentCity")
                        self.search.placeholder = address2Set
                        self.removeSpinner()
                        let address = city2Check +  " - " + province2Check + " - " + country2Check
                        self.refresh(address: address, annotation: nil)
                    }
                }
            }
        }
        else{
            if UserDefaults.standard.bool(forKey: "DP_CHANGE"){
                UserDefaults.standard.set(false, forKey: "DP_CHANGE")
            }
            else{
                //SET REGION BASED ON COORDINATE
            }
        }
    }
    
    func removeSpinner(){
        
        if let tab = self.tabBarController as? TabBarVC{
            UIView.animate(withDuration: 0.5, animations: {
                tab.spinner?.alpha = 0.0
            }, completion: {(finished : Bool) in
                if finished{
                    tab.spinner?.isHidden = true
                }
            })
        }
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        
        let newHeight = image.size.height * scale
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       let renderer = MKPolylineRenderer(overlay: overlay)
        if #available(iOS 13.0, *) {
            renderer.strokeColor = UIColor.link
        } else {
            renderer.strokeColor = UIColor.blue.withAlphaComponent(0.85)

        }
            
            
        renderer.lineWidth = 7.5
        return renderer
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
        
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        //findLocation()
    }
    
    @IBAction func rewindPost(segue: UIStoryboardSegue){
        
        print("g")
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        notificationCenter.removeObserver(self)
        
    }
    
    var selectedPost: PostAnnotation? = nil
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {

    }
    
    var navigatingPost: PostAnnotation? = nil
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if animated{
            if selectedPost != nil{
                switch navigatingPost{
                case .some(_):
                    if navigatingPost == selectedPost{
                        self.calloutView.isHidden = true
                    }
                    else{
                        fallthrough
                    }
                case nil:
                    self.calloutView.isHidden = false
                    self.calloutView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                    let view = self.map.view(for: selectedPost!)
                    UIView.animate(withDuration: 0.15, animations: {
                        self.calloutView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0).translatedBy(x: 0, y: (self.calloutView.frame.height - (view?.frame.height ?? 0) - 45))
                        }, completion: {(finished : Bool) in
                    })
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        if animated{
            
            
        }
        else{
            calloutView.isHidden = true
            
            if navigatingPost == selectedPost{
                
            }
            else{
                self.map.deselectAnnotation(selectedPost, animated: true)
                self.selectedPost = nil
            }
        }
    }
    
    @IBOutlet weak var fullNameCallout: UILabel!
    @IBOutlet weak var usernameCallout: UILabel!
    
    @IBOutlet weak var infoStack: UIStackView!
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let selectedAnnotation = view.annotation
        
        if let photoAnnotation = selectedAnnotation as? PostAnnotation{
            //  print(photoAnnotation.name!)
    
            self.calloutView.isHidden = true
            activity.startAnimating()
            self.usernameCallout.text?.removeAll()
            self.fullNameCallout.text?.removeAll()
            self.usernameCallout.isHidden = true
            self.fullNameCallout.isHidden = true
            self.infoStack.isHidden = true
            self.spinner.isHidden = false
            self.callOutImage.image = nil
            self.selectedPost = photoAnnotation
            
            switch selectedPost?.publisherUID{
                
            case KeychainWrapper.standard.string(forKey: "USER"):
                
                let username = KeychainWrapper.standard.string(forKey: "USERNAME")
                let fullName = KeychainWrapper.standard.string(forKey: "FULL_NAME")
                self.usernameCallout.text = "@" + (username ?? "null")
                self.fullNameCallout.text = fullName ?? "null"
                photoAnnotation.username = username
                selectedPost?.username = username
                photoAnnotation.fullName = fullName
                selectedPost?.fullName = fullName
                
                
                
                if username == nil || username == ""{
                    fallthrough
                }
                if fullName == nil || fullName == ""{
                    fallthrough
                }
                
                self.activity.stopAnimating()
                self.usernameCallout.isHidden = false
                self.fullNameCallout.isHidden = false
                self.infoStack.isHidden = false
                
                
            default:
                Firestore.firestore().collection("Users").document(photoAnnotation.publisherUID).getDocument(completion: {(snapshot, err) in
                    if err != nil{
                        self.activity.stopAnimating()
                        return
                    }
                    else{
                        let username = snapshot?["Username"] as? String
                        let fullname = snapshot?["Full Name"] as? String
                        // KeychainWrapper.standard.set(username ?? "", forKey: "USERNAME")
                        //KeychainWrapper.standard.set(fullname ?? "", forKey: "FULL_NAME")
                        self.usernameCallout.text = "@" + (username ?? "null")
                        self.fullNameCallout.text = fullname
                        photoAnnotation.username = username
                        self.selectedPost?.username = username
                        photoAnnotation.fullName = fullname
                        self.selectedPost?.fullName = fullname
                        self.activity.stopAnimating()
                        self.usernameCallout.isHidden = false
                        self.fullNameCallout.isHidden = false
                        self.infoStack.isHidden = false
                    }
                })
            }
            
            let ref = Storage.storage().reference()
            let uid = self.selectedPost?.publisherUID
            let link = self.selectedPost?.partyPicLink
            let loc = (uid ?? "null") + "/" + "Party-"
            let final = loc + (link ?? "null") + ".jpg"
            ref.child(final).downloadURL(completion: { url, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    self.downloader.downloadImage(with: url, options: .scaleDownLargeImages, progress: nil, completed: { (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            return
                        }
                        else{
                            self.callOutImage.alpha = 0.0
                            self.callOutImage.image = image
                            self.selectedPost?.image = image
                            photoAnnotation.image = image
                            
                            self.spinner.isHidden = true
                            UIView.animate(withDuration: 0.1, animations: {
                                self.callOutImage.alpha = 1.0
                            })
                        }
                    })
                }
            })
            
            let region = MKCoordinateRegion.init(center: photoAnnotation.coordinate, latitudinalMeters: 50, longitudinalMeters: 50)
            self.map.setRegion(region, animated: true)
            //photoDetailsSegue()
        }
            
        else if let clusteredPosts = selectedAnnotation as? MKClusterAnnotation{
            
            pts = [PostAnnotation]()
            if let memb = (clusteredPosts.memberAnnotations as? [PostAnnotation])?.sorted(by: { $0.likes > $1.likes }){
                pts.removeAll()
                for memberPhoto in memb{
                    pts.append(memberPhoto)
                    if pts.count == memb.count{
                        
                        self.performSegue(withIdentifier: "AreaPosts", sender: nil)
                    }
                }
            }
        }
    }
    
    func myPosts(city: String, country: String, newPost: Bool, newDate: String?, completed: @escaping DownloadComplete){
        
        let uid = KeychainWrapper.standard.string(forKey: "USER")
        var postCount: Int! = 0
        let searchDate = loadDate(ambiguous: false)
        
        var query: Query! = nil
        
        if newPost{
            query = Firestore.firestore().collection("Users").document(uid!).collection("Posts").whereField("Timestamp", isEqualTo: newDate ?? "")
        }
        else{
            query = Firestore.firestore().collection("Users").document(uid!).collection("Posts").whereField("Timestamp", isGreaterThanOrEqualTo: searchDate).whereField("City", isEqualTo: city).whereField("Country", isEqualTo: country)
        }
        
        query.getDocuments(completion: { (querySnapshot, err) in
            
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                guard let snap = querySnapshot else {return}
                for document in snap.documents {
                    
                    postCount += 1
                    guard let city = document["City"] as? String else{return}
                    guard let country = document["Country"] as? String else{return}
                    let link = document["Picture"] as? String
                    let likes = document["Likes"] as? Int
                    guard let long = document["LONG"] as? CLLocationDegrees else{return}
                    guard let lat = document["LAT"] as? CLLocationDegrees else{return}
                    guard let date = document["Timestamp"] as? String else{return}
                    guard let displayDate = document["DisplayTime"] as? String else{return}
                    let info = document["OtherInfo"] as? String
                    
                    self.addAnnotation(postLong: long, postLat: lat, nodeName: document.documentID, uid: uid!, likes: likes ?? 0, city: city, postID: document.documentID, country: country, timeStamp: date, link: link, displayDate: displayDate, info: info)
                    
                    if(postCount == snap.documents.count){
                        postCount = nil
                        completed()
                    }
                }
            }
        })
    }
    
    /*
     func tempUpdateTimes(id: String, uid: String, dateTime: String){
     let oldTimestamp = dateTime
     print(oldTimestamp)
     let components = oldTimestamp.components(separatedBy: ", ")
     let time = components[1]
     let origDate = components[0]
     let timeComponents = time.components(separatedBy: " ")
     let meridiem = timeComponents[0]
     let timeOfDay = timeComponents[1]
     let dateToConvert = timeOfDay + " " + meridiem
     let datet = (origDate) + ", " + (dateToConvert)
     let r = UTCToLocal(date: datet, fromFormat: "yyyy-MM-dd, hh:mm:ss a", toFormat: "yyyy-MM-dd, hh:mm a")
     print(r)
     Firestore.firestore().collection("Users").document(uid).collection("Posts").document(id).updateData(["DisplayTime":"\(r)"], completion: { error in
     })
     
     }
     
     
     func UTCToLocal(date:String, fromFormat: String, toFormat: String) -> String {
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = fromFormat
     dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
     
     let dt = dateFormatter.date(from: date)
     
     
     dateFormatter.timeZone = TimeZone(secondsFromGMT: 7200)
     
     dateFormatter.dateFormat = toFormat
     
     return dateFormatter.string(from: dt!)
     }
     */
    
    
    var loadingPosts = Bool()
    
    func loadFriendPosts(city: String, country: String, completed: @escaping DownloadComplete){
        
        let searchDate = loadDate(ambiguous: false)
        
        var documentCounter: Int! = 0
        
        
        let myFollowing = UserFollowing.userFollowing
        for followingUID in myFollowing{
            
            Firestore.firestore().collection("Users").document(followingUID).collection("Posts").whereField("Timestamp", isGreaterThanOrEqualTo: searchDate).whereField("City", isEqualTo: city).whereField("Country", isEqualTo: country).getDocuments(completion: { (querySnapshot, err) in
                
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let snap = querySnapshot else {return}
                    for document in snap.documents {
                        
                        documentCounter += 1
                        guard let city = document["City"] as? String else{return}
                        guard let country = document["Country"] as? String else{return}
                        let link = document["Picture"] as? String
                        let likes = document["Likes"] as? Int
                        guard let long = document["LONG"] as? CLLocationDegrees else{return}
                        guard let lat = document["LAT"] as? CLLocationDegrees else{return}
                        guard let date = document["Timestamp"] as? String else{return}
                        guard let displayDate = document["DisplayTime"] as? String else{return}
                        let info = document["OtherInfo"] as? String
                        
                        self.addAnnotation(postLong: long, postLat: lat, nodeName: document.documentID, uid: document.documentID, likes: likes ?? 0, city: city, postID: document.documentID, country: country, timeStamp: date, link: link, displayDate: displayDate, info: info)
                        
                        if(documentCounter == snap.documents.count){
                            documentCounter = nil
                            completed()
                        }
                    }
                }
            })
        }
    }
    
    var routes: [MKRoute] = [MKRoute]()
    
    
    
    @IBAction func unwindToMap(segue:  UIStoryboardSegue) {
        
        if let annot = map.selectedAnnotations.first{
            //Fix crash with following line
            let viewRegion = MKCoordinateRegion.init(center: annot.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
            map.setRegion(viewRegion, animated: false)
            map.deselectAnnotation(annot, animated: true)

        }
        if self.pts != nil{
            
            for a in self.pts{
                
                if !self.upts.contains(a){
                    self.map.removeAnnotation(a)
                }
            }
            self.pts = nil
            self.upts = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let navVC = segue.destination as? UINavigationController{
            
            if let fullVC = navVC.viewControllers.first as? FullPostViewController{
                
                guard let userImage = selectedPost?.userImage else {return}
                guard let image = selectedPost?.image else {return}
                
                let userImageData = userImage.jpegData(compressionQuality: 0.8)
                let postImageData = image.jpegData(compressionQuality: 0.8)
                let uid = selectedPost?.publisherUID ?? "null"
                let picID = selectedPost?.partyPicLink
                let otherInfo = selectedPost?.otherInfo
                
                
                fullVC.post = FeedPost(uid: uid, isPic: true, picID: picID, postCaption: otherInfo, uploadDate: selectedPost?.convertedDate ?? "null", fullName: selectedPost?.fullName, username: selectedPost?.username, imageData: postImageData, userImage: userImageData, postID: selectedPost?.postID ?? "null", userImageID: "null", uploadTime: selectedPost?.convertedTime ?? "null", timestamp: selectedPost?.timeStamp, active: selectedPost?.active)
            }
                
            else if let areaVC = navVC.viewControllers.first as? AreaPostsViewController{
                areaVC.currentAreaParties = pts
                areaVC.region = map.region
            }
        }
    }
}

extension UISearchBar {
    
    func getTextField() -> UITextField? { return value(forKey: "searchField") as? UITextField }
    func setText(color: UIColor) { if let textField = getTextField() { textField.textColor = color } }
    func setPlaceholderText(color: UIColor) { getTextField()?.setPlaceholderText(color: color) }
    func setClearButton(color: UIColor) { getTextField()?.setClearButton(color: color) }
    
    func setTextField(color: UIColor) {
        guard let textField = getTextField() else { return }
        switch searchBarStyle {
        case .minimal:
            textField.layer.backgroundColor = color.cgColor
            textField.layer.cornerRadius = 6
        case .prominent, .default: textField.backgroundColor = color
        @unknown default:
            return
        }
    }
    
    func setSearchImage(color: UIColor) {
        guard let imageView = getTextField()?.leftView as? UIImageView else { return }
        imageView.tintColor = color
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
    }
}

extension UITextField {
    
    private class ClearButtonImage {
        static private var _image: UIImage?
        static private var semaphore = DispatchSemaphore(value: 1)
        static func getImage(closure: @escaping (UIImage?)->()) {
            DispatchQueue.global(qos: .userInteractive).async {
                semaphore.wait()
                DispatchQueue.main.async {
                    if let image = _image { closure(image); semaphore.signal(); return }
                    guard let window = UIApplication.shared.windows.first else { semaphore.signal(); return }
                    let searchBar = UISearchBar(frame: CGRect(x: 0, y: -200, width: UIScreen.main.bounds.width, height: 44))
                    window.rootViewController?.view.addSubview(searchBar)
                    searchBar.text = "txt"
                    searchBar.layoutIfNeeded()
                    _image = searchBar.getTextField()?.getClearButton()?.image(for: .normal)
                    closure(_image)
                    searchBar.removeFromSuperview()
                    semaphore.signal()
                }
            }
        }
    }
    
    func setClearButton(color: UIColor) {
        ClearButtonImage.getImage { [weak self] image in
            guard   let image = image,
                let button = self?.getClearButton() else { return }
            button.imageView?.tintColor = color
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    func setPlaceholderText(color: UIColor) {
        attributedPlaceholder = NSAttributedString(string: placeholder != nil ? placeholder! : "", attributes: [.foregroundColor: color])
    }
    
    func getClearButton() -> UIButton? { return value(forKey: "clearButton") as? UIButton }
}

extension UISearchBar {
    var textField: UITextField? {
        return subviews.first?.subviews.compactMap { $0 as? UITextField }.first
    }
}

extension UIViewController{
    
    func loadDate(ambiguous: Bool) -> String{
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        if ambiguous{
            formatter.dateFormat = "YYYY-MM-dd, a hh:mm"
        }
        else{
            formatter.dateFormat = "YYYY-MM-dd, a hh:mm:ss"
        }
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = today.adding(hours: -5) //How far back posts are loaded in hours
        let uploadDate = formatter.string(from: date)
        return uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
    }
    
    func currentDate() -> String{
        
        //print(TimeZone.current.abbreviation())
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "YYYY-MM-dd, a hh:mm"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let uploadDate = formatter.string(from: today)
        return uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
    }
    
    func time(time: String) -> String{
        
        let substring = time.substring(from: 0, to: time.count - 4)
        print(substring)
        return substring
    }
}

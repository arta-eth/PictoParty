//
//  CameraViewController.swift
//  Party Time
//
//  Created by Artak on 2018-09-15.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate{

    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var camSwitch: UIButton!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var stack: UIStackView!
    
    @IBOutlet weak var useImg: UIButton!
    
    let notificationCenter = NotificationCenter.default
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var output: AVCapturePhotoOutput?
    var displayImage = UIImageView()
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var flashMode = AVCaptureDevice.FlashMode.off
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    var camPos = "Back"
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    

    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
   
    public enum CameraPosition {
        case front
        case rear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        useImg.isEnabled = false
        useImg.isHidden = true
        shutterButton.layer.cornerRadius = shutterButton.frame.height / 2
        shutterButton.clipsToBounds = true
        useImg.layer.cornerRadius = useImg.frame.height / 2
        useImg.clipsToBounds = true
        shutterButton.layer.borderColor = UIColor.lightGray.cgColor
        shutterButton.layer.borderWidth = 15
        flashBtn.setRadiusWithShadow()
        camSwitch.setRadiusWithShadow()
        
        if !UserDefaults.standard.bool(forKey: "FirstTimeCam"){
            checkCameraAccess()
        }
        else{
            UserDefaults.standard.set(false, forKey: "FirstTimeCam")
        }

    }
    
    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Denied, request permission from settings")
            UserDefaults.standard.set(false, forKey: "AuthCam")
            presentCameraSettings()
        case .restricted:
            print("Restricted, device owner must approve")
            UserDefaults.standard.set(false, forKey: "AuthCam")
        case .authorized:
            print("Authorized, proceed")
            UserDefaults.standard.set(true, forKey: "AuthCam")
            setUpCam()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                    UserDefaults.standard.set(true, forKey: "AuthCam")
                    self.setUpCam()
                } else {
                    print("Permission denied")
                    UserDefaults.standard.set(false, forKey: "AuthCam")
                }
            }
        @unknown default:
            return
        }
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Sorry!",
                                                message: "Camera Access must be enabled from settings in order to use this feature",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    // Handle
                })
            }
        })
        present(alertController, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        
        let vc = self.parent as? PhotosTabVC
        
        if(vc?.fromProfile ?? false){
            displayView.layer.cornerRadius = displayView.frame.height / 2
        }
      
        
        displayView.clipsToBounds = true

    }
    
    @IBAction func usePhoto(_ sender: UIButton) {
        
            let vc = self.parent as? PhotosTabVC
        
            var multiplier = 1
            if(!(vc?.fromProfile ?? false)){
                multiplier = 2
            }
        
        rotateButtonAnimate(multiplier: multiplier)
        
    }
    
    
    
    @IBAction func zoomCamera(_ sender: UIPinchGestureRecognizer) {
        guard let device = rearCameraInput?.device else { return }
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        let newScaleFactor = minMaxZoom(sender.scale * lastZoomFactor)
        switch sender.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
   
    @IBAction func switchCam(_ sender: UIButton) {
        do {
            try rotateCameraViews()
        }
        catch {
            print(error)
        }
        switch currentCameraPosition {
        case .some(.front):
            print("front")
        case .some(.rear):
            print("back")
        case .none:
            return
        }
    }
    
    @IBAction func flash(_ sender: UIButton) {
        
        if let currentDevice = UserDefaults.standard.string(forKey: "currentDevice"){
        
            guard let camPos = currentCameraPosition else{return}
            switch camPos{
            
            case .front:
                switch frontCamera?.hasFlash{
                
                case true:
                    print(currentDevice)
                    if flashMode == .on {
                        flashMode = .off
                        flashBtn.setImage(#imageLiteral(resourceName: "noFlash"), for: .normal)
                    }
                        
                    else if flashMode == .off{
                        flashMode = .on
                        flashBtn.setImage(#imageLiteral(resourceName: "Flash"), for: .normal)
                    }
                
                default:
                    print(currentDevice)
                    
                }
            case .rear:
                if flashMode == .on {
                    flashMode = .off
                    flashBtn.setImage(#imageLiteral(resourceName: "noFlash"), for: .normal)
                }
                    
                else if flashMode == .off{
                    flashMode = .on
                    flashBtn.setImage(#imageLiteral(resourceName: "Flash"), for: .normal)
                }
            }
        }

      
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        
        camSwitch.isEnabled = false
        flashBtn.isEnabled = false
        shutterButton.isEnabled = false
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        self.output?.capturePhoto(with: settings, delegate: self)
       
    }
    
    
    func add(image: UIImage){
        
        showButtonAnimate()
        captureSession?.removeInput((captureSession?.inputs.first)!)
        videoPreviewLayer?.removeFromSuperlayer()
        captureSession?.stopRunning()
        
        switch camPos{
        case "Front":
            displayImage.image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored).crop()
        default:
            displayImage.image = image.crop()
        }
        
        displayImage.translatesAutoresizingMaskIntoConstraints = false
        displayView.insertSubview(displayImage, at: 1)
        displayImage.contentMode = UIView.ContentMode.scaleAspectFill
        displayImage.leadingAnchor.constraint(equalTo: displayView.leadingAnchor).isActive = true
        displayImage.trailingAnchor.constraint(equalTo: displayView.trailingAnchor).isActive = true
        displayImage.topAnchor.constraint(equalTo: displayView.topAnchor).isActive = true
        displayImage.bottomAnchor.constraint(equalTo: displayView.bottomAnchor).isActive = true
        
        let button = UIButton(type: .system) // let preferred over var here
        button.tag = 20
        button.backgroundColor = UIColor.clear
        button.setImage(#imageLiteral(resourceName: "Cancel"), for: .normal)
        button.addTarget(self, action: #selector(cancel(_:)), for: UIControl.Event.touchUpInside)
        button.tintColor = UIColor.white
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        displayImage.addSubview(button)
        button.trailingAnchor.constraint(equalTo: displayImage.trailingAnchor, constant: -30).isActive = true
        button.topAnchor.constraint(equalTo: displayImage.topAnchor, constant: 30).isActive = true
        button.setRadiusWithShadow()
        
        
        let button2 = UIButton(type: .system)// let preferred over var here
        button2.tag = 30
        button2.backgroundColor = UIColor.clear
        button2.setImage(#imageLiteral(resourceName: "SaveImg"), for: UIControl.State.normal)
        
        
        
        button2.addTarget(self, action: #selector(saveToCameraRoll(_:)), for: UIControl.Event.touchUpInside)
        button2.tintColor = UIColor.white
        button2.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        button2.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button2.translatesAutoresizingMaskIntoConstraints = false
        displayImage.addSubview(button2)
        button2.leadingAnchor.constraint(equalTo: displayImage.leadingAnchor, constant: 30).isActive = true
        button2.topAnchor.constraint(equalTo: displayImage.topAnchor, constant: 30).isActive = true
        button2.setRadiusWithShadow()
    
        
        
        
        
        displayImage.isUserInteractionEnabled = true

    }
    
    @objc func cancel(_ sender: UIButton){
        
        hideButtonAnimate()
        
        
        for views in displayImage.subviews{
            
            views.removeFromSuperview()
        }
        displayImage.removeFromSuperview()
        
        setUpCam()
        
    }
    
    func hideBtn(_ sender: UIButton, shown: Bool){
        
        switch shown{
            
        case true:
            UIView.animate(withDuration: 0.5, animations: {
                
                sender.alpha = 0
                
            })
        case false:
            UIView.animate(withDuration: 0.5, animations: {
                
                
                sender.setImage(UIImage(named: "Saved"), for: UIControl.State.normal)
                sender.alpha = 1.0
                sender.isEnabled = true
            })
        }
    }
    
    @objc func saveToCameraRoll(_ sender: UIButton){
        
        hideBtn(sender, shown: true)
        let n = self.displayImage.image?.crop()
        let activity = UIActivityIndicatorView()
        activity.style = UIActivityIndicatorView.Style.whiteLarge
        activity.translatesAutoresizingMaskIntoConstraints = false
        displayImage.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: sender.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: sender.centerYAnchor).isActive = true
        sender.isEnabled = false
        activity.setRadiusWithShadow()
        activity.startAnimating()
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: n!)
        }, completionHandler: { success, error in
            if success {
                // Saved successfully!
                DispatchQueue.main.async {
                    activity.stopAnimating()
                    activity.removeFromSuperview()
                    self.hideBtn(sender, shown: false)
                }
            }
            else if error != nil {
                // Save photo failed with error
                print(error?.localizedDescription ?? "")
            }
            else {
                // Save photo failed with no error
            }
        })
    }
    
    func rotateCameraViews() throws {
        
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else {
            throw CameraControllerError.captureSessionIsMissing }
        captureSession.beginConfiguration()
        func rotateCameraToFront() throws {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera!)
            captureSession.removeInput(rearCameraInput!)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }
            else { throw CameraControllerError.invalidOperation }
        }
        
        func rotateCameraToRear() throws {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera!)
            captureSession.removeInput(frontCameraInput!)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.currentCameraPosition = .rear
            }
            else { throw CameraControllerError.invalidOperation }
        }
        //7
        switch currentCameraPosition {
        case .front:
            camPos = "Back"
            try rotateCameraToRear()
            
        case .rear:
            camPos = "Front"
            try rotateCameraToFront()
        }
        
        //8
        captureSession.commitConfiguration()
      
        
    }
    
    func showAnimate()
    {
        
        
        self.displayView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        self.displayView.alpha = 0.0
        UIView.animate(withDuration: 0.35, animations: {
            self.displayView.alpha = 1.0
            
            self.displayView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let vc = self.parent?.parent as? EventDescriptionViewController
            vc?.setPicture()
            
            vc?.backBtn.tintColor = UIColor.clear
        })
    }
    
    func removeAnimate()
    {
        
        if let vc = self.parent?.parent as? EventDescriptionViewController{
            vc.setPicture()
            vc.backBtn.tintColor = UIColor.white
            vc.backBtn.isEnabled = true
        
        }
        
        else if let editVC = self.parent?.parent as? ProfileViewController{
            
            editVC.updatePhoto()
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.displayView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            self.displayView.alpha = 0.0
        }, completion: {(finished : Bool) in
            if(finished)
            {
                self.willMove(toParent: nil)
                self.parent?.view.removeFromSuperview()
                self.parent?.removeFromParent()
            }
        })
    }
    
  
    
    func setUpCam(){
        
        self.captureSession?.startRunning()
        
        DispatchQueue.main.async {
            self.camSwitch.isEnabled = true
            self.flashBtn.isEnabled = true
        }
        
        prepare {(error) in
            if let error = error {
                print(error)
            }
            try? self.displayPreview(on: self.displayView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
      
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
          notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        captureSession?.stopRunning()
        notificationCenter.removeObserver(self)


    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        showAnimate()
       if UserDefaults.standard.bool(forKey: "AuthCam"){
            if(!(self.captureSession?.isRunning ?? false)){
                self.captureSession?.startRunning()
            }
        }
    }
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        captureSession?.stopRunning()
    }
    
    @objc func appMovedToForeground() {
        print("App moved to foreground!")
        
        if UserDefaults.standard.bool(forKey: "AuthCam"){
            if(!(self.captureSession?.isRunning)!){
                self.captureSession?.startRunning()
            }
        }
    }

    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            
            throw CameraControllerError.captureSessionIsMissing }
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer?.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(videoPreviewLayer!, at: 0)
        self.videoPreviewLayer?.frame = view.layer.bounds
    }
    
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        
        func createCaptureSession() { self.captureSession = AVCaptureSession() }
        
        func configureCaptureDevices() throws {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = (session.devices.compactMap { $0 })
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
            
            }
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
            if(camPos == "Back"){
                let rearCamera = self.rearCamera
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera!)
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                self.currentCameraPosition = .rear
            }
            else if(camPos == "Front"){
                let frontCamera = self.frontCamera
                    self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera!)
                    if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                    else { throw CameraControllerError.inputsAreInvalid }
                    self.currentCameraPosition = .front
            }
            else { throw CameraControllerError.noCamerasAvailable }
        }
        func configurePhotoOutput() throws {
            
            guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing }
            self.output = AVCapturePhotoOutput()
            self.output!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            if captureSession.canAddOutput(self.output!) { captureSession.addOutput(self.output!) }
            if(!(self.captureSession?.isRunning)!){
                self.captureSession?.startRunning()
            }
        }
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func showButtonAnimate(){
        
        self.useImg.isHidden = false
        self.useImg.isEnabled = true
        UIView.animate(withDuration: 0.2, animations: {
            self.stack.transform = CGAffineTransform(translationX: self.view.frame.minX, y: self.view.frame.minY)
                self.useImg.alpha = 1.0
                self.shutterButton.alpha = 0.0
                self.shutterButton.isEnabled = false
                self.shutterButton.isHidden = true
        })
    }
    
    func rotateButtonAnimate(multiplier: Int){

        UIView.animate(withDuration: 0.30, animations: {
            self.useImg.transform = CGAffineTransform(rotationAngle: CGFloat.pi / CGFloat(multiplier))
        }, completion: { (finished: Bool) in
            if(multiplier == 1){
                self.performSegue(withIdentifier: "choseDP", sender: nil)
            }
            else{
                
                if let n = self.parent?.parent as? RootPageViewController{
                    
                    
                    if let navVC = n.viewControllerList[1] as? UINavigationController{
                        
                        if let vc = navVC.viewControllers.first as? EventDescriptionViewController{
                            vc.image = self.displayImage.image
                            n.setViewControllers([vc], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
                        }
                    }
                }
            }
        })
    }
    
    func hideButtonAnimate(){
        
        self.shutterButton.isEnabled = true
        self.shutterButton.isHidden = false
        UIView.animate(withDuration: 0.15, animations: {
            self.stack.transform = CGAffineTransform(translationX: self.view.frame.minX, y: self.view.frame.minY)
            self.shutterButton.alpha = 1.0
            self.useImg.alpha = 0.0
            self.useImg.isHidden = true
            self.useImg.isEnabled = false
        })
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let data = photo.fileDataRepresentation(){
            let image = UIImage(data: data)
            add(image: image!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? ProfileViewController{
            vc.dp = self.displayImage.image ?? UIImage(named: "default_DP.png")!
            vc.changedDP = true
        }
    }
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

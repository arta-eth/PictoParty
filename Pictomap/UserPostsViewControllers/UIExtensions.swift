//
//  UIExtensions.swift
//  Party Time
//
//  Created by Artak on 2018-09-24.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit
import OneSignal
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseDatabase


extension String {
    
    var strippedTitle: String {
        let okayChars = Set("0123456789APM-:, ")
        return self.filter {okayChars.contains($0) }
    }
}

extension Date {
    func adding(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
}

extension UIImage {
    
    func crop() -> UIImage? {
        var imageHeight = self.size.height
        var imageWidth = self.size.width
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }
        let size = CGSize(width: imageWidth, height: imageHeight)
        let refWidth : CGFloat = CGFloat(self.cgImage!.width)
        let refHeight : CGFloat = CGFloat(self.cgImage!.height)
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = self.cgImage!.cropping(to: cropRect) {
            let cropped = UIImage(cgImage: imageRef, scale: 0, orientation: self.imageOrientation)
            return cropped
        }
        return nil
    }
    
    func circleImage(_ cornerRadius: CGFloat, size: CGSize, color: UIColor, width: CGFloat) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            var path: UIBezierPath
            if size.height == size.width {
                if cornerRadius == size.width / 2 {
                    path = UIBezierPath(arcCenter: CGPoint(x: size.width/2, y: size.height/2), radius: cornerRadius, startAngle: 0, endAngle: 2.0*CGFloat(Double.pi), clockwise: true)
                }else {
                    path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                }
            }else {
                path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            }
            context.addPath(path.cgPath)
            context.clip()
            self.draw(in: rect)
            guard let uncompressedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                return nil
            }
            UIGraphicsEndImageContext()
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: uncompressedImage.size))
            imageView.contentMode = .center
            imageView.image = uncompressedImage
            imageView.layer.cornerRadius = uncompressedImage.size.width / cornerRadius
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = width
            imageView.layer.borderColor = color.cgColor
            
            UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0)
            defer { UIGraphicsEndImageContext() }
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            imageView.layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }else {
            return nil
        }
    }}


extension UIColor{
    
    func mainColor() -> UIColor{
        return UIColor(hue: 0.5861, saturation: 0.6, brightness: 1, alpha: 1.0) /* #66afff */
    }
}

extension UIViewController{
    
    func saveImage(_ image: UIImage, name: String, isDP: Bool) -> Bool{
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            return false
        }
        do {
            let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            try imageData.write(to: imageURL)
            if isDP{
                UserInfo.dp = image
            }
            return true
        } catch {
            return false
        }
    }
    
    // returns an image if there is one with the given name, otherwise returns nil
    func loadImage(withName name: String) -> UIImage? {
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    func saveClass(_ postClass: Data, name: String){

        do {
            let postURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            try postClass.write(to: postURL)
        } catch {print(error.localizedDescription)}
    }
    
    func loadClass(withName name: String) -> Data? {
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
        
        do{
            let data = try Data(contentsOf: imageURL)
            return data
        }catch{print(error.localizedDescription)}
        return nil
    }
    
    func removeFile(withName name: String){
        
         let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)

        do{
            try FileManager.default.removeItem(at: imageURL)
        }catch{print(error.localizedDescription)}
        
    }
    
    func clearDocumentsDirectory() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let items = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        items?.forEach { item in
            try? fileManager.removeItem(at: item)
        }
    }
    
    
    func loggingOut(auto: Bool){

        
        if(!auto){
            let uid = KeychainWrapper.standard.string(forKey: "USER")
        Database.database().reference().child("Users").child(uid!).child("Credentials").child("Notification ID").removeValue(completionBlock: { error, snapshot in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    return
                }
                else{
                    self.removingStoredFiles()
                }
            })
        }
        else{
            self.removingStoredFiles()
        }
 
    }
    
    func removingStoredFiles(){
        
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        self.clearDocumentsDirectory()
        OneSignal.setSubscription(false)
        let success = KeychainWrapper.standard.removeAllKeys()
        print(success)
        do{
            try Auth.auth().signOut()
        }catch{}
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = mainStoryBoard.instantiateViewController(withIdentifier: "noAccVC")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = loginVC
    }
}

extension UIView {
    
    func showNoWifiLabel(){
        
        
        
        let n = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 40))
        n.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        n.text = "No Internet Connection"
        n.textColor = UIColor.white
        n.translatesAutoresizingMaskIntoConstraints = false
        n.textAlignment = .center
        self.addSubview(n)
        let guide = self.safeAreaLayoutGuide
        n.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 10).isActive = true
        n.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: -10).isActive = true
        n.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        n.heightAnchor.constraint(equalToConstant: 40).isActive = true
        n.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY - n.frame.height * 2)
        UIView.animate(withDuration: 0.40, animations: {
            n.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY)
        }, completion: { (finished: Bool) in
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.removeWifiLabel(sender:)), userInfo: n, repeats: false)
        })
    }
    
    class noWifiLabel: UILabel{
        
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func layoutSubviews() {
            
        
        }
        
    }
    

    
    @objc func removeWifiLabel(sender: Timer){
        let n = sender.userInfo as? UILabel
        sender.invalidate()
        UIView.animate(withDuration: 0.15, animations: {
            n!.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY - (n?.frame.height)! * 2)
        }, completion: { (finished: Bool) in
            n?.removeFromSuperview()
        })
    }

    
    func roundCorners(_ corners: CACornerMask, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        self.layer.maskedCorners = corners
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        
    }
    
    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }
        return nil
    }
}

public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}

extension UIBarButtonItem{
    
    func hideButton(){
        self.isEnabled = false
        self.tintColor = UIColor.clear
    }
    
    func showButton(color: UIColor){
        self.isEnabled = true
        self.tintColor = color
    }
}

extension String {
    var stripped: String {
        let okayChars = Set("+0123456789")
        return self.filter {okayChars.contains($0) }
    }
    
    var revert: String {
        let okayChars = Set("123456789")
        return self.filter {okayChars.contains($0) }
    }
}

extension UIButton{
    
    func updateFollowBtn(following: Bool){
        switch following{
        case true:
            self.setTitle("Following", for: .normal)
            self.backgroundColor = UserBackgroundColor().primaryColor
            self.tintColor = UIColor.white
            print("following")
        case false:
            self.setTitle("Follow", for: .normal)
            self.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            self.tintColor = UIColor.blue.withAlphaComponent(0.8)
            print("not following")
        }
    }
    
    
}

extension UIView{
    
    func hollowedCenter(offset: CGFloat) -> CAShapeLayer{
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: self.frame.midX, y: self.frame.midY),
                    radius: (self.frame.width / 2) - offset - 5,
                    startAngle: 0.0,
                    endAngle: 2.0 * .pi,
                    clockwise: false)
        path.addRect(CGRect(origin: .zero, size: self.superview?.frame.size ?? CGSize(width: 0, height: 0)))
        
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        return maskLayer
    }
}


class UITextViewWithPlaceholder: UITextView {
    
    private var originalTextColour: UIColor = UIColor.black
    private var placeholderTextColour: UIColor = UIColor(red: 0, green: 0, blue: 0.098, alpha: 0.22)
    
    var placeholder:String?{
        didSet{
            if let placeholder = placeholder{
                text = placeholder
            }
        }
    }
    
    override internal var text: String? {
        didSet{
            textColor = originalTextColour
            if text == placeholder{
                textColor = placeholderTextColour
            }
        }
    }
    
    override internal var textColor: UIColor?{
        didSet{
            if let textColor = textColor, textColor != placeholderTextColour{
                originalTextColour = textColor
                if text == placeholder{
                    self.textColor = placeholderTextColour
                }
            }
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        // Remove the padding top and left of the text view
        self.textContainer.lineFragmentPadding = 0
        self.textContainerInset = UIEdgeInsets.zero
        
        // Listen for text view did begin editing
        NotificationCenter.default.addObserver(self, selector: #selector(removePlaceholder), name: UITextView.textDidBeginEditingNotification, object: nil)
        // Listen for text view did end editing
        NotificationCenter.default.addObserver(self, selector: #selector(addPlaceholder), name: UITextView.textDidEndEditingNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc private func removePlaceholder(){
        if text == placeholder{
            text = ""
        }
    }
    
    @objc private func addPlaceholder(){
        if text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
            text = placeholder
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

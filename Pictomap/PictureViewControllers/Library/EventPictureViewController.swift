//
//  EventPictureViewController.swift
//  Party Time
//
//  Created by Artak on 2018-07-29.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import Photos

class EventPictureViewController: PictureUIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    let reuseIdentifier = "PhotoCell"
    var images = [PHAsset]()
    var image = UIImage()

    var chosen: UIImage?
    let button = UIButton()
    var collectionViewFlowLayout = UICollectionViewFlowLayout()

    var size = CGFloat()
    
    typealias DownloadComplete = () -> ()

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        
        if !UserDefaults.standard.bool(forKey: "FirstTimePhoto"){
            checkPhotosAccess()
        }
        else{
            UserDefaults.standard.set(false, forKey: "FirstTimePhoto")
        }
    }
    
    func checkPhotosAccess() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied:
            
            print("Denied, request permission from settings")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
        case .restricted:
            print("Restricted, device owner must approve")
            UserDefaults.standard.set(false, forKey: "AuthPhoto")
        case .authorized:
            
            print("Authorized, proceed")
            UserDefaults.standard.set(true, forKey: "AuthPhoto")

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized  {
                    print("Permission granted, proceed")
                    UserDefaults.standard.set(true, forKey: "AuthPhoto")

                } else {
                    print("Permission denied")
                    UserDefaults.standard.set(false, forKey: "AuthPhoto")
                }
            })
        @unknown default:
            return
        }
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Sorry!",
                                                message: "Photo Library Access must be enabled from settings in order to use this feature",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    // Handle
                })
            }
        })
        let p = self.parent as? PictureUIViewController
        p?.present(alertController, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        
        collectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout

    }
    
    
    func getImages() {
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        assets.enumerateObjects({ (object, count, stop) in
            // self.cameraAssets.add(object)
            self.images.append(object)
        })
        
        //In order to get latest image first, we just reverse the array
        self.images.reverse()
        
        DispatchQueue.main.async{
            print("potus")
            self.collectionView?.reloadData()
            self.collectionView(self.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
            self.add()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        print(images.count)
        return images.count
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        images.removeAll()
        
        if UserDefaults.standard.bool(forKey: "AuthPhoto"){
            print("yeet")
            getImages()
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        

        
        if !UserDefaults.standard.bool(forKey: "AuthPhoto"){
            presentCameraSettings()
        }
    }
    
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print(indexPath.item)
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as!
        PhotoCollectionViewCell
        
     
        
       // cell.layer.cornerRadius = cell.frame.height / 4
        cell.clipsToBounds = true
       
        let asset = images[indexPath.item]
        let manager = PHImageManager.default()
        manager.requestImage(for: asset,
                             targetSize: CGSize(width: 120.0, height: 120.0),
                             contentMode: .aspectFill,
                             options: nil) { (result, _) in
                                cell.cameraRoll.image = result
                                cell.cameraRoll.clipsToBounds = true
                                cell.cameraRoll.contentMode = .scaleAspectFill
        }
      
        
        self.size = cell.frame.height - 40
        
        return cell
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        

        if !decelerate{
            stopScrollAnimateBtn()
            center()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
   
        stopScrollAnimateBtn()
        center()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        startScrollAnimateBtn()
    }
    
    
    
    func center(){
        
        // Find collectionview cell nearest to the center of collectionView
        // Arbitrarily start with the last cell (as a default)
        var closestCell : UICollectionViewCell = collectionView.visibleCells[0];
        for cell in collectionView!.visibleCells as [UICollectionViewCell] {
            let closestCellDelta = abs(closestCell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
            let cellDelta = abs(cell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }
        }
        let indexPath = collectionView.indexPath(for: closestCell)
        collectionView.scrollToItem(at: indexPath!, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        
        
        update(indexPath: indexPath!, initial: true)
    }
    
 
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
    }
    
    func download(asset: PHAsset, completed: @escaping DownloadComplete){
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 500.0, height: 500.0), contentMode: .aspectFit, options: nil, resultHandler: {
            (result, info)->Void in
            
            if let pic = result?.crop(){
                self.chosen = pic
            }

            completed()
            
        })
        
        
    }
    
    @objc func reverseAnimate(){
        
        let ggggg = self.parent?.parent as? PhotosTabVC
        
        var multiplier = 1
        if(!(ggggg?.fromProfile)!){
            
            multiplier = 2
        }
        
        UIView.animate(withDuration: 0.30, animations: {
            
            self.button.transform = CGAffineTransform(rotationAngle: CGFloat.pi / CGFloat(multiplier))
            
        }, completion: { (finished: Bool) in
            
            let p = self.parent as? PictureUIViewController
            p?.usePhoto(fromProfile: (ggggg?.fromProfile)!)
 
        })
    }
    
    func update(indexPath: IndexPath, initial: Bool){
        
        
        
        print("You selected cell #\(indexPath.item)!")
        
        
        print("os")
        let asset = images[indexPath.item]
        self.download(asset: asset){
            
            print("ye")
            if let vc = self.parent as? PictureUIViewController{
                vc.loadImage(image: self.chosen!)
            }
        }
    }
    
    func add(){
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        
        self.button.tag = 50
        
        self.view.addSubview(button)
        
        self.view.bringSubviewToFront(button)
        
        self.button.addTarget(self, action: #selector(self.reverseAnimate), for: UIControl.Event.touchUpInside)
        
        self.button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        self.button.centerXAnchor.constraint(equalTo: (self.view.centerXAnchor)).isActive = true
        self.button.centerYAnchor.constraint(equalTo: (self.collectionView.centerYAnchor)).isActive = true
        
        self.button.heightAnchor.constraint(equalToConstant: size).isActive = true
        
        self.button.widthAnchor.constraint(equalToConstant: size).isActive = true
        
        self.button.backgroundColor = UIColor.red.withAlphaComponent(0.7)
        
        self.button.layer.cornerRadius = self.button.frame.height / 2
        
        print(self.button.frame.height)
        
        
        self.button.clipsToBounds = true
        self.button.setImage(UIImage(named: "arrowBtn"), for: UIControl.State.normal)
        
        button.setRadiusWithShadow()
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        
        print("You chose \(indexPath.item)")

        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        self.update(indexPath: indexPath, initial: true)
    }
    
    
    func startScrollAnimateBtn(){
        
        
        self.button.isEnabled = false
        UIView.animate(withDuration: 0.25, animations: {
            
            self.button.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            
        })
        
    }

    
    func stopScrollAnimateBtn(){
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.button.isEnabled = true

        })
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCell: CGFloat = 3   //you need to give a type as CGFloat
        let cellWidth = UIScreen.main.bounds.size.width / numberOfCell
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //collectionView.reloadData()
        //images.remove(at: indexPath.item)
        //self.collectionView?.deleteItems(at: [indexPath])
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        //let choseVC = segue.destination as? EventDescriptionViewController
        
        //choseVC?.image = image
        
        
    }
    
    
}

extension UIView {
    func setRadiusWithShadow(_ radius: CGFloat? = nil) {
        //self.layer.cornerRadius = radius ?? self.frame.width / 2
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.7
        self.layer.masksToBounds = false
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

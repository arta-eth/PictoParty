//
//  CameraRollPopUpView.swift
//  Pictomap
//
//  Created by Artak on 2018-11-25.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SwiftKeychainWrapper

extension FullPostViewController{
    
    
    @IBAction func showCameraRoll(_ sender: UIButton){
        
        checkPhotosAccess{
            if UserDefaults.standard.bool(forKey: "AuthPhoto"){
                
                if self.commentInputView.isFirstResponder{
                    self.commentInputView.resignFirstResponder()
                }
                
                DispatchQueue.main.async {
                    if !self.cameraRollView.isHidden{
                        self.cameraRollHide(sender: sender)
                        print("has and removing")
                    }
                    else{
                        self.collectionView.reloadData()
                        self.getImages()
                        self.cameraRollPopUp(sender: sender)
                        print("has and adding")
                        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionView.ScrollPosition.left, animated: false)
                        self.collectionView.deselectItem(at: self.collectionView.indexPathsForSelectedItems?.first ?? IndexPath(item: 0, section: 0), animated: false)
                        
                    }
                }
            }
            else{
                print("no auth")
                self.presentCameraSettings()
            }
        }
    }
    
    func animateAppearance(cell: UICollectionViewCell){
        
        cell.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            cell.alpha = 1.0
        })
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let numberOfCell: CGFloat = 5
        let cellWidth = UIScreen.main.bounds.size.width / numberOfCell
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photos", for: indexPath) as! PhotosForUploadCell
        cell.clipsToBounds = true
        let asset = images[indexPath.item]
        let manager = PHImageManager.default()
        cell.imageView.image = UIImage(named: "default_DP.png")
        manager.requestImage(for: asset, targetSize: CGSize(width: 120.0, height: 120.0), contentMode: .aspectFill, options: nil) { (result, _) in
            cell.imageView.image = result
            cell.imageView.clipsToBounds = true
            cell.imageView.contentMode = .scaleAspectFill
            print("retrieving: \(indexPath.item)")
            self.animateAppearance(cell: cell)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.postCommentBtn.isEnabled = true
        self.download(asset: images[indexPath.item]){
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func getImages() {
        
        self.images.removeAll()
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        assets.enumerateObjects({ (object, count, stop) in
            // self.cameraAssets.add(object)
            self.images.append(object)
        })
        
        //In order to get latest image first, we just reverse the array
        self.images.reverse()
        
        DispatchQueue.main.async{
            self.collectionView?.reloadData()
        }
    }
    
    func download(asset: PHAsset, completed: @escaping DownloadComplete){
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 500.0, height: 500.0), contentMode: .aspectFit, options: nil, resultHandler: {
            (result, info)->Void in
            
            self.commentImage = (result?.crop())!
            print("than")
            
            completed()
            
        })
    }
}

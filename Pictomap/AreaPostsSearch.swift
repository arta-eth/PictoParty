//
//  AreaPostsSearchTable.swift
//  Pictomap
//
//  Created by Artak on 2018-10-27.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import SwiftKeychainWrapper


extension AreaPostsViewController{
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.setShowsCancelButton(false, animated: true)
        searchbar.text?.removeAll()
        searchedUsernamePosts.removeAll()
        searchBar.resignFirstResponder()
        //Bool false
        filtered = false
        
        self.collectionView.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        sortLikes(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.checkPostTime()
        })
    }
    
    func reloadSortMenu(){
        
        if let stack = sortView.subviews.first as? UIStackView{
            for sub in stack.subviews{
                if let button = sub as? UIButton{
                    
                    if button == stack.subviews[1]{
                        button.setTitleColor(.lightText, for: .normal)
                    }
                    else{
                        button.setTitleColor(.white, for: .normal)
                    }
                }
            }
        }
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        searchBar.setShowsCancelButton(true, animated: true)
        //Bool true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
    }
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard let r = searchBar.text else{return}
        filtered = true
        searchBar.isLoading = true
        reloadSortMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            if r != ""{
                self.filtered = true
                self.searchedUsernamePosts = self.currentAreaParties.filter({$0.username?.contains(r) ?? false})
                self.collectionView.reloadData()
            }
            else{
                
                self.filtered = false
                self.searchedUsernamePosts.removeAll()
                self.sortLikes(nil)
                self.collectionView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.checkPostTime()
                })
            }
            searchBar.isLoading = false
        })
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        sortLikes(nil)
        
    }
    
}


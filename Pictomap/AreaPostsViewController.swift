//
//  AreaPostsViewController.swift
//
//
//  Created by Artak on 2018-09-22.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseFirestore
import CoreLocation
import MapKit

private let reuseIdentifier = "areaCell"

class AreaPostsViewController: UIViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UISearchResultsUpdating, UICollectionViewDelegate, UICollectionViewDataSource{
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var region: MKCoordinateRegion! = nil
    
    var currentAreaParties = [PostAnnotation]()
    var searchedUsernamePosts = [PostAnnotation]()
    var filtered: Bool? = false
    var selectedPost: PostAnnotation? = nil
    var postClass: FeedPost! = nil
    let searchbar = UISearchBar()
    
    let notificationCenter = NotificationCenter.default
    
    var today = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        
        
        setLeftNavigationItem(button: UIBarButtonItem.SystemItem.stop)
        setRightNavigationItem()
        searchbar.placeholder = "Search Username"
        searchbar.delegate = self
        searchbar.tintColor = UIColor.darkGray
        searchbar.clipsToBounds = true
        searchbar.searchBarStyle = .minimal
        self.navigationItem.titleView = searchbar
        
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.view.backgroundColor = UIColor.black
        searchbar.tintColor = UIColor.white
        searchbar.setText(color: UIColor.white)
        self.searchbar.keyboardAppearance = .dark
        
        // Do any additional setup after loading the view.
        self.today = self.getDate()
    }
    
    override func viewDidLayoutSubviews() {
        backView.roundCorners([UIRectCorner.topRight, UIRectCorner.topLeft], radius: self.view.frame.width / 20)
        //self.view.layer.borderColor = UIColor.lightGray.cgColor
        //self.view.layer.borderWidth = 1
        
        
    }
    
    func reloadCellActiveAnimation(){
        
        for cell in self.collectionView.visibleCells as? [AreaPostsCell] ?? []{
            if let indexPath = self.collectionView.indexPath(for: cell){
                var cellInfo: [PostAnnotation]? = nil
                
                if self.filtered ?? false{
                    cellInfo = searchedUsernamePosts
                }
                else{
                    cellInfo = currentAreaParties
                }
                
                if cellInfo != []{
                    
                    if cellInfo?[indexPath.item].active ?? false{
                        cell.dateLbl.text = "Happening Now"
                        cell.dateLbl.textColor = UIColor.white
                        cell.timestampLbl.textColor = UIColor.white
                        
                        UIView.animate(withDuration: 1, delay: 0, options:
                            [.allowUserInteraction,
                             .repeat,
                             .autoreverse],
                                       animations: {
                                        cell.backgroundColor = UIColor.init(red: 0.3, green: 0.0, blue: 0.8, alpha: 0.2)
                                        cell.backgroundColor = UIColor.init(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.2)
                        }, completion:nil )
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var backView: UIView!
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
        notificationCenter.removeObserver(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        let cell = collectionView.cellForItem(at: indexPath)
        if filtered ?? false{
            self.selectedPost = searchedUsernamePosts[indexPath.item]
        }
        else{
            self.selectedPost = currentAreaParties[indexPath.item]
        }
        
        self.performSegue(withIdentifier: "full", sender: cell)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        if postClass != nil{
            if let post = currentAreaParties.first(where: {$0.postID ==  postClass.postID}){
                //post?.city = postClass.
                post.convertedDate = postClass.uploadDate
                post.convertedTime = postClass.uploadTime
                post.postCaption = postClass.postCaption
                
                if let index = self.currentAreaParties.firstIndex(of: post){
                    
                    print(index)
                    
                    
                    if !(filtered ?? true){
                        self.collectionView.performBatchUpdates({
                            self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                        }, completion: nil)
                    }
                }
            }
        }
        checkPostTime()
        reloadCellActiveAnimation()

    }
    
    func checkPostTime(){
        
        if self.filtered ?? false{
            for post in self.searchedUsernamePosts{
                switch post.active{
                case true:
                    let load = loadDate(ambiguous: true)
                    let current = currentDate()
                    if post.ambiguousTime <= current && post.ambiguousTime >= load{
                        post.active = true
                    }
                    else{
                        if post.ambiguousTime < load{
                            post.active = false
                            if let index = self.searchedUsernamePosts.firstIndex(of: post){
                                self.searchedUsernamePosts.removeAll(where: {$0.postID == post.postID})
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                                }, completion: nil)
                            }
                        }
                    }
                default:
                    print("Clears")
                }
            }
        }
        else{
            for post in self.currentAreaParties{
                switch post.active{
                case true:
                    let load = loadDate(ambiguous: true)
                    let current = currentDate()
                    if post.ambiguousTime <= current && post.ambiguousTime >= load{
                        post.active = true
                    }
                    else{
                        if post.ambiguousTime < load{
                            post.active = false
                            if let index = self.currentAreaParties.firstIndex(of: post){
                                self.currentAreaParties.removeAll(where: {$0.postID == post.postID})
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                                }, completion: nil)
                            }
                        }
                    }
                default:
                    print("Clears")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        
    }
    
    @objc func appMovedToForeground() {
        print("App moved to foreground!")
        checkPostTime()
        reloadCellActiveAnimation()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if self.searchedUsernamePosts != []{
            self.filtered = true
            
        }
        
        map.setRegion(region, animated: false)
        
        let filteredPosts = self.currentAreaParties.filterDuplicate({$0.publisherUID})
        for filt in filteredPosts{
            if filt.username == nil || filt.fullName == nil{
                
                if filt.publisherUID == KeychainWrapper.standard.string(forKey: "USER"){
                    for match in self.currentAreaParties.filter({$0.publisherUID == filt.publisherUID}){
                        guard let index = self.currentAreaParties.firstIndex(of: match) else { return }
                        match.username = KeychainWrapper.standard.string(forKey: "USERNAME")
                        match.fullName = KeychainWrapper.standard.string(forKey: "FULL_NAME")
                        
                        self.collectionView.performBatchUpdates({
                            self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                        }, completion: nil)
                        
                    }
                }
                else{
                    self.downloadNames(uid: filt.publisherUID, handler: { username, fullname in
                        for match in self.currentAreaParties.filter({$0.publisherUID == filt.publisherUID}){
                            guard let index = self.currentAreaParties.firstIndex(of: match) else { return }
                            match.username = username
                            match.fullName = fullname
                            
                            self.collectionView.performBatchUpdates({
                                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                            }, completion: nil)
                            
                        }
                    })
                }
            }
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if let fullVC = segue.destination as? FullPostViewController{
            guard let image = selectedPost?.userImage else{return}
            let data = image.jpegData(compressionQuality: 0.8)
            let uid = selectedPost?.publisherUID ?? "null"
            let picID = selectedPost?.partyPicLink
            let otherInfo = selectedPost?.otherInfo
            
            fullVC.post = FeedPost(uid: uid, isPic: true, picID: picID, postCaption: otherInfo, uploadDate: selectedPost?.convertedDate ?? "null", fullName: selectedPost?.fullName, username: selectedPost?.username, imageData: nil, userImage: data, postID: selectedPost?.postID ?? "null", userImageID: "null", uploadTime: selectedPost?.convertedTime ?? "null", timestamp: selectedPost?.timeStamp, active: selectedPost?.active)
        }
        if let mapVC = segue.destination as? MapViewController{
            mapVC.upts = self.currentAreaParties
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func setLeftNavigationItem(button: UIBarButtonItem.SystemItem) {
        
        let button = UIBarButtonItem(barButtonSystemItem: button, target: self, action: #selector(self.goBack))
        button.tintColor = UIColor.lightText
        self.navigationItem.leftBarButtonItem = button
    }
    
    func setRightNavigationItem() {
        
        let button = UIBarButtonItem(image: UIImage(named: "sortBy"), style: .plain, target: self, action: #selector(self.hideOrShowSort))
        
        button.tintColor = UIColor.lightText
        
        self.navigationItem.rightBarButtonItem = button
    }
    
    @objc func hideOrShowSort(){
        
        if sortView.isHidden{
            self.view.bringSubviewToFront(sortView)
            sortView.isHidden = false
            sortView.alpha = 0.0
            UIView.animate(withDuration: 0.2, animations: {
                self.sortView.alpha = 1.0
            })
        }
        else{
            UIView.animate(withDuration: 0.1, animations: {
                self.sortView.alpha = 0.0
            }, completion: { (finished: Bool) in
                self.sortView.isHidden = true
            })
        }
    }
    
    @objc func sortDate(_ sender: UIButton?){
        
        if self.filtered ?? false{
            searchedUsernamePosts.sort{ $0.timeStamp < $1.timeStamp }
        }
        else{
            currentAreaParties.sort{ $0.timeStamp < $1.timeStamp }
        }
        self.collectionView.reloadData()
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
        for sub in sender?.superview?.subviews ?? []{
            if let button = sub as? UIButton{
                button.setTitleColor(.white, for: .normal)
            }
        }
        sender?.setTitleColor(.lightText, for: .normal)
    }
    
    @objc func sortLikes(_ sender: UIButton?){
        
        if self.filtered ?? false{
            searchedUsernamePosts.sort{ $0.likes > $1.likes }
        }
        else{
            currentAreaParties.sort{ $0.likes > $1.likes }
        }
        self.collectionView.reloadData()
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
        for sub in sender?.superview?.subviews ?? []{
            if let button = sub as? UIButton{
                button.setTitleColor(.white, for: .normal)
            }
        }
        sender?.setTitleColor(.lightText, for: .normal)
    }
    
    @objc func sortUsername(_ sender: UIButton?){
        
        if self.filtered ?? false{
            searchedUsernamePosts.sort{ $0.username < $1.username }
        }
        else{
            currentAreaParties.sort{ $0.username < $1.username }
        }
        
        self.collectionView.reloadData()
        if !sortView.isHidden{
            self.hideOrShowSort()
        }
        for sub in sender?.superview?.subviews ?? []{
            if let button = sub as? UIButton{
                button.setTitleColor(.white, for: .normal)
            }
        }
        sender?.setTitleColor(.lightText, for: .normal)
    }
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    
    lazy var sortView: UIView = {
        
        let safeArea = self.view.safeAreaInsets.top
        let view = UIView.init(frame: CGRect(x: self.view.frame.width - 170, y: safeArea, width: 150, height: 200))
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(view)
        view.isHidden = true
        
        view.widthAnchor.constraint(equalToConstant: 150).isActive = true
        view.heightAnchor.constraint(equalToConstant: 150).isActive = true
        view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: safeArea).isActive = true
        view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
        
        let stack = UIStackView.init(frame: CGRect(x: view.frame.minX + 10, y: view.frame.minY, width: 130, height: 200))
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let labe1 = UILabel.init(frame: CGRect(x: 0, y: 0, width: 130, height: 50))
        let button2 = UIButton.init(frame: CGRect(x: 0, y: 0, width: 130, height: 50))
        button2.setTitle("Most Popular", for: .normal)
        button2.addTarget(self, action: #selector(self.sortLikes(_:)), for: .touchUpInside)
        
        let button3 = UIButton.init(frame: CGRect(x: 0, y: 0, width: 130, height: 50))
        button3.setTitle("Username", for: .normal)
        button3.addTarget(self, action: #selector(self.sortUsername(_:)), for: .touchUpInside)
        
        
        let button4 = UIButton.init(frame: CGRect(x: 0, y: 0, width: 130, height: 50))
        button4.setTitle("Date", for: .normal)
        button4.addTarget(self, action: #selector(self.sortDate(_:)), for: .touchUpInside)
        
        stack.addArrangedSubview(labe1)
        stack.addArrangedSubview(button2)
        stack.addArrangedSubview(button3)
        stack.addArrangedSubview(button4)
        
        for sub in stack.arrangedSubviews{
            
            if let label = sub as? UILabel{
                
                label.attributedText = NSAttributedString(string: "Order by...", attributes:
                    [.underlineStyle: NSUnderlineStyle.single.rawValue])
                label.font = UIFont.boldSystemFont(ofSize: 16)
                label.textColor = UIColor.white
                label.textAlignment = .center
                
            }
            else if let button = sub as? UIButton{
                
                if button == stack.arrangedSubviews[1]{
                    button.setTitleColor(.lightText, for: .normal)
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                }
                else{
                    button.setTitleColor(.white, for: .normal)
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                }
            }
        }
        view.addSubview(stack)
        stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
        return view
        
    }()
    
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    @objc func goBack(){
        
        if self.searchbar.isFirstResponder{
            self.searchbar.resignFirstResponder()
        }
        self.performSegue(withIdentifier: "back2Map", sender: nil)
    }
    
    func downloadNames(uid: String, handler: @escaping (String, String) -> Void){
        
        Firestore.firestore().collection("Users").document(uid).getDocument(completion: { querySnap, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "none")
                return
            }
            else{
                
                let username = querySnap?["Username"] as? String
                let fullname = querySnap?["Full Name"] as? String
                
                handler(username ?? "none", fullname ?? "none")
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = (self.view.frame.width / 2)
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        
        if self.filtered ?? false{
            return searchedUsernamePosts.count
        }
        return currentAreaParties.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? AreaPostsCell
        
        var cellInfo: [PostAnnotation]? = nil
        
        if self.filtered ?? false{
            cellInfo = searchedUsernamePosts
        }
        else{
            cellInfo = currentAreaParties
        }
        
        if let info = cellInfo?[indexPath.row]{
            cell?.postPic.image = info.userImage
            cell?.usernameLbl.text = "@" + (info.username ?? "null")
            cell?.fullnameLbl.text = info.fullName
            cell?.timestampLbl.text = info.convertedTime
            
            if info.active{
                cell?.dateLbl.text = "Happening Now"
                cell?.dateLbl.textColor = UIColor.white
                cell?.timestampLbl.textColor = UIColor.white
                
                UIView.animate(withDuration: 1, delay: 0, options:
                    [.allowUserInteraction,
                     .repeat,
                     .autoreverse],
                               animations: {
                                cell?.backgroundColor = UIColor.init(red: 0.3, green: 0.0, blue: 0.8, alpha: 0.2)
                                cell?.backgroundColor = UIColor.init(red: 0.2, green: 0.7, blue: 0.6, alpha: 0.2)
                }, completion:nil )
            }
            else{
                if info.convertedDate == self.today{
                    cell?.dateLbl.text = "Today"
                    cell?.dateLbl.textColor = UIColor.green
                    cell?.timestampLbl.textColor = UIColor.green
                    cell?.layer.removeAllAnimations()
                    
                }
                else{
                    cell?.dateLbl.text = info.convertedDate?.findMonth(abbreviation: true)
                    cell?.dateLbl.textColor = UIColor(displayP3Red: 0.815, green: 0.828, blue: 0.815, alpha: 1.0)
                    cell?.timestampLbl.textColor = UIColor(displayP3Red: 0.921, green: 0.921, blue: 0.921, alpha: 1.0)
                    cell?.backgroundColor = UIColor.clear
                    cell?.layer.removeAllAnimations()
                    
                }
            }
        }
        
        
        return cell!
    }
    
    
    
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
}

extension String {
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }
        
        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }
        
        return self.substring(from: from, to: end)
    }
    
    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }
        
        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }
        
        return self.substring(from: start, to: to)
    }
}

extension UISearchBar {
    //
    private var searchField: UITextField? {
        let subViews = self.subviews.flatMap { $0.subviews }
        return (subViews.filter { $0 is UITextField }).first as? UITextField
    }
    private var searchIcon: UIImage? {
        let subViews = subviews.flatMap { $0.subviews }
        return  ((subViews.filter { $0 is UIImageView }).first as? UIImageView)?.image
    }
    private var activityIndicator: UIActivityIndicatorView? {
        return searchField?.leftView?.subviews.compactMap{ $0 as? UIActivityIndicatorView }.first
    }
    
    var isLoading: Bool {
        get {
            return activityIndicator != nil
        } set {
            let _searchIcon = searchIcon
            if newValue {
                if activityIndicator == nil {
                    let _activityIndicator = UIActivityIndicatorView(style: .white)
                    _activityIndicator.color = UIColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
                    _activityIndicator.startAnimating()
                    _activityIndicator.backgroundColor = UIColor.clear
                    self.setImage(UIImage(), for: .search, state: .normal)
                    searchField?.leftView?.addSubview(_activityIndicator)
                    let leftViewSize = searchField?.leftView?.frame.size ?? CGSize.zero
                    _activityIndicator.center = CGPoint(x: (leftViewSize.width/2), y: leftViewSize.height/2)
                }
            } else {
                self.setImage(_searchIcon, for: .search, state: .normal)
                activityIndicator?.removeFromSuperview()
            }
        }
    }
}

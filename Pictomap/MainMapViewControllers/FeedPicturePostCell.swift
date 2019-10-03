//
//  FeedPostCell.swift
//  Pictomap
//
//  Created by Artak on 2018-12-17.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseUI

class FeedPicturePostCell: UITableViewCell {

    @IBOutlet weak var quickLikePostBtn: UIButton!
    
    
    
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var postPicture: UIImageView!
    @IBOutlet weak var postCaption: UITextView!
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 100, height: 100))


    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        self.fullName.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) /* #fcfcfc */

        self.username.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) /* #fcfcfc */


        self.username.text?.removeAll()
        self.fullName.text?.removeAll()

        circularProgress.isHidden = true
        circularProgress.progressColor = UIColor.white /* #e0e0e0 */
        circularProgress.trackColor = UIColor.clear
        self.postPicture.addSubview(circularProgress)
        self.bringSubviewToFront(circularProgress)
        self.circularProgress.center.y = self.postPicture.center.y
        self.circularProgress.center.x = self.postPicture.center.x

    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        self.userImage.clipsToBounds = true
        self.username.layer.cornerRadius = self.username.frame.height / 3
        self.username.clipsToBounds = true
        self.fullName.layer.cornerRadius = self.fullName.frame.height / 3
        self.fullName.clipsToBounds = true
        
        
        
        self.quickLikePostBtn.backgroundColor = UIColor.clear
        self.quickLikePostBtn.setImage(UIImage(named: "likeIcon"), for: .normal)
        self.quickLikePostBtn.tintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) /* #e8e8e8 */

        

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //Stop or reset anything else that is needed here
    }

}

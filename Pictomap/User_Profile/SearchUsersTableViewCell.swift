//
//  SearchUsersTableViewCell.swift
//  Pictomap
//
//  Created by Artak on 2019-07-23.
//  Copyright © 2019 artacorp. All rights reserved.
//

import UIKit

class SearchUsersTableViewCell: UITableViewCell {

    var userImgView = UIImageView()
    var usernameLbl = UILabel()
    var fullnameLbl = UILabel()
    var stack1 = UIStackView()
    var stack2 = UIStackView()

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        

    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        stack1.translatesAutoresizingMaskIntoConstraints = false
        stack2.translatesAutoresizingMaskIntoConstraints = false
        userImgView.translatesAutoresizingMaskIntoConstraints = false
        fullnameLbl.translatesAutoresizingMaskIntoConstraints = false
        usernameLbl.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        
        stack1.axis = .horizontal
        stack2.axis = .vertical
     
        view.addSubview(userImgView)

        fullnameLbl.textColor = UIColor.init(hue: 0.206, saturation: 0.06, brightness: 0.86, alpha: 1.00)
        usernameLbl.textColor = UIColor.init(hue: 0.359, saturation: 0.00, brightness: 1.00, alpha: 1.00)

        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        fullnameLbl.font = UIFont.init(name: "Arial Rounded MT Bold", size: 18)
        usernameLbl.font = UIFont.init(name: "Arial", size: 16)

        
        userImgView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        userImgView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        userImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userImgView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        stack1.addArrangedSubview(view)
        view.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        stack2.addArrangedSubview(fullnameLbl)
        stack2.addArrangedSubview(usernameLbl)
        stack1.addArrangedSubview(stack2)
        stack1.spacing = 10
        
        contentView.addSubview(stack1)
        
        stack1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        stack1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        stack1.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        stack1.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        let b = stack1.heightAnchor.constraint(equalToConstant: 50)
        
        b.isActive = true

    }
    
    override func layoutSubviews() {
        userImgView.layer.cornerRadius = 25
        userImgView.clipsToBounds = true
    }
    
    
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


        // Configure the view for the selected state
    }

}

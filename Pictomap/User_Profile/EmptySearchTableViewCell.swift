//
//  EmptySearchTableViewCell.swift
//  Pictomap
//
//  Created by Artak on 2019-07-29.
//  Copyright © 2019 artacorp. All rights reserved.
//

import UIKit

class EmptySearchTableViewCell: UITableViewCell {

    var label = UILabel()
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        label.textColor = UIColor.init(hue: 0.359, saturation: 0.00, brightness: 1.00, alpha: 1.00)
        
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear

        label.font = UIFont.init(name: "Arial", size: 16)
        
        contentView.addSubview(view)

        
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
        // Configure the view for the selected state
    }

}

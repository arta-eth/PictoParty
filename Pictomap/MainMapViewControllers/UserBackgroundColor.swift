//
//  UserBackgroundColor.swift
//  Pictomap
//
//  Created by Artak on 2018-10-21.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class UserBackgroundColor{
    
    var primaryColor: UIColor = UIColor(hue: 211/360, saturation: 81/100, brightness: 97/100, alpha: 1.0)
    
    var secondaryColor: UIColor = UIColor(hue: 211/360, saturation: 81/100, brightness: 97/100, alpha: 1.0)


    
    var primary: UIColor{
        
        get{
            return primaryColor
        }
        set{
            primaryColor = newValue
        }
    }
    
    var secondary: UIColor{
        
        get{
            return secondaryColor
        }
        set{
            secondaryColor = newValue
        }
    }
}


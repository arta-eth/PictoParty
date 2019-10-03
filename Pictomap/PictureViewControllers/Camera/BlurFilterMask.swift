//
//  BlurFilterMask.swift
//  Pictomap
//
//  Created by Artak on 2018-10-30.
//  Copyright © 2018 artacorp. All rights reserved.
//

import Foundation
import QuartzCore

class BlurFilterMask : CALayer {
    
    private let GRADIENT_WIDTH : CGFloat = 50.0
    
    var origin : CGPoint?
    var diameter : CGFloat?
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        let clearRegionRadius : CGFloat  = self.diameter! * 0.5
        let blurRegionRadius : CGFloat  = clearRegionRadius + GRADIENT_WIDTH
        
        let baseColorSpace = CGColorSpaceCreateDeviceRGB();
        let colours : [CGFloat] = [0.0, 0.0, 0.0, 0.0,     // Clear region
            0.0, 0.0, 0.0, 0.5] // blur region color
        let colourLocations : [CGFloat] = [0.0, 0.4]
        let gradient = CGGradient (colorSpace: baseColorSpace, colorComponents: colours, locations: colourLocations, count: 2)
        
        
        ctx.drawRadialGradient(gradient!, startCenter: self.origin!, startRadius: clearRegionRadius, endCenter: self.origin!, endRadius: blurRegionRadius, options: .drawsAfterEndLocation);
        
    }
    
}

//
//  AvoidButton.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit

protocol Avo1dButtonDelegate {
    func touchDidEnd(_ button: Avo1dButton)
}

class Avo1dButton: UIButton {
    
    var selector: Selector!
    var delegate: Avo1dButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let verticalMotionEffect : UIInterpolatingMotionEffect =
            UIInterpolatingMotionEffect(keyPath: "center.y",
                                        type: .tiltAlongVerticalAxis)
        
        // Set horizontal effect
        let horizontalMotionEffect : UIInterpolatingMotionEffect =
            UIInterpolatingMotionEffect(keyPath: "center.x",
                                        type: .tiltAlongHorizontalAxis)
        
        let constant = 7
        verticalMotionEffect.minimumRelativeValue = constant
        verticalMotionEffect.maximumRelativeValue = -constant
        horizontalMotionEffect.minimumRelativeValue = constant
        horizontalMotionEffect.maximumRelativeValue = -constant
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        self.titleLabel?.addMotionEffect(group)
        self.imageView?.addMotionEffect(group)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


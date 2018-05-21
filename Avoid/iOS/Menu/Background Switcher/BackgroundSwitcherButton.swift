//
//  BackgroundSwitcherButton.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit

class BackgroundSwitcherButton: UIButton{
    
    init(frame: CGRect, center: CGPoint, image: UIImage) {
        super.init(frame: frame)
        self.setBackgroundImage(image, for: .normal)
        self.center = center
        self.layer.cornerRadius = self.frame.height / 8
        self.layer.masksToBounds = true
        self.showsTouchWhenHighlighted = true
        
        self.contentMode = .scaleAspectFit
        self.imageView?.contentMode = .scaleAspectFit
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

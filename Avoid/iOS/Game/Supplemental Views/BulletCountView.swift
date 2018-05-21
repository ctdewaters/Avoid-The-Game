//
//  BulletCountView.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit

class BulletCountView: UIView {
    var path: UIBezierPath!
    var shapeLayer: CAShapeLayer!
    var label: UILabel!
    
    init (frame: CGRect, center: CGPoint, bulletCount: Int) {
        super.init(frame: frame)
        
        path = UIBezierPath(arcCenter: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2), radius: self.frame.width / 2 + 8, startAngle: CGFloat(-M_PI / 2), endAngle: CGFloat(3 * M_PI / 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 0
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        
        shapeLayer.lineWidth = 7
        shapeLayer.lineCap = kCALineCapRound
        
        let backgroundPath = UIBezierPath(arcCenter: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2), radius: self.frame.width / 2 + (25 / 2), startAngle: CGFloat(-CGFloat.pi / 2), endAngle: CGFloat(3 * CGFloat.pi / 2), clockwise: true)
        
        let shapeBackground = CAShapeLayer()
        shapeBackground.path = backgroundPath.cgPath
        shapeBackground.strokeStart = 0
        shapeBackground.strokeEnd = 1
        shapeBackground.fillColor = UIColor.white.withAlphaComponent(0.3).cgColor
        shapeBackground.strokeColor = UIColor.clear.cgColor
        shapeBackground.zPosition = shapeLayer.zPosition - 1
        shapeBackground.lineWidth = 5
        
        self.layer.addSublayer(shapeLayer)
        self.layer.addSublayer(shapeBackground)
        
        label = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 30))
        label.text = "\(bulletCount)"
        label.center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        label.font = UIFont(name: "Ubuntu", size: 32)
        label.textColor = UIColor(rgba: "#00335b")
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor;
        label.layer.shadowOffset = CGSize(width: 0.5, height: 1);
        label.layer.shadowOpacity = 0.8;
        label.layer.shadowRadius = 2;
        self.addSubview(label)
        
        self.center = center
    }
    
    func updateProgressFromFloat(_ progress: CGFloat) {
        shapeLayer.strokeEnd = progress
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Bullet Count deallocated")
    }
}

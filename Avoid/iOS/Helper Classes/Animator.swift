//
//  Animator.swift
//  AnyScore
//
//  Created by Collin DeWaters on 6/22/15.
//  Copyright © 2015 Collin DeWaters. All rights reserved.
//

import UIKit


open class Animator: NSObject {

    func simpleAnimationForDuration(_ duration: TimeInterval, animation: (() -> Void)){
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        animation()
        UIView.commitAnimations()
    }
    
    func complexAnimationForDuration(_ duration: TimeInterval, delay: TimeInterval, animation1: @escaping (() ->Void), animation2: @escaping (() ->Void)){
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions(), animations: {
            ()->Void in
            animation1()
            }, completion: {
                Bool in
                if true{
                    animation2()
                }
        })
        
    }
    
    func caBasicAnimation(_ from: Double, to: Double, repeatCount: Float, keyPath: String, duration: CFTimeInterval) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.repeatCount = repeatCount
        animation.isRemovedOnCompletion = true
        
        return animation
    }
    
}

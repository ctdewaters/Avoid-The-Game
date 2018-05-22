//
//  UserNodePicker.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit

class UserNodePicker: UIView, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var scrollView: UIScrollView!
    var blur: UIVisualEffectView!
    
    var createOwnButton: UIButton!
    var selectedNodeButton: UIButton!
    
    var viewCenter: CGPoint!
    
    var scrollViewButtons = [UIButton]()
    
    var selectedButtonBackground: UIVisualEffectView!
    var startingSelectedCenter: CGFloat!
    
    init(frame: CGRect, center: CGPoint){
        super.init(frame: frame)
        
        scrollView = UIScrollView(frame: self.frame)
        self.addSubview(scrollView)
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        
        selectedNodeButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.height * 0.5, height: self.frame.height * 0.5))
        selectedNodeButton.center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        selectedNodeButton.addTarget(self, action: #selector(self.didSelectTexture(sender:)), for: .touchUpInside)
        self.addSubview(selectedNodeButton)
        self.bringSubview(toFront: selectedNodeButton)
        
        selectedButtonBackground = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        selectedButtonBackground.frame = CGRect(x: 0, y: 0, width: selectedNodeButton.frame.width * 1.75, height: self.frame.height)
        self.addSubview(selectedButtonBackground)
        self.bringSubview(toFront: selectedNodeButton)
        
        startingSelectedCenter = self.frame.minX + self.selectedNodeButton.frame.width / 2 + 20
        
        var currentX = scrollView.frame.minX + self.frame.height + 25
        
        //Add buttons to scrollView
        for i in 0 ..< userNodeTextures.count - 1 {
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.height * 0.5, height:  self.frame.height * 0.5))
            button.center = CGPoint(x: currentX, y: self.frame.height / 2)
            button.alpha = 0
            scrollView.addSubview(button)
            currentX += self.frame.height * 0.5 + 20
            
            button.addTarget(self, action: #selector(self.didSelectTexture(sender:)), for: UIControlEvents.touchUpInside)
            
            button.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            scrollViewButtons.append(button)
        }
        
        scrollView.contentSize = CGSize(width: CGFloat(userNodeTextures.count - 1) * ((self.frame.height * 0.5) + 40), height: self.frame.height)
        
        self.viewCenter = center
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        self.transform = CGAffineTransform(scaleX: 0, y: 0)
        self.center = center
        self.scrollView.delegate = self
        self.alpha = 0
    }
    
    func setScrollViewWithNonSelectedTextures( selectedImage: inout UIImage) {
        var count = 0
        for button in scrollViewButtons{
            
            let texture = userNodeTextures[count]
            if texture == selectedImage {
                count += 1
                button.setImage(userNodeTextures[count], for: .normal)
            }
            else {
                button.setImage(texture, for: .normal)
            }
            
            animator.simpleAnimationForDuration(0.7, animation: {
                button.transform = .identity
                button.alpha = 1
            })
            
            button.layer.add(animator.caBasicAnimation(Double(CGFloat.pi / 2), to: 0, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.7), forKey: "rotate")
            
            count += 1
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: blur)
            if self.bounds.contains(location) != true {
                self.deactivate()
            }
        }
    }
    
    @objc func didSelectTexture(sender: UIButton) {
        
        if sender != selectedNodeButton {
            
            let startingSenderCenter = sender.center.x
            let lastSelectedImage = selectedNodeButton.imageView!.image
            
            self.bringSubview(toFront: scrollView)
            self.bringSubview(toFront: selectedNodeButton)
            
            animator.simpleAnimationForDuration(0.1, animation: {
                sender.transform = .identity
            })
            
            animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
                sender.center.x = self.startingSelectedCenter - 20
                self.selectedNodeButton.center.x = startingSenderCenter + 20
            }, animation2: {
                animator.complexAnimationForDuration(0.1, delay: 0, animation1: {
                    sender.center.x = self.startingSelectedCenter
                    self.selectedNodeButton.center.x = startingSenderCenter
                }, animation2: {
                    self.selectedNodeButton.center.x = self.startingSelectedCenter
                    self.selectedNodeButton.setImage(sender.imageView!.image, for: .normal)
                    sender.center.x = startingSenderCenter
                    sender.setImage(lastSelectedImage, for: .normal)
                    self.bringSubview(toFront: self.selectedButtonBackground)
                    self.bringSubview(toFront: self.selectedNodeButton)
                    self.deactivate()
                })
            })
        }
        else {
            self.deactivate()
        }
    }
    
    func activate(withImage image: UIImage) {
        var image = image
        selectedNodeButton.setImage(image, for: UIControlState.normal)
        selectedNodeButton.center.x = self.center.x
        
        blurLowerZPositions()
        animator.complexAnimationForDuration(0.2, delay: 0, animation1: {
            self.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            self.selectedNodeButton.alpha = 1
            self.alpha = 1
        }, animation2: {
            animator.simpleAnimationForDuration(0.2, animation: {
                self.transform = .identity
                self.selectedNodeButton.center = CGPoint(x: self.frame.minX + self.selectedNodeButton.frame.width / 2 + 10, y: self.frame.height / 2)
                self.setScrollViewWithNonSelectedTextures(selectedImage: &image)
            })
        })
    }
    
    func deactivate() {
        animator.simpleAnimationForDuration(0.3, animation: {
            self.removeBlur()
            menu.userNodeButton.setImage(self.selectedNodeButton.imageView!.image, for: .normal)
            self.transform = CGAffineTransform(scaleX: 0.000000001, y: 0.0000000001)
            self.alpha = 0
            menu.savePersonalDesignChanges()
            
            for button in self.scrollViewButtons {
                button.transform = CGAffineTransform(scaleX: 0.000000001, y: 0.000000000001)
                button.alpha = 0
            }
        })
    }
    
    func blurLowerZPositions(){
        blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = UIScreen.main.bounds
        self.superview!.addSubview(blur)
        
        blur.alpha = 0
        self.superview?.bringSubview(toFront: self)
        self.layer.masksToBounds = false
        
        animator.simpleAnimationForDuration(0.35, animation: {
            self.blur.alpha = 1
        })
    }
    
    func removeBlur(){
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.blur.alpha = 0
        }, animation2: {
            self.blur.removeFromSuperview()
        })
    }
}

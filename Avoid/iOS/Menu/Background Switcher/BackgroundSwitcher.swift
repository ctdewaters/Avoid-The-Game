//
//  BackgroundSwitcher.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit
import DeviceKit

protocol BackgroundSwitcherDelegate {
    func backgroundSwitcherDidOpen()
    func backgroundSwitcherDidClose(chosenImage: UIImage)
}

///`BackgroundSwitcher`: displays the interface for selecting a new background.
class BackgroundSwitcher: UIView, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var bgSwitcherDelegate: BackgroundSwitcherDelegate!
    let backgroundNames = ["backgroundRed", "backgroundExtrudedRed", "backgroundBlue", "backgroundExtrudedBlue", "backgroundGreen", "backgroundExtrudedGreen", "backgroundYellow", "backgroundExtrudedYellow", "backgroundGray", "backgroundExtrudedGray", "background"].map{
        UIImage(named: $0)
    }
    
    var currentCenter: CGFloat!
    var blur: UIVisualEffectView!
    var scrollView: UIScrollView!
    
    let imagePicker = UIImagePickerController()
    
    var backgroundButtons = [BackgroundSwitcherButton]()
    
    var cameraButton: UIButton!
    var libraryButton: UIButton!
    
    var titleLabel: UILabel!
    
    var openPosition: CGPoint!
    var closedPosition: CGPoint!
    var chosenButton: UIButton!
    
    //MARK: - Initialization.
    init(frame: CGRect, center: CGPoint, currentBackground: UIImage, delegate: BackgroundSwitcherDelegate){
        super.init(frame: frame)
        
        scrollView = UIScrollView(frame: frame)
        self.addSubview(scrollView)
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        
        imagePicker.delegate = self
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        self.center = center
        closedPosition = center
        self.bgSwitcherDelegate = delegate
        self.scrollView.delegate = self
        self.addButtonsToScroller()
        self.addTitleLabel()
        openPosition = CGPoint(x: center.x, y: center.y - frame.height)
        
        self.alpha = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup functions.
    ///Adds title label.
    func addTitleLabel() {
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 70))
        titleLabel.textAlignment = .center
        titleLabel.text = "Change the Background"
        titleLabel.font = UIFont(name: "Audiowide", size: 20)
        titleLabel.textColor = .white
        titleLabel.center = CGPoint(x: center.x, y: scrollView.frame.minY - titleLabel.frame.height / 2)
        self.addSubview(titleLabel)
    }

    func addButtonsToScroller(){
        currentCenter = self.frame.minX + self.frame.width / 8 + 25
        
        for bg in backgroundNames{
            let button = BackgroundSwitcherButton(frame: CGRect(x: 0, y: 0, width: self.frame.width / 3.5, height: (self.frame.height - (self.frame.height / 4))), center: CGPoint(x: currentCenter, y: self.frame.height / 2 - self.frame.height / 8 + (self.frame.height * 0.03)), image: bg!)
            button.addTarget(self, action: #selector(self.newBackgroundChosen(sender:)), for: .touchUpInside)
            
            if Device() == .iPhoneX {
                button.frame.size.height -= 15
            }
            
            self.scrollView.addSubview(button)
            backgroundButtons.append(button)
            currentCenter = currentCenter + (self.frame.width / 4) + 25
        }
        
        self.scrollView.contentSize = CGSize(width: CGFloat(backgroundButtons.count) * (self.frame.width / 4 + 25) + 25, height: self.frame.height)
        
        //Add the camera button to the bottom
        cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width / 3, height: 35))
        cameraButton.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        cameraButton.layer.cornerRadius = cameraButton.frame.height / 2
        cameraButton.layer.masksToBounds = true
        cameraButton.setImage(UIImage(named: "cameraButton")!, for: .normal)
        cameraButton.setImage(UIImage(named: "cameraSelected")!, for: .highlighted)
        cameraButton.addTarget(self, action: #selector(self.showImagePicker(sender:)), for: .touchUpInside)
        cameraButton.center = CGPoint(x: self.frame.width / 2 - cameraButton.frame.width / 1.5, y: self.frame.height - cameraButton.frame.height / 1.35)
        cameraButton.imageView?.contentMode = .scaleAspectFit
        self.addSubview(cameraButton)
        self.bringSubview(toFront: cameraButton)
        
        
        //Add the library button to the bottom
        libraryButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width / 3, height: 35))
        libraryButton.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        libraryButton.layer.cornerRadius = libraryButton.frame.height / 2
        libraryButton.layer.masksToBounds = true
        libraryButton.setImage(UIImage(named: "folder")!, for: .normal)
        libraryButton.setImage(UIImage(named: "folderSelected")!, for: .highlighted)
        libraryButton.addTarget(self, action: #selector(self.showImagePicker(sender:)), for: .touchUpInside)
        libraryButton.center = CGPoint(x: self.frame.width / 2 + libraryButton.frame.width / 1.5, y: self.frame.height - libraryButton.frame.height / 1.35)
        libraryButton.imageView?.contentMode = .scaleAspectFit
        
        if Device() == .iPhoneX {
            libraryButton.frame.origin.y -= 30
            cameraButton.frame.origin.y -= 30
        }
        
        self.addSubview(libraryButton)
        self.bringSubview(toFront: libraryButton)
    }
    
    //MARK: - Animation.
    func animateIn(){
        blurLowerZPositions()
        
        animator.complexAnimationForDuration(0.5, delay: 0, animation1: {
            self.alpha = 1
            self.center = self.openPosition
        }, animation2: {
            if self.bgSwitcherDelegate != nil{
                self.bgSwitcherDelegate.backgroundSwitcherDidOpen()
            }
        })
    }
    
    func animateOut(sender: UIButton?){
        removeBlur()
        
        animator.complexAnimationForDuration(0.5, delay: 0, animation1: {
            self.alpha = 0
            self.center = self.closedPosition
        }, animation2: {
            if self.bgSwitcherDelegate != nil && sender != nil{
                self.bgSwitcherDelegate.backgroundSwitcherDidClose(chosenImage: sender!.backgroundImage(for: .normal)!)
            }
        })
    }
    
    //MARK: - Image Picker
    @objc func showImagePicker(sender: UIButton) {
        imagePicker.allowsEditing = false
        if sender == cameraButton {
            imagePicker.sourceType = .camera
        }
        else {
            imagePicker.sourceType = .photoLibrary
        }
        menu.present(imagePicker, animated: true, completion: nil)
    }
    
    //ImagePicker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.animateOut(sender: nil)
        menu.backgroundSelectorOpen = false
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        if image != menu.backgroundImage.image {
            //Change background image
            animator.complexAnimationForDuration(0.7, delay: 0, animation1: {
                menu.backgroundImage.alpha = 0
            }, animation2: {
                menu.backgroundImage.image = image
                animator.simpleAnimationForDuration(0.7, animation: {
                    menu.backgroundImage.alpha = 1
                    menu.savePersonalDesignChanges()
                })
            })
        }

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - New background setup.
    @objc func newBackgroundChosen(sender: UIButton){
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = .identity
        })
        sender.layer.add(animator.caBasicAnimation(0, to: 2 * Double.pi, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.35), forKey: "rotation")
        animateOut(sender: sender)
    }
    
    
    //MARK: - Blurring.
    func blurLowerZPositions(){
        blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = UIScreen.main.bounds
        self.superview!.addSubview(blur)
        
        blur.alpha = 0
        self.sendSubview(toBack: blur)
        self.layer.masksToBounds = false
        
        blur.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap)))
        
        animator.simpleAnimationForDuration(0.7, animation: {
            self.blur.alpha = 1
        })
    }
    
    func removeBlur(){
        animator.complexAnimationForDuration(0.7, delay: 0, animation1: {
            self.blur.alpha = 0
        }, animation2: {
            self.blur.removeFromSuperview()
        })
    }
    
    //MARK: - Tap gesture
    @objc func tap() {
        self.animateOut(sender: nil)
    }
    
    func getDistanceFromCenter(viewCenter: CGFloat)->CGFloat{
        var difference = self.frame.width / 2 - viewCenter
        
        if difference < 0{
            difference = -difference
        }
        return difference
    }
}

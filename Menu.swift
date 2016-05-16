//
//  Menu.swift
//  Avoid 2
//
//  Created by Collin DeWaters on 11/15/14.
//  Copyright (c) 2014 iInnovate LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import GameKit
import Darwin

public var animator = Animator()

protocol BackgroundSwitcherDelegate {
    func backgroundSwitcherDidOpen()
    func backgroundSwitcherDidClose(chosenImage: UIImage)
}

extension UIButton {
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(self.superview)
            if self.frame.contains(location) == true {
                self.affectViewFromForce(touch.force)
            }
            if self.frame.contains(location) != true {
                animator.simpleAnimationForDuration(0.1, animation: {
                    self.transform = CGAffineTransformMakeScale(1, 1)
                })
            }
        }
    }
    
    func affectViewFromForce(force: CGFloat) {
        let transform = 1 + (force / 16.6666)
        self.transform = CGAffineTransformMakeScale(transform, transform)
    }
}

var displayRect: CGRect!

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
    
    init(frame: CGRect, center: CGPoint, currentBackground: UIImage, delegate: BackgroundSwitcherDelegate){
        super.init(frame: frame)
        
        scrollView = UIScrollView(frame: frame)
        self.addSubview(scrollView)
        scrollView.backgroundColor = .clearColor()
        scrollView.showsHorizontalScrollIndicator = false
        
        imagePicker.delegate = self
        
        self.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        self.center = center
        closedPosition = center
        self.bgSwitcherDelegate = delegate
        self.scrollView.delegate = self
        self.addButtonsToScroller()
        self.addTitleLabel()
        openPosition = CGPointMake(center.x, center.y - frame.height)
    }
    
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
                    self.bgSwitcherDelegate.backgroundSwitcherDidClose(sender!.backgroundImageForState(.Normal)!)
                }
        })
    }
    
    func addButtonsToScroller(){
        currentCenter = CGRectGetMinX(self.frame) + self.frame.width / 8 + 25
        
        for bg in backgroundNames{
            let button = BackgroundSwitcherButton(frame: CGRectMake(0, 0, self.frame.width / 4, self.frame.height - (self.frame.height / 4)), center: CGPointMake(currentCenter, self.frame.height / 2 - self.frame.height / 8 + (self.frame.height * 0.03)), image: bg!)
            button.addTarget(self, action: Selector("newBackgroundChosen:"), forControlEvents: .TouchUpInside)
            
            self.scrollView.addSubview(button)
            backgroundButtons.append(button)
            currentCenter = currentCenter + (self.frame.width / 4) + 25
        }
        
        self.scrollView.contentSize = CGSizeMake(CGFloat(backgroundButtons.count) * (self.frame.width / 4 + 25) + 25, self.frame.height)
        
        //Add the camera button to the bottom
        cameraButton = UIButton(frame: CGRectMake(0, 0, self.frame.width / 3, 35))
        cameraButton.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        cameraButton.layer.cornerRadius = cameraButton.frame.height / 2
        cameraButton.layer.masksToBounds = true
        cameraButton.setImage(UIImage(named: "cameraButton")!, forState: .Normal)
        cameraButton.setImage(UIImage(named: "cameraSelected")!, forState: .Highlighted)
        cameraButton.addTarget(self, action: Selector("showImagePicker:"), forControlEvents: .TouchUpInside)
        cameraButton.center = CGPointMake(self.frame.width / 2 - cameraButton.frame.width / 1.5, self.frame.height - cameraButton.frame.height / 1.35)
        cameraButton.imageView?.contentMode = .ScaleAspectFit
        self.addSubview(cameraButton)
        self.bringSubviewToFront(cameraButton)
        
        
        //Add the library button to the bottom
        libraryButton = UIButton(frame: CGRectMake(0, 0, self.frame.width / 3, 35))
        libraryButton.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        libraryButton.layer.cornerRadius = libraryButton.frame.height / 2
        libraryButton.layer.masksToBounds = true
        libraryButton.setImage(UIImage(named: "folder")!, forState: .Normal)
        libraryButton.setImage(UIImage(named: "folderSelected")!, forState: .Highlighted)
        libraryButton.addTarget(self, action: Selector("showImagePicker:"), forControlEvents: .TouchUpInside)
        libraryButton.center = CGPointMake(self.frame.width / 2 + libraryButton.frame.width / 1.5, self.frame.height - libraryButton.frame.height / 1.35)
        libraryButton.imageView?.contentMode = .ScaleAspectFit
        
        self.addSubview(libraryButton)
        self.bringSubviewToFront(libraryButton)
    }
    
    func showImagePicker(sender: UIButton) {
        imagePicker.allowsEditing = true
        if sender == cameraButton {
            imagePicker.sourceType = .Camera
        }
        else {
            imagePicker.sourceType = .PhotoLibrary
        }
        menu.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //ImagePicker Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.animateOut(nil)
        menu.backgroundSelectorOpen = false
        picker.dismissViewControllerAnimated(true, completion: nil)
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
    
    //Add title label to self
    func addTitleLabel() {
        
        titleLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width, 70))
        titleLabel.textAlignment = .Center
        titleLabel.text = "Customize the Background"
        titleLabel.font = UIFont(name: "Ubuntu", size: 20)
        titleLabel.textColor = .whiteColor()
        titleLabel.center = CGPointMake(center.x, CGRectGetMinY(scrollView.frame) - titleLabel.frame.height / 2)
        
        self.addSubview(titleLabel)
        titleLabel.transform = CGAffineTransformMakeScale(0, 0)
    }
    
    func newBackgroundChosen(sender: UIButton){
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
        sender.layer.addAnimation(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.35), forKey: "rotation")
        animateOut(sender)
    }
    
    func blurLowerZPositions(){
        blur = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blur.frame = UIScreen.mainScreen().bounds
        self.superview!.addSubview(blur)
        
        blur.alpha = 0
        self.sendSubviewToBack(blur)
        self.layer.masksToBounds = false
        
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
    
    func getDistanceFromCenter(viewCenter: CGFloat)->CGFloat{
        var difference = self.frame.width / 2 - viewCenter
        
        if difference < 0{
            difference = -difference
        }
        return difference
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BackgroundSwitcherButton: UIButton{
    
    init(frame: CGRect, center: CGPoint, image: UIImage) {
        super.init(frame: frame)
        self.setBackgroundImage(image, forState: .Normal)
        self.center = center
        self.layer.cornerRadius = self.frame.height / 8
        self.layer.masksToBounds = true
        self.showsTouchWhenHighlighted = true
        
        self.contentMode = .ScaleAspectFit
        self.imageView?.contentMode = .ScaleAspectFit
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GKGameCenterViewController{
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    public override func shouldAutorotate() -> Bool {
        return false
    }
}

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
        scrollView.backgroundColor = .clearColor()
        scrollView.showsHorizontalScrollIndicator = false
        
        selectedNodeButton = UIButton(frame: CGRectMake(0, 0, self.frame.height * 0.5, self.frame.height * 0.5))
        selectedNodeButton.center = CGPointMake(self.frame.width / 2, self.frame.height / 2)
        selectedNodeButton.addTarget(self, action: Selector("didSelectTexture:"), forControlEvents: .TouchUpInside)
        self.addSubview(selectedNodeButton)
        self.bringSubviewToFront(selectedNodeButton)
        
        selectedButtonBackground = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
        selectedButtonBackground.frame = CGRectMake(0, 0, selectedNodeButton.frame.width * 1.75, self.frame.height)
        self.addSubview(selectedButtonBackground)
        self.bringSubviewToFront(selectedNodeButton)
        
        startingSelectedCenter = CGRectGetMinX(self.frame) + self.selectedNodeButton.frame.width / 2 + 20
        
        var currentX = CGRectGetMinX(scrollView.frame) + self.frame.height + 25
        
        //Add buttons to scrollView
        for var i = 0; i < userNodeTextures.count - 1; i++ {
            let button = UIButton(frame: CGRectMake(0, 0, self.frame.height * 0.5, self.frame.height * 0.5))
            button.center = CGPointMake(currentX, self.frame.height / 2)
            button.alpha = 0
            scrollView.addSubview(button)
            currentX += self.frame.height * 0.5 + 20
            
            button.addTarget(self, action: Selector("didSelectTexture:"), forControlEvents: UIControlEvents.TouchUpInside)
            
            button.transform = CGAffineTransformMakeScale(0, 0)
            
            scrollViewButtons.append(button)
        }
        
        scrollView.contentSize = CGSizeMake(CGFloat(userNodeTextures.count - 1) * ((self.frame.height * 0.5) + 40), self.frame.height)

        self.viewCenter = center
        
        self.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        self.transform = CGAffineTransformMakeScale(0, 0)
        self.center = center
        self.scrollView.delegate = self
        self.alpha = 0
    }
    
    func setScrollViewWithNonSelectedTextures(inout selectedImage: UIImage) {
        var count = 0
        for button in scrollViewButtons{
            
            let texture = userNodeTextures[count]
            if texture == selectedImage {
                count++
                button.setImage(userNodeTextures[count], forState: .Normal)
            }
            else {
                button.setImage(texture, forState: .Normal)
            }
            
            animator.simpleAnimationForDuration(0.7, animation: {
                button.transform = CGAffineTransformMakeScale(1, 1)
                button.alpha = 1
            })
            
            button.layer.addAnimation(animator.caBasicAnimation(M_PI / 2, to: 0, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.7), forKey: "rotate")
            
            count++
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(blur)
            if self.bounds.contains(location) != true {
                self.deactivate()
            }
            else {
                print("TOUCHING")
            }
        }
    }
    
    func didSelectTexture(sender: UIButton) {
        
        if sender != selectedNodeButton {
        
            let startingSenderCenter = sender.center.x
            let lastSelectedImage = selectedNodeButton.imageView!.image
        
            self.bringSubviewToFront(scrollView)
            self.bringSubviewToFront(selectedNodeButton)
        
            animator.simpleAnimationForDuration(0.1, animation: {
                sender.transform = CGAffineTransformMakeScale(1, 1)
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
                            self.selectedNodeButton.setImage(sender.imageView!.image, forState: .Normal)
                            sender.center.x = startingSenderCenter
                            sender.setImage(lastSelectedImage, forState: .Normal)
                            self.bringSubviewToFront(self.selectedButtonBackground)
                            self.bringSubviewToFront(self.selectedNodeButton)
                            self.deactivate()
                    })
            })
        }
        else {
            self.deactivate()
        }
    }
    
    func activate(var withImage image: UIImage) {
        selectedNodeButton.setImage(image, forState: UIControlState.Normal)
        selectedNodeButton.center.x = self.center.x
        
        blurLowerZPositions()
        animator.complexAnimationForDuration(0.2, delay: 0, animation1: {
            self.transform = CGAffineTransformMakeScale(1.25, 1.25)
            self.selectedNodeButton.alpha = 1
            self.alpha = 1
            }, animation2: {
                animator.simpleAnimationForDuration(0.2, animation: {
                    self.transform = CGAffineTransformMakeScale(1, 1)
                    self.selectedNodeButton.center = CGPointMake(CGRectGetMinX(self.frame) + self.selectedNodeButton.frame.width / 2 + 10, self.frame.height / 2)
                    self.setScrollViewWithNonSelectedTextures(&image)
                })
        })
    }
    
    func deactivate() {
        animator.simpleAnimationForDuration(0.3, animation: {
            self.removeBlur()
            menu.userNodeButton.setImage(self.selectedNodeButton.imageView!.image, forState: .Normal)
            self.transform = CGAffineTransformMakeScale(0.000000001, 0.0000000001)
            self.alpha = 0
            menu.savePersonalDesignChanges()
            
            for button in self.scrollViewButtons {
                button.transform = CGAffineTransformMakeScale(0.000000001, 0.000000000001)
                button.alpha = 0
            }
        })
    }
    
    func blurLowerZPositions(){
        blur = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blur.frame = UIScreen.mainScreen().bounds
        self.superview!.addSubview(blur)
        
        blur.alpha = 0
        self.superview?.bringSubviewToFront(self)
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

var menu: Menu!
var canUseGameCenter: Bool!

let userNodeTextures = ["userNodeNavy", "userNodeWhite", "userNode", "userNodePink", "userNodeYellow", "userNodeGreen"].map{
    UIImage(named: $0)!
}

class Menu: UIViewController, GKGameCenterControllerDelegate, BackgroundSwitcherDelegate{
    
    var localPlayer = GKLocalPlayer.localPlayer()
    
    @IBOutlet weak var userNodeButton: UIButton!
    @IBOutlet weak var scoresButton: UIButton!
    @IBOutlet weak var changeBackgroundButton: UIButton!
    @IBOutlet weak var avo1d: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    var backgroundSelectorOpen = false
    
    var leaderboardIdentifier: String? = nil
    var gameCenterEnabled: Bool = false
    
    @IBOutlet weak var defenseHSLabel: UILabel!
    @IBOutlet weak var timeHSLabel: UILabel!
    
    var highScore = Int()
    var timeHighScore = Double()
    var effect: UIVisualEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
    var effectView: UIVisualEffectView = UIVisualEffectView()
    
    //Gesture Recognizers
    var swipeRight: UISwipeGestureRecognizer!
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeDown: UISwipeGestureRecognizer!
    var swipeUp: UISwipeGestureRecognizer!
    
    var backgroundSelector: BackgroundSwitcher!
    
    var group: UIMotionEffectGroup!
    var userNodePicker: UserNodePicker!
    var mediaPlayer: AVPlayer!
    
    var recordGame: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if skView != nil {
            print("SKVIEW NOT NIL")
           // scene.parent?.removeFromParent()
            //scene = nil
            skView.removeFromSuperview()
            //print("Scene: \(scene), VIEW: \(skView)")
        }
        
        print("View height: \(self.view.frame.height)")
        
        addBackgroundAndStrokeToButton(playButton)
        addBackgroundAndStrokeToButton(scoresButton)
        
        playButton.showsTouchWhenHighlighted = true
        scoresButton.showsTouchWhenHighlighted = true
        
        userNodePicker = UserNodePicker(frame: CGRectMake(0, 0, self.view.frame.width, userNodeButton.frame.height * 2), center: CGPointMake(view.frame.width / 2, userNodeButton.center.y))
        self.view.addSubview(userNodePicker)
        self.view.bringSubviewToFront(userNodeButton)
        
        menu = self
        
        defenseHSLabel.transform = CGAffineTransformMakeScale(0, 0)
        timeHSLabel.transform = CGAffineTransformMakeScale(0, 0)
        timeHSLabel.superview?.transform = CGAffineTransformMakeScale(0, 0)
        timeHSLabel.superview?.layer.cornerRadius = 30
        timeHSLabel.superview?.layer.masksToBounds = true
        
        avo1d.layer.shadowColor = UIColor.whiteColor().CGColor
        avo1d.layer.shadowOffset = CGSizeMake(0, 0)
        avo1d.layer.shadowOpacity = 0.9
        avo1d.textColor = UIColor.whiteColor()
        avo1d.layer.shadowRadius = 7
        
        displayRect = self.view.frame
        
        //Load scores, login to game center
        self.loginToGameCenter()
        
        if backgroundImage.image == nil{
            backgroundImage.image = UIImage(named: "backgroundRed")
        }
        
        backgroundSelector = BackgroundSwitcher(frame: CGRectMake(0, 0, view.frame.width, view.frame.height / 2.5), center: CGPointMake(view.center.x, CGRectGetMaxY(view.frame) + (view.frame.height / 5)), currentBackground: backgroundImage.image!, delegate: self)
        backgroundSelector.layer.zPosition = 20
        
        view.addSubview(backgroundSelector)
        view.bringSubviewToFront(backgroundSelector)
        
        //Keep device from sleeping
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        backgroundImage.center = CGPointMake(self.view.frame.width / 2, self.view.frame.height / 2)
        
        //Parallax Effect
        // Set vertical effect
        let verticalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        
        // Set horizontal effect
        let horizontalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        
        for v in view.subviews as [UIView] {
            if v != backgroundImage && v != backgroundSelector {
                let constant = Int(25 + arc4random_uniform(UInt32(10)))
                verticalMotionEffect.minimumRelativeValue = -constant
                verticalMotionEffect.maximumRelativeValue = constant
                horizontalMotionEffect.minimumRelativeValue = -constant
                horizontalMotionEffect.maximumRelativeValue = constant
                group = UIMotionEffectGroup()
                group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
                v.addMotionEffect(group)
                self.view.bringSubviewToFront(v)
            }
        }
        
        loadUserDesign()
    }
    
    @IBAction func toggleRecordGame(sender: UIButton) {
        recordGame = (recordGame == true) ? false : true
        savePersonalDesignChanges()
        print(recordGame)
        
        animator.simpleAnimationForDuration(0.25, animation: {
            (self.recordGame == true) ? sender.setTitle("Rec: On", forState: .Normal) : sender.setTitle("Rec: Off", forState: .Normal)
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //Load current usernode texture
        self.loadUserDesign()
        
        var int = 0
        
        if canUseGameCenter != nil {
            if canUseGameCenter == true {
                loadHighestLocalPlayerScore("defenseHighScores")
                loadHighestLocalPlayerTime("high_Scores")
                
            }
            else {
                loadDefenseHighScoreFromCoreData()
                loadTimeHighScoreFromCoreData()
            }
        }
        
        swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        swipeDown = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeDown.direction = .Down
        self.view.addGestureRecognizer(swipeDown)
        
        swipeUp = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeUp.direction = .Up
        self.view.addGestureRecognizer(swipeUp)
        
    }
    
    @IBAction func userDidOpenNodePicker(sender: UIButton) {
        userNodePicker.center = sender.center
        userNodePicker.activate(withImage: sender.imageView!.image!)
        animator.simpleAnimationForDuration(0.3, animation: {
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
    }
    
    func addBackgroundAndStrokeToButton(button: UIButton) {
        button.layer.cornerRadius = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 64.5 : 49.5)
        button.layer.masksToBounds = true
        
        button.imageView?.transform = CGAffineTransformMakeScale(0.5, 0.5)
        
        button.layer.borderColor = UIColor(rgba: "#00335b").CGColor
        button.layer.borderWidth = 5
        button.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        
        button.setTitleColor(UIColor(rgba: "#00335b"), forState: .Highlighted)
    }
    
    //Protocol for background switcher
    func backgroundSwitcherDidOpen() {
        backgroundSelectorOpen = true
        
        animator.simpleAnimationForDuration(0.5, animation: {
            self.backgroundSelector.titleLabel.transform = CGAffineTransformMakeScale(1, 1)
        })
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.backgroundSelector.titleLabel.transform = CGAffineTransformMakeScale(1.25, 1.25)
            }, animation2: {
                animator.simpleAnimationForDuration(0.35, animation: {
                    self.backgroundSelector.titleLabel.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
    }
    
    func backgroundSwitcherDidClose(chosenImage: UIImage) {
        backgroundSelectorOpen = false
        if chosenImage != backgroundImage.image{
            //Change background image
            animator.complexAnimationForDuration(0.7, delay: 0, animation1: {
                self.backgroundImage.alpha = 0
                }, animation2: {
                    self.backgroundImage.image = chosenImage
                    animator.simpleAnimationForDuration(0.7, animation: {
                    self.backgroundImage.alpha = 1
                    self.savePersonalDesignChanges()
                })
            })
        }
        
    }
    
    @IBAction func changeBackground(sender: UIButton) {
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
        backgroundSelector.animateIn()
        view.bringSubviewToFront(backgroundSelector)
        
    }
    
    //Convert RGB to UIColor
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    

    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if backgroundSelectorOpen == false{
            
                switch swipeGesture.direction {
                case UISwipeGestureRecognizerDirection.Up:
                    if backgroundSelectorOpen == false{
                        backgroundSelectorOpen = true
                        backgroundSelector.animateIn()
                    }
                    view.bringSubviewToFront(backgroundSelector)
                
                default:
                    break
                }
            }
            
            else if swipeGesture.direction == .Down{
                backgroundSelector.animateOut(nil)
                backgroundSelectorOpen = false
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func savePersonalDesignChanges(){
        dataManager.saveObjectInEntity("Personal", objects: [UIImagePNGRepresentation(userNodeButton.imageView!.image!)!, UIImageJPEGRepresentation(backgroundImage.image!, 1)!, recordGame], keys: ["uNColor", "background", "replayKit"], deletePrevious: true)
    }
    
    func loadUserDesign(){
        let results = dataManager.loadObjectInEntity("Personal")
        
        if results!.count > 0{
            let res = results?.objectAtIndex(0) as! NSManagedObject
            let data = res.valueForKey("uNColor") as! NSData
            let bgData = res.valueForKey("background") as! NSData
            let returnedImage = UIImage(data: data)
            let returnedBackgroundImage = UIImage(data: bgData)
            
            recordGame = (res.valueForKey("replayKit") == nil) ? true : res.valueForKey("replayKit") as! Bool
            (recordGame == true) ? recordButton.setTitle("Rec: On", forState: .Normal) : recordButton.setTitle("Rec: Off", forState: .Normal)
            backgroundImage.image = returnedBackgroundImage
            userNodeButton.setImage(returnedImage, forState: .Normal)
            
        }
        else{
            backgroundImage.image = UIImage(named: "backgroundRed")
            userNodeButton.setImage(UIImage(named: "userNodeNavy"), forState: .Normal)
            recordGame = true
            recordButton.setTitle("Rec: On", forState: .Normal)
            print("No results")
        }
        recordButton.backgroundColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.5)
        recordButton.layer.cornerRadius = 15
        recordButton.layer.masksToBounds = true
    }
    
    override func shouldAutorotate() -> Bool {
       return false
    }
    
    @IBAction func goToGame(sender: UIButton) {
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
        savePersonalDesignChanges()
        self.performSegueWithIdentifier("goToGame", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        backgroundSelector = nil
        for var view: UIView in self.view.subviews {
            view.removeFromSuperview()
        }
        
        var desVC = segue.destinationViewController as! GameViewController
        desVC.highScore = Double(self.highScore)
        desVC.highestTime = Double(self.timeHighScore)
    }
    

    @IBAction func showGameCenter(sender: UIButton) {
        
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = CGAffineTransformMakeScale(1, 1)
        })
        
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        self.presentViewController(gc, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController)
    {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loadDefenseHighScoreFromCoreData(){
        //Get corner radius based on device type

        let results = dataManager.loadObjectInEntity("DefenseMode")
        
        if results!.count > 0{
            let res = results?.objectAtIndex(0) as! NSManagedObject
            highScore = res.valueForKey("defenseHighScore") as! Int
        }
        else{
            highScore = 0
            
            print("No results", terminator: "")
        }
        
        prepareHighScoreLabelWithScore(&highScore)
    }
    
    func loadTimeHighScoreFromCoreData() {
        let results = dataManager.loadObjectInEntity("Time")
        
        if results!.count > 0{
            let res = results?.objectAtIndex(0) as! NSManagedObject
            timeHighScore = res.valueForKey("timeHighScore") as! Double
        }
        else{
            timeHighScore = 0
            
            print("No results", terminator: "")
        }
        
        prepareTimeScoreLabelWithScore(&timeHighScore)
    }
    
    func prepareHighScoreLabelWithScore(inout score: Int) {
        let cornerRadius: CGFloat = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 60 : 40)
        let fontSize = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 23 : 15)
        
        defenseHSLabel.layer.cornerRadius = cornerRadius
        defenseHSLabel.layer.masksToBounds = true
        defenseHSLabel.backgroundColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.75)
        defenseHSLabel.font = UIFont(name: "Ubuntu", size: fontSize)
        
        defenseHSLabel.text = String(format: "\(score)\n\nHits")
        
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.defenseHSLabel.transform = CGAffineTransformMakeScale(1.25, 1.25)
            self.defenseHSLabel.superview?.transform = CGAffineTransformMakeScale(1, 1)
            }, animation2: {
                animator.simpleAnimationForDuration(0.05, animation: {
                    self.defenseHSLabel.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
        
    }
    
    func prepareTimeScoreLabelWithScore(inout score: Double) {
        let cornerRadius: CGFloat = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 60 : 40)
        let fontSize = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 23 : 15)
        
        timeHSLabel.layer.cornerRadius = cornerRadius
        timeHSLabel.layer.masksToBounds = true
        timeHSLabel.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        timeHSLabel.textColor = UIColor(rgba: "#00335b")
        timeHSLabel.font = UIFont(name: "Ubuntu", size: fontSize)
        
        timeHSLabel.text = "\(NSString(format: "%.01f", score) as String)\n\nSeconds"
        
        
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.timeHSLabel.transform = CGAffineTransformMakeScale(1.25, 1.25)
            self.timeHSLabel.superview?.transform = CGAffineTransformMakeScale(1, 1)
            }, animation2: {
                animator.simpleAnimationForDuration(0.05, animation: {
                    self.timeHSLabel.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
        
    }
    
    func loadHighestLocalPlayerScore (leaderboardID: String) {
        let leaderBoardRequest = GKLeaderboard()
        leaderBoardRequest.identifier = leaderboardID
        
        leaderBoardRequest.loadScoresWithCompletionHandler { (scores, error) -> Void in
            if (error != nil) {
                print("Error: \(error!.localizedDescription)")
            } else if (scores != nil) {
                if leaderBoardRequest.localPlayerScore != nil {
                    self.highScore = Int(leaderBoardRequest.localPlayerScore!.value)
                    print("Local player's score: \(self.highScore)")
                }
                else {
                    self.highScore = 0
                    print("This is the local player's first time \(self.highScore)")
                }
                self.prepareHighScoreLabelWithScore(&self.highScore)
                
            }
        }
    }
    
    func loadHighestLocalPlayerTime(leaderboardID: String) {
        let leaderBoardRequest = GKLeaderboard()
        leaderBoardRequest.identifier = leaderboardID
        
        leaderBoardRequest.loadScoresWithCompletionHandler { (scores, error) -> Void in
            if (error != nil) {
                print("Error: \(error!.localizedDescription)")
            } else if (scores != nil) {
                if leaderBoardRequest.localPlayerScore != nil {
                    self.timeHighScore = Double(leaderBoardRequest.localPlayerScore!.value) / 10.0
                    print("Local player's score: \(self.timeHighScore)")
                }
                else {
                    self.timeHighScore = 0
                    print("This is the local player's first time \(self.timeHighScore)")
                }
                
                
                self.prepareTimeScoreLabelWithScore(&self.timeHighScore)
            }
        }
    }
    

    //GameCenter login
    func loginToGameCenter() {
       var score = 0
       localPlayer.authenticateHandler = {( gameCenterVC:UIViewController?, gameCenterError:NSError?) -> Void in
       
            if gameCenterVC != nil { //not signed in
                self.presentViewController(gameCenterVC!, animated: true, completion: { () -> Void in
                    if GKLocalPlayer.localPlayer().authenticated {
                        self.loadHighestLocalPlayerScore("defenseHighScores")
                        self.loadHighestLocalPlayerScore("high_Scores")
                    }
                    else {
                        score = 0
                    }
                })
            }
                
            else { //Either declined gamecenter or is signed in
                
                if self.localPlayer.authenticated == true {//signed in
                    //self.self
                    canUseGameCenter = true
                    
                    self.loadHighestLocalPlayerScore("defenseHighScores")
                    self.loadHighestLocalPlayerTime("high_Scores")
                    
                }
                else  { // declined
                    canUseGameCenter = false
                    self.loadDefenseHighScoreFromCoreData()
                    self.loadTimeHighScoreFromCoreData()
                }
            }
        
            if gameCenterError != nil {
                print("Game Center error: \(gameCenterError)", terminator: "")
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


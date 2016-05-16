//
//  IntroViewController.swift
//  Avoid
//
//  Created by Collin DeWaters on 10/30/15.
//  Copyright © 2015 iInnovate LLC. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let fontSize = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 20 : (self.view.frame.height == 736.0) ? 16 : 12)
        let titleFontSize = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 30 : (self.view.frame.height == 736.0) ? 25 : 22)
        
        let page1 = EAIntroPage()
        page1.title = "Welcome to Avoid 2"
        page1.desc = "A lot has changed. Here's some tips to get you up and running."
        page1.descFont = UIFont(name: "Ubuntu", size: fontSize)
        page1.titleFont = UIFont(name: "Ubuntu", size: titleFontSize)
        page1.bgImage = UIImage(named: "backgroundRed")
        let imageView = UIImageView(image: UIImage(named: "intro"))
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        page1.titleIconView = imageView
        page1.titleIconView.frame.size = CGSize(width: 200, height: 200)
        page1.titleIconView.layer.borderColor = UIColor.whiteColor().CGColor
        page1.titleIconView.layer.borderWidth = 3.0
        page1.titleIconView.layer.cornerRadius = 50
        page1.titleIconView.layer.masksToBounds = true
        
        let page2 = EAIntroPage()
        page2.title = "Custom Backgrounds!"
        page2.desc = "We wanted to make Avoid 2 even more customizable, which is why you can now change the in-game background. We have provided a few ourselves, but you can also snap a photo or browse your library to personalize it to your liking! To access the switcher, just swipe up on the home screen, or press the \"Change Background\" button at the bottom of the screen."
        page2.titlePositionY = view.frame.height / 2.7
        page2.descPositionY = view.frame.height / 3
        page2.descFont = UIFont(name: "Ubuntu", size: fontSize)
        page2.titleFont = UIFont(name: "Ubuntu", size: titleFontSize)
        page2.bgImage = UIImage(named: "backgroundBlue")
        var page2ImageView = UIImageView(image: UIImage(named: "userNodeNavy")!)
        page2ImageView.contentMode = .ScaleAspectFit
        animateImageView(&page2ImageView, images: [UIImage(named: "introBackground2")!, UIImage(named: "introBackground1")!], index: 0)
        page2.titleIconView = page2ImageView
        page2.titleIconView.frame.size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        
        let page3 = EAIntroPage()
        page3.title = "Screen Recording!"
        page3.desc = "New in Avoid 2, you can now record the screen as you play! To enable screen recording, ensure that the record button on the home screen is set to \"on\". Once the game is over, you can access the recording and send it to your friends, or save it to your camera roll!"
        page3.descFont = UIFont(name: "Ubuntu", size: fontSize)
        page3.titleFont = UIFont(name: "Ubuntu", size: titleFontSize)
        page3.titlePositionY = view.frame.height / 2.7
        page3.descPositionY = view.frame.height / 3
        page3.bgImage = UIImage(named: "backgroundGreen")
        var page3ImageView = UIImageView(image: UIImage(named: "userNodeNavy")!)
        page3ImageView.contentMode = .ScaleAspectFit
        animateImageView(&page3ImageView, images: [UIImage(named: "introRecord2")!, UIImage(named: "introRecord1")!], index: 0)
        page3.titleIconView = page3ImageView
        page3.titleIconView.frame.size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        
        let page4 = EAIntroPage()
        page4.title = "How it Works"
        page4.desc = "The player has two objectives in Avoid: avoid the bullets for as long as possible, and destroy as many bullets as possible. The player starts with 15 defense bullets to shoot. If a player runs out of bullets, it takes five seconds to relead. To shoot a defense bullet, just tap the screen in the direction you wish to shoot it."
        page4.descFont = UIFont(name: "Ubuntu", size: fontSize)
        page4.titleFont = UIFont(name: "Ubuntu", size: titleFontSize)
        page4.titlePositionY = view.frame.height / 2.7
        page4.descPositionY = view.frame.height / 3
        page4.bgImage = UIImage(named: "backgroundGray")
        let page4ImageView = UIImageView(image: UIImage(named: "userNodeNavy")!)
        page4ImageView.contentMode = .ScaleAspectFit
        page4ImageView.image = UIImage(named: "introInGame")!
        page4.titleIconView = page4ImageView
        page4.titleIconView.frame.size = CGSize(width: self.view.frame.width, height: self.view.frame.width)
        
        let label = UILabel(frame: CGRect(x: 20, y: view.frame.height / 2 - 80, width: view.frame.width - 40, height: 40))
        label.text = "That's What's New."
        label.textColor = UIColor.whiteColor()
        label.textAlignment = .Center
        label.font = UIFont(name: "Ubuntu", size: 32.0)
        
        let button = UIButton(frame: CGRect(x: 30, y: view.frame.height / 2 - 20, width: view.frame.width - 60, height: 40))
        button.backgroundColor = UIColor(rgba: "#00335b")
        button.setAttributedTitle(NSAttributedString(string: "It's time to Avoid!", attributes: [NSFontAttributeName : UIFont(name: "Ubuntu", size: 20)!, NSForegroundColorAttributeName: UIColor.whiteColor()]), forState: .Normal)
        button.layer.cornerRadius = button.frame.height / 2
        button.layer.masksToBounds = true
        button.addTarget(self, action: "goHome", forControlEvents: UIControlEvents.TouchUpInside)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.view.insertSubview(label, atIndex: 0)
            self.view.insertSubview(button, atIndex: 0)
            self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundRed")!)
        }
        
        
        let introView = EAIntroView(frame: view.frame, andPages: [page1, page2, page3, page4])
        introView.limitScrollingToPage(2)
        introView.skipButton.titleLabel?.font = UIFont(name: "Ubuntu", size: 20)
        introView.showInView(view)
    }
    
    func goHome() {
        let delegate = UIApplication.sharedApplication().delegate!
        let root = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("menu")
        delegate.window!!.rootViewController = root
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Transition for image scroller
    func animateImageView(inout imageView: UIImageView, images: [UIImage], var index: Int) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.75)
        CATransaction.setCompletionBlock {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.animateImageView(&imageView, images: images, index: index)
            }
        }
        let transition = CATransition()
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionPush
        imageView.layer.addAnimation(transition, forKey: kCATransition)
        imageView.image = images[index]
        
        CATransaction.commit()
        
        //If index is less than the array.count, add by one. Else, index is set to zero.
        index = index < images.count - 1 ? index + 1 : 0
    }
    
    
}

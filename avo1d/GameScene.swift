//
//  GameScene.swift
//  avo1d
//
//  Created by Collin DeWaters on 10/26/14.
//  Copyright (c) 2014 iInnovate LLC. All rights reserved.
//

import SpriteKit
import CoreMotion
import CoreData
import GameKit
import UIKit
import ReplayKit

public extension UIColor {
    public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        if rgba.hasPrefix("#") {
            let index = rgba.startIndex.advancedBy(1)
            let hex = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

protocol GameTimerDelegate{
    func increaseDifficulty()
}

protocol GameForegroundViewDelegate {
    func menuDidSelectRecalibrate()
    func menuDidSelectResume()
    func menuDidSelectRestart()
    func menuDidSelectHome()
}

protocol Avo1dButtonDelegate {
    func touchDidEnd(button: Avo1dButton)
}

class BulletCountView: UIView {
    var path: UIBezierPath!
    var shapeLayer: CAShapeLayer!
    var label: UILabel!
    
    init (frame: CGRect, center: CGPoint, bulletCount: Int) {
        super.init(frame: frame)
        
        path = UIBezierPath(arcCenter: CGPointMake(self.frame.width / 2, self.frame.height / 2), radius: self.frame.width / 2 + 8, startAngle: CGFloat(-M_PI / 2), endAngle: CGFloat(3 * M_PI / 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 0
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.strokeColor = UIColor.whiteColor().CGColor
        
        shapeLayer.lineWidth = 7
        shapeLayer.lineCap = kCALineCapRound
        
        let backgroundPath = UIBezierPath(arcCenter: CGPointMake(self.frame.width / 2, self.frame.height / 2), radius: self.frame.width / 2 + (25 / 2), startAngle: CGFloat(-M_PI / 2), endAngle: CGFloat(3 * M_PI / 2), clockwise: true)
        
        let shapeBackground = CAShapeLayer()
        shapeBackground.path = backgroundPath.CGPath
        shapeBackground.strokeStart = 0
        shapeBackground.strokeEnd = 1
        shapeBackground.fillColor = UIColor.whiteColor().colorWithAlphaComponent(0.3).CGColor
        shapeBackground.strokeColor = UIColor.clearColor().CGColor
        shapeBackground.zPosition = shapeLayer.zPosition - 1
        shapeBackground.lineWidth = 5
        
        self.layer.addSublayer(shapeLayer)
        self.layer.addSublayer(shapeBackground)
        
        label = UILabel(frame: CGRectMake(0, 0, self.frame.width, 30))
        label.text = "\(bulletCount)"
        label.center = CGPointMake(self.frame.width / 2, self.frame.height / 2)
        label.font = UIFont(name: "Ubuntu", size: 32)
        label.textColor = UIColor(rgba: "#00335b")
        label.textAlignment = .Center
        label.layer.shadowColor = UIColor.blackColor().CGColor;
        label.layer.shadowOffset = CGSizeMake(0.5, 1);
        label.layer.shadowOpacity = 0.8;
        label.layer.shadowRadius = 2;
        self.addSubview(label)
        
        self.center = center
    }
    
    func updateProgressFromFloat(progress: CGFloat) {
        shapeLayer.strokeEnd = progress
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Bullet Count deallocated")
    }
}

class ForegroundGameView: UIView, Avo1dButtonDelegate {
    var delegate: GameForegroundViewDelegate?
    
    var resumeButton = Avo1dButton()
    var calibrateButton = Avo1dButton()
    var restartButton = Avo1dButton()
    var exitButton = Avo1dButton()
    
    var calibratedLabel = UILabel()
    
    var titleLabel: UILabel!
    
    var background: UIVisualEffectView!
    
    var selectedButton: UIButton!
    
    var scoreLabel: UILabel!
    var timeLabel: UILabel!
    
    var highScoreLabel: UILabel!
    
    var viewReplayButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        background = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        background.frame = frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showMenu(menuType: String) {
        
        self.addSubview(background)
        self.sendSubviewToBack(background)
        self.background.alpha = 0
        
        animator.simpleAnimationForDuration(0.5, animation: {
            self.alpha = 1
            self.background.alpha = 1
        })
        
        switch menuType {
        case "pause" : //Setup pause menu
            
            titleLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width, self.frame.height * 0.3))
            titleLabel.text = "Game Paused"
            titleLabel.textColor = UIColor(rgba: "#FFFFFF")
            titleLabel.font = UIFont(name: "Ubuntu", size: 40)
            titleLabel.textAlignment = .Center
            titleLabel.center = CGPointMake(self.center.x, CGRectGetMinY(self.frame) + titleLabel.frame.height / 2)
            self.addSubview(titleLabel)
            titleLabel.transform = CGAffineTransformMakeScale(0, 0)
            titleLabel.alpha = 1
            
            animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
                self.titleLabel.transform = CGAffineTransformMakeScale(1.35, 1.35)
                self.background.alpha = 1
                }, animation2: {
                    animator.simpleAnimationForDuration(0.15, animation: {
                        self.titleLabel.transform = CGAffineTransformMakeScale(1, 1)
                    })
            })
            
            setUpPauseMenu()
            
            break
        case "gameOver" :
            titleLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width, self.frame.height * 0.3))
            titleLabel.text = "Game Over"
            titleLabel.textColor = UIColor(rgba: "#FFFFFF")
            titleLabel.font = UIFont(name: "Ubuntu", size: 40)
            titleLabel.textAlignment = .Center
            titleLabel.center = CGPointMake(self.center.x, CGRectGetMinY(self.frame) + titleLabel.frame.height / 2)
            self.addSubview(titleLabel)
            titleLabel.transform = CGAffineTransformMakeScale(0, 0)
            titleLabel.alpha = 1
            
            animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
                self.titleLabel.transform = CGAffineTransformMakeScale(1.35, 1.35)
                self.background.alpha = 1
                }, animation2: {
                    animator.simpleAnimationForDuration(0.15, animation: {
                        self.titleLabel.transform = CGAffineTransformMakeScale(1, 1)
                    })
            })
            
            print("\n\n\nSHOULD SHOW GAME OVER MENU")
            
            setUpGameOverMenu()
            
            break
        default:
            break
        }
    }
    
    func displayScoreLabels(inout time: Double, timeHighScore: Bool, inout score: Int, newHighScore: Bool) {
        
        
        timeLabel = UILabel(frame: CGRectMake(0, 0, 100, 100))
        timeLabel.center = CGPointMake(self.frame.width / 2 - self.frame.width / 4.5, (self.frame.height / 2 + titleLabel.center.y) / 2)
        timeLabel.text =  "\(NSString(format: "%.01f", time) as String)\nSeconds"
        timeLabel.font = UIFont(name: "Ubuntu", size: 20)
        timeLabel.backgroundColor = UIColor.whiteColor()
        timeLabel.layer.cornerRadius = 50
        timeLabel.textColor = UIColor(rgba: "#00335b")
        timeLabel.layer.masksToBounds = true
        timeLabel.textAlignment = .Center
        timeLabel.numberOfLines = 3
        timeLabel.alpha = 0
        self.addSubview(timeLabel)
        
        scoreLabel = UILabel(frame: CGRectMake(0, 0, 100, 100))
        scoreLabel.center = CGPointMake(self.frame.width / 2 +  self.frame.width / 4.5, (self.frame.height / 2 + titleLabel.center.y) / 2)
        scoreLabel.text = "\(score)\nHits"
        scoreLabel.font = UIFont(name: "Ubuntu", size: 20)
        scoreLabel.backgroundColor = UIColor(rgba: "#00335b")
        scoreLabel.textColor = UIColor.whiteColor()
        scoreLabel.layer.cornerRadius = 50
        scoreLabel.layer.masksToBounds = true
        scoreLabel.textAlignment = .Center
        scoreLabel.numberOfLines = 3
        scoreLabel.alpha = 0
        self.addSubview(scoreLabel)
        
        if timeHighScore == true {
            timeLabel.layer.borderColor = UIColor(rgba: "#00335b").CGColor
            timeLabel.layer.borderWidth = 5
        }
        if newHighScore == true {
            scoreLabel.layer.borderColor = UIColor.whiteColor().CGColor
            scoreLabel.layer.borderWidth = 5
        }
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.scoreLabel.transform = CGAffineTransformMakeScale(1.35, 1.35)
            self.scoreLabel.alpha = 1
            self.timeLabel.transform = CGAffineTransformMakeScale(1.35, 1.35)
            self.timeLabel.alpha = 1
            }, animation2: {
                animator.simpleAnimationForDuration(0.15, animation: {
                    self.scoreLabel.transform = CGAffineTransformMakeScale(1, 1)
                    self.timeLabel.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
        
        //Finish all of this up
    }
    
    func addViewReplayButton() {
        viewReplayButton = UIButton(frame: CGRectMake(0, 0, self.frame.width * 0.3, 40))
        viewReplayButton.setTitle("View Replay", forState: .Normal)
        viewReplayButton.titleLabel?.font = UIFont(name: "Ubuntu", size: 20)
        viewReplayButton.titleLabel?.textColor = UIColor.whiteColor()
        viewReplayButton.backgroundColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.75)
        viewReplayButton.layer.cornerRadius = 20
        viewReplayButton.layer.masksToBounds = true
        viewReplayButton.center = CGPointMake(self.center.x, calibrateButton.center.y + calibrateButton.frame.height / 2 + 45)
        viewReplayButton.addTarget(nil, action: Selector("showReplay"), forControlEvents: .TouchUpInside)
        viewReplayButton.alpha = 0
        self.addSubview(viewReplayButton)
        
        animator.simpleAnimationForDuration(0.35, animation: {
            self.viewReplayButton.alpha = 1
        })
    }
    
    func showReplay() {
        animator.simpleAnimationForDuration(0.15, animation: {
            self.viewReplayButton.transform = CGAffineTransformMakeScale(1, 1)
        })
        gameVC?.presentViewController(scene!.previewViewController, animated: true, completion: nil)
    }
    
    
    func setUpMenuButton (inout button : Avo1dButton, withImage image: UIImage, atCenter center: CGPoint, withSelector selector: Selector) {
        button = Avo1dButton(frame: CGRectMake(0, 0, self.frame.width * 0.3, self.frame.width * 0.3))
        button.backgroundColor = UIColor.whiteColor()
        button.setImage(image, forState: .Normal)
        button.layer.cornerRadius = button.frame.width / 2
        button.layer.zPosition += button.frame.width
        button.layer.masksToBounds = true
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor(rgba: "#00335b").CGColor
        button.center = center
        button.addTarget(nil, action: selector, forControlEvents: UIControlEvents.TouchUpInside)
        button.transform = CGAffineTransformMakeScale(0, 0)
        button.alpha = 0
        button.delegate = self
        
        self.addSubview(button)
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            button.transform = CGAffineTransformMakeScale(1.35, 1.35)
            button.alpha = 1
            }, animation2: {
                animator.simpleAnimationForDuration(0.15, animation: {
                    button.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
    }
    
    func setCalibratedLabel () {
        calibratedLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width, 50))
        calibratedLabel.text = "Device Recalibrated"
        calibratedLabel.transform = CGAffineTransformMakeScale(0, 1)
        calibratedLabel.center = CGPointMake(self.frame.width / 2, calibrateButton.center.y + calibrateButton.frame.height / 2 + 60)
        calibratedLabel.textAlignment = .Center
        calibratedLabel.font = UIFont(name: "Ubuntu", size: 30)
        calibratedLabel.textColor = .lightTextColor()
        self.addSubview(calibratedLabel)
    }
    
    var calibrateTimer: NSTimer!
    
    func animateCalibratedLabel () {
        calibratedLabel.transform = CGAffineTransformMakeScale(0, 1)
        calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("shrinkCalibratedLabel"), userInfo: nil, repeats: false)
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.calibratedLabel.transform = CGAffineTransformMakeScale(1.25, 1)
            }, animation2: {
                animator.simpleAnimationForDuration(0.1, animation: {
                    self.calibratedLabel.transform = CGAffineTransformMakeScale(1, 1)
                })
        })
    }
    
    func shrinkCalibratedLabel () {
        animator.simpleAnimationForDuration(0.35, animation: {
            self.calibratedLabel.transform = CGAffineTransformMakeScale(0.00000001, 1)
        })
        calibrateTimer.invalidate()
    }
    
    func setUpPauseMenu () {
        setUpMenuButton(&calibrateButton, withImage: UIImage(named: "calibrateButton")!, atCenter: CGPointMake(self.frame.width / 2, CGRectGetMidY(self.frame) + self.frame.width * 0.3), withSelector: Selector("didSelectButton:"))
        setUpMenuButton(&resumeButton, withImage: UIImage(named: "resumeButton")!, atCenter: CGPointMake((self.frame.width / 2) - self.frame.width * 0.3, CGRectGetMidY(self.frame)), withSelector: Selector("didSelectButton:"))
        setUpMenuButton(&exitButton, withImage: UIImage(named: "menuButton")!, atCenter: CGPointMake((self.frame.width / 2) + self.frame.width * 0.3, CGRectGetMidY(self.frame)), withSelector: Selector("didSelectButton:"))
        setCalibratedLabel()
    }
    
    func setUpGameOverMenu () {
        setUpMenuButton(&calibrateButton, withImage: UIImage(named: "calibrateButton")!, atCenter: CGPointMake(self.frame.width / 2, CGRectGetMidY(self.frame) + self.frame.width * 0.3), withSelector: Selector("didSelectButton:"))
        setUpMenuButton(&restartButton, withImage: UIImage(named: "restartButton")!, atCenter: CGPointMake((self.frame.width / 2) - self.frame.width * 0.3, CGRectGetMidY(self.frame)), withSelector: Selector("didSelectButton:"))
        setUpMenuButton(&exitButton, withImage: UIImage(named: "menuButton")!, atCenter: CGPointMake((self.frame.width / 2) + self.frame.width * 0.3, CGRectGetMidY(self.frame)), withSelector: Selector("didSelectButton:"))
        setCalibratedLabel()
    }
    
    func didSelectButton (sender: UIButton) {
        selectedButton = sender
        
        switch sender {
        case calibrateButton :
            animateCalibratedLabel()
            delegate?.menuDidSelectRecalibrate()
        case resumeButton :
            delegate?.menuDidSelectResume()
        case exitButton :
            delegate?.menuDidSelectHome()
        case restartButton :
            delegate?.menuDidSelectRestart()
        default :
            break
        }
        
    }
    
    func animateOut() {
        self.selectedButton.layer.addAnimation(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.35), forKey: "rotateSelectedButton")
        self.selectedButton.layer.addAnimation(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.35), forKey: "rotateSelectedButtonX")
        
        animator.simpleAnimationForDuration(0.35, animation: {
            self.selectedButton.alpha = 0
            self.calibrateButton.alpha = 0
            self.exitButton.alpha = 0
            self.restartButton.alpha = 0
            self.resumeButton.alpha = 0
        })
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.selectedButton.transform = CGAffineTransformMakeScale(1.35, 1.35)
            self.background.alpha = 0
            self.scoreLabel.transform = CGAffineTransformMakeScale(0.00000000001, 0.00000000001)
            self.timeLabel.transform = CGAffineTransformMakeScale(0.00000000001, 0.00000000001)
            self.titleLabel.alpha = 0
            
            }, animation2: {
                animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
                    self.selectedButton.transform = CGAffineTransformMakeScale(0.000000001, 0.000000001)
                    }, animation2: {
                        for v in self.subviews {
                            v.removeFromSuperview()
                        }
                        self.removeFromSuperview()
                })
        })
    }
    
    //Avo1dButtonDelegate
    func touchDidEnd(button: Avo1dButton) {
        didSelectButton(button)
    }
    
}

class Avo1dButton: UIButton {
    
    var selector: Selector!
    var delegate: Avo1dButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let verticalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        
        // Set horizontal effect
        let horizontalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)

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


//Images for textures
let blueBulletImage = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("blueBullet", ofType: "png")!)
let redBulletImage = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("redBullet", ofType: "png")!)
let greenBulletImage = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("greenBullet", ofType: "png")!)
let defenseBulletImage = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("defenseBullet", ofType: "png")!)

class GameScene: SKScene, SKPhysicsContactDelegate, GameTimerDelegate, GameForegroundViewDelegate, RPPreviewViewControllerDelegate {
    
    //GameCenter Variables
    var gameCenterAchievements=[String:GKAchievement]()
    var achievementIdentifiers: Array<String> = ["20sec", "40sec", "1min", "2sf", "millisec", "2min", "90sec", "5bul", "10bul", "20bul", "40bul", "60bul"]
    
    var location = CGPoint()
    
    var timerDelegate: GameTimerDelegate!
    
    //Nodes
    var userNode: SKSpriteNode!
    var bullets: SKNode!
    var defenseBullets: SKNode?
    var defenseScore: Int?
    var scoreLabel: UILabel!
    var timeLabel: UILabel!
    var notificationLabel: SKLabelNode!
    var pauseButton: SKSpriteNode!
    var viewController: UIViewController?
    var calibY = 0.0
    var roll = CGFloat()
    var pitch = CGFloat()
    var remainingBullets = Int()
    var reloadTimer: NSTimer!
    var reloadTime = Double()
    var reloading = Bool()
    
    var recordingLabel: UILabel!
    
    //ReplayKit
    let sharedRecorder = RPScreenRecorder.sharedRecorder()
    var previewViewController: RPPreviewViewController!

    var backgroundView: UIImageView!
    
    var rPath: UIBezierPath!
    var rShapeLayer: CAShapeLayer!
    
    var shapeLayer: SKShapeNode!
    
    //CoreMotion
    var motionManager: CMMotionManager?
    var newPosition: CGPoint!
    
    var currentDifficulty = String()
    var direction = UInt32()
    var genOrNot = UInt32()
    var gameOn = Bool()
    var gamePaused = Bool()
    var bulletArray: [SKNode]!
    var defenseBulletArray: [SKNode]!
    var timer: NSTimer!
    var diffNum: UInt32!
    
    var tapLocationTarget: UIImageView!
    
    var convertedTimeInterval = NSTimeInterval()
    
    //time variables
    var highScore: Double!
    var timeHighScore: Double!
    var time = Double()
    
    //textures
    var bulletTexture: SKTexture!
    
    var colorChoose = UInt32()
    
    //Categories
    let userCategory: UInt32 = 1
    let bulletCategory: UInt32 = 0x1 << 1
    let worldCategory: UInt32 = 0x1 << 2
    let defenseBulletCategory: UInt32 = 0x1 << 3
    
    //screen bounds
    var rightBound = CGFloat()
    var leftBound = CGFloat()
    var upperBound = CGFloat()
    var bottomBound = CGFloat()
    var viewFrame = CGRect()
    var tapToBegin = Bool()
    var record: Bool!
    
    var menu: ForegroundGameView!
        
    override func didMoveToView(view: SKView) {
        
        super.didMoveToView(view)
        
        gameCenterLoadAchievements()
        
        //high scores
        self.highScore = gameVC!.highScore
        timeHighScore = gameVC!.highestTime
        
        motionManager = CMMotionManager()
        calibrateAccel()
        
        /* Setup your scene here */
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        self.physicsBody?.friction = 0
        
        defenseBulletArray = [SKNode]()
        bulletArray = [SKNode]()
        
        menu = ForegroundGameView(frame: self.frame)
        menu.delegate = self
        
        //setting screens bounds
        rightBound = view.frame.width - 7.5
        leftBound = CGRectGetMinX(view.frame) + 7.5
        upperBound = view.frame.height - 7.5
        bottomBound = CGRectGetMinY(view.frame) + 7.5
        viewFrame = view.frame
        
        loadSettingsFromCoreData()
        
        //game is not running
        gameOn = false
        
        //timer delegate
        timerDelegate = self
        
        //setting up the user node
        if upperBound > 1000{
            userNode.size = CGSizeMake(30, 30)
        }
        else{
            userNode.size = CGSizeMake(20, 20)
        }
        userNode.position = CGPointMake(rightBound / 2, bottomBound)
        userNode.physicsBody = SKPhysicsBody(circleOfRadius: userNode.size.width / 2)
        userNode.physicsBody?.dynamic = true
        userNode.physicsBody?.allowsRotation = false
        userNode.physicsBody?.categoryBitMask = userCategory
        userNode.physicsBody?.contactTestBitMask = bulletCategory
        userNode.physicsBody?.collisionBitMask = 0
        self.addChild(userNode)
        
        gamePaused = false
        
        setWelcomeScreen()
        
    }
    
    func setHighScoreAndTimeLabels(){
        
        let fontSize = CGFloat((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 23 : 17)
        
        //setting up high score label
        
        timeLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width * 0.2, self.frame.width * 0.2))
        timeLabel.center = CGPointMake(CGRectGetMinX(backgroundView.frame) + timeLabel.frame.width * 0.75, CGRectGetMaxY(backgroundView.frame) - timeLabel.frame.height * 0.75)
        timeLabel.alpha = 0.75
        timeLabel.layer.cornerRadius = self.frame.width * 0.1
        timeLabel.layer.masksToBounds = true
        timeLabel.layer.borderColor = UIColor(rgba: "#00335b").CGColor
        timeLabel.textAlignment = .Center
        timeLabel.font = UIFont(name: "Ubuntu", size: fontSize)
        timeLabel.textColor = UIColor(rgba: "#00335b")
        timeLabel.backgroundColor = .whiteColor()
        self.backgroundView.addSubview(timeLabel)
        
        //setting time label
        
        time = 0
        
        scoreLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width * 0.2, self.frame.width * 0.2))
        scoreLabel.center = CGPointMake(self.view!.center.x, CGRectGetMaxY(backgroundView.frame) - scoreLabel.frame.height * 0.75)
        scoreLabel.alpha = 0.7
        scoreLabel.layer.cornerRadius = self.frame.width * 0.1
        scoreLabel.layer.masksToBounds = true
        scoreLabel.layer.borderColor = UIColor.whiteColor().CGColor
        scoreLabel.font = UIFont(name: "Ubuntu", size: fontSize)
        scoreLabel.textAlignment = .Center
        scoreLabel.textColor = .whiteColor()
        scoreLabel.backgroundColor = UIColor(rgba: "#00335b")
        self.backgroundView.addSubview(scoreLabel)
        setGame()
    }
    
    func loadSettingsFromCoreData(){
        
        var results = dataManager.loadObjectInEntity("Personal")
        
        if results!.count > 0{
            var res = results?.objectAtIndex(0) as? NSManagedObject
            var uNColor = res!.valueForKey("uNColor") as? NSData
            var bg = res!.valueForKey("background") as? NSData
            record = res!.valueForKey("replayKit") as! Bool
            print(record)
            
            backgroundView = UIImageView(frame: self.view!.frame)
            backgroundView.image = UIImage(data: bg!)!
            backgroundView.contentMode = .ScaleAspectFill
            self.view?.superview?.addSubview(backgroundView)
            self.view?.superview?.sendSubviewToBack(backgroundView)
            
            self.view!.backgroundColor = .clearColor()
            self.backgroundColor = .clearColor()

            userNode = SKSpriteNode(texture: SKTexture(image: UIImage(data: uNColor!)!))
            
            res = nil
            uNColor = nil
            bg = nil
        }
        else{
            print("No results", terminator: "")
            userNode.texture = SKTexture(image: UIImage(named: "userNodeNavy")!)

        }
        results = nil
    }
    
    
    func setWelcomeScreen(){
        setHighScoreAndTimeLabels()
        scoreLabel.text = "0 Hits"
    }
    
    func setBulletCountView(){
        bulletCountView = BulletCountView(frame: CGRectMake(0, 0, backgroundView.frame.width * 0.333, backgroundView.frame.width * 0.333), center: backgroundView.center, bulletCount: remainingBullets)
        backgroundView.addSubview(bulletCountView)
        bulletCountView.transform = CGAffineTransformMakeScale(0, 0)
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.bulletCountView.transform = CGAffineTransformMakeScale(1, 1)
            }, animation2: {
                animator.simpleAnimationForDuration(0.75, animation: {
                    self.bulletCountView.updateProgressFromFloat(1 - 0.07)
                })
        })
    }
    
    func setGame(){
        
        if menu.selectedButton != nil {
            menu.animateOut()
        }
        
        scoreLabel.text = "0 Hits"
        
        remainingBullets = 15
        time = 0
        defenseScore = 0
        
        if notificationLabel != nil {
            notificationLabel.removeFromParent()
            notificationLabel = nil
        }
        
        notificationLabel = SKLabelNode(text: "Tap to begin!")
        notificationLabel.zPosition = 100
        notificationLabel.position = CGPointMake(rightBound / 2, upperBound / 2)
        notificationLabel.alpha = 0.75
        notificationLabel.fontColor = SKColor.whiteColor()
        notificationLabel.fontSize = 25
        notificationLabel.fontName = "Ubuntu-Light"
        
        let returnToRegularSize = SKAction.scaleXTo(1, y: 1, duration: 0.2)
        userNode.runAction(returnToRegularSize)
        userNode.removeActionForKey("pulsate")
        
        let moveToCenter: SKAction = SKAction.moveTo(CGPoint(x: rightBound / 2, y: upperBound / 2), duration: 0.5)
        userNode.runAction(moveToCenter)
        
        tapToBegin = true
        
        if notificationLabel.parent == nil{
            self.addChild(notificationLabel)
        }
    }
    
    var calibrateTimer: NSTimer!
    
    func calibrateAccel(){
        motionManager!.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler:{
            deviceManager, error in
            self.calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("stopUpdates"), userInfo: nil, repeats: false)
            
            self.calibY = self.motionManager!.deviceMotion!.attitude.pitch
            print(self.calibY)
        })
    }
    
    func stopUpdates(){
        self.motionManager!.stopDeviceMotionUpdates()
        if calibrateTimer != nil {
            calibrateTimer.invalidate()
            calibrateTimer = nil
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        for touch: AnyObject in touches {
            location = touch.locationInNode(self)
            
            //Pause and menu interfacing
            if tapToBegin == true{ //user just opened game or pressed restart
                self.startGame()
            }
                
            else if gameOn == true && gamePaused == false{ //game is on (user pausing game or tapping to move node)
                if pauseButton.containsPoint(location){
                    self.pauseGame()
                }
                else {
                    
                    if remainingBullets > 0{ //Shoot a defense bullet
                        generateAndShootDefenseBullet(location)
                    }
                    
                    if remainingBullets == 0 && pauseButton.frame.contains(location) != true{//ran out of defense bullets
                        
                        if (bulletCountView != nil || bulletCountView.superview != nil) && reloadTimer == nil{
                            
                            reloadTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("decreaseReloadTime"), userInfo: nil, repeats: true)
                            setReloadingAnimation()
                        }
                    }
                }
            }
        }
    }
    
    var bulletCountView: BulletCountView!
    
    
    func setReloadingAnimation(){
        reloading = true
        
        bulletCountView.label.layer.addAnimation(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.35), forKey: "rotateUp")
        
        bulletCountView.label.font = UIFont(name: "Ubuntu", size: 22)
        bulletCountView.label.text = "Reloading"
        
    }
    
    func decreaseReloadTime(){
        reloadTime = reloadTime + 0.1
        
        print("RELOADING\n\n\n")
        
        let timeRatio = CGFloat(reloadTime / 5)
        
        animator.simpleAnimationForDuration(0.1, animation: {
            self.bulletCountView.updateProgressFromFloat(timeRatio)
        })
        
        print(reloadTime, terminator: "")
        if reloadTime >= 5.0{
            reloadTimer.invalidate()
            reloadTimer = nil
            reloadTime = 0
            
            reloading = false
            remainingBullets = 15
            
            bulletCountView.label.layer.addAnimation(animator.caBasicAnimation(2 * M_PI, to: 0, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.35), forKey: "rotateDown")
            bulletCountView.label.font = UIFont(name: "Ubuntu", size: 22)
            bulletCountView.label.text = "\(remainingBullets)"
            
        }
    }
    
    //Defense bullets
    func generateAndShootDefenseBullet(loc: CGPoint){
        if pauseButton.frame.contains(location) == false && gamePaused == false && gameOn == true && tapToBegin == false{
            
            let defenseBullet = SKSpriteNode(color: UIColor.blackColor(), size: CGSize(width: 20, height: 7))
            defenseBullet.texture = SKTexture(image: defenseBulletImage!)
            
            let emmiter = SKEmitterNode(fileNamed: "DefenseParticle.sks")
            emmiter?.targetNode = scene
            defenseBullet.addChild(emmiter!)
            
            defenseBullet.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: defenseBullet.size.width - 3, height: defenseBullet.size.height))
            defenseBullet.physicsBody?.categoryBitMask = defenseBulletCategory
            defenseBullet.physicsBody?.contactTestBitMask = bulletCategory | defenseBulletCategory
            defenseBullet.physicsBody?.collisionBitMask = 0
            defenseBullet.physicsBody?.allowsRotation = true
            defenseBullet.physicsBody?.friction = 0
            defenseBullet.position = userNode.position
            defenseBullet.alpha = 0
            defenseBullets!.addChild(defenseBullet)
            defenseBulletArray.append(defenseBullet)
            let fadeIn = SKAction.fadeInWithDuration(0.25)
            let rotateBullet = SKAction.rotateByAngle(rotateBulletToCorrectAngle(location, node: userNode.position), duration: 0.001)
            //Vectors
            let bulletVector = lineOfBullet(location, node: userNode.position)
            let recoil = CGVector(dx: bulletVector.dx * -0.025, dy: bulletVector.dy * -0.025)
            
            let shootBullet = SKAction.moveBy(bulletVector, duration: 5)
            let group = SKAction.group([fadeIn, shootBullet])
            let shoot = SKAction.sequence([rotateBullet, group])
            defenseBullet.runAction(shoot)
            
            let recoilAction = SKAction.moveBy(recoil, duration: 0.2)
            
            userNode.runAction(recoilAction)
            
            //Update bulletcountview
            remainingBullets -= 1
            print("\n\(self.bulletCountView.shapeLayer.strokeEnd - CGFloat(1 / 15))\n")
            animator.simpleAnimationForDuration(0.75, animation: {
                self.bulletCountView.updateProgressFromFloat(self.bulletCountView.shapeLayer.strokeEnd - CGFloat(0.07))
            })
            if remainingBullets == 0 {
                self.bulletCountView.updateProgressFromFloat(0)
                setReloadingAnimation()
                
            }
            else{
                bulletCountView.label.layer.addAnimation(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.3), forKey: "rotateBulletCountLabel")
                bulletCountView.label.text = "\(remainingBullets)"
            }
            
            generateTapNode(atLocation: loc)
        }
    }
    
    func generateTapNode(atLocation loc: CGPoint) {
        let tapPath = UIBezierPath(arcCenter: loc, radius: CGFloat((self.frame.width * 0.15) / 2), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        
        let shape = SKShapeNode(path: tapPath.CGPath, centered: true)
        shape.zPosition = userNode.zPosition + 5
        shape.fillColor = SKColor.clearColor()
        shape.strokeColor = SKColor.whiteColor().colorWithAlphaComponent(0.7)
        shape.setScale(0)
        shape.lineWidth = 3
        shape.position = loc
        self.addChild(shape)
        
    
        let grow = SKAction.scaleTo(1.3, duration: 0.4)
        let shrink = SKAction.scaleTo(1, duration: 0.1)
        let fadeOut = SKAction.fadeOutWithDuration(0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([grow, shrink, fadeOut, remove])
        shape.runAction(sequence)
    }
    
    func rotateBulletToCorrectAngle(loc: CGPoint, node: CGPoint)-> CGFloat{
        let xOffset = loc.x - node.x
        let yOffset = loc.y - node.y
        let angle = atan(yOffset/xOffset)
        return CGFloat(angle)
    }
    
    func lineOfBullet(loc: CGPoint, node:CGPoint) -> CGVector{
        let xForce = loc.x - node.x
        let yForce = loc.y - node.y
        let actualForce:CGFloat = 3000
        let degreeOfForce = atan(yForce/xForce)
        
        let opposite = sin(degreeOfForce) * actualForce
        let adjacent = cos(degreeOfForce) * actualForce
        
        var force = CGVector(dx: adjacent, dy: opposite)
        if loc.x < node.x{
            force.dx = -adjacent
            force.dy = -opposite
        }
        return force
    }
    
    func startGame(){
        defenseBullets = SKNode()
        self.addChild(defenseBullets!)
        setBulletCountView()
        bullets = SKNode()
        bullets.speed = 1
        self.addChild(bullets)
        
        if sharedRecorder.available == true && record == true{
            print("\n\n\nWE WILL RECORD THIS TIME\n\n\n\n")
            sharedRecorder.startRecordingWithMicrophoneEnabled(false , handler: { (error: NSError?) in
                if error != nil {
                    //pause game and show error
                    print(error)
                    self.pauseGame()
                }
                else {
                    self.recordingLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width * 0.15, 35))
                    self.recordingLabel.text = "•REC"
                    self.recordingLabel.textAlignment = .Center
                    self.recordingLabel.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
                    self.recordingLabel.layer.cornerRadius = 35 / 2
                    self.recordingLabel.layer.masksToBounds = true
                    self.recordingLabel.font = UIFont(name: "Ubuntu", size: 23)
                    self.recordingLabel.textColor = .redColor()
                    self.recordingLabel.center = CGPointMake(CGRectGetMaxX(self.backgroundView.frame) - self.recordingLabel.frame.width / 2 - 5, CGRectGetMinY(self.backgroundView.frame) + 25)
                    self.backgroundView.addSubview(self.recordingLabel)
                }
            })
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("increaseTime"), userInfo: nil, repeats: true)
        
        userNode.physicsBody = SKPhysicsBody(circleOfRadius: userNode.size.width / 2)
        userNode.speed = 1
    
        diffNum = 98
        
        notificationLabel.removeFromParent()
        gameOn = true
        tapToBegin = false
        
        gamePaused = false
        
        pauseButton = SKSpriteNode(imageNamed: "pauseButton")
        pauseButton.size = CGSizeMake(self.frame.width * 0.2, self.frame.width * 0.2)
        pauseButton.position = CGPointMake(CGRectGetMaxX(backgroundView.frame) - pauseButton.frame.width * 0.75, CGRectGetMinY(backgroundView.frame) + pauseButton.frame.height * 0.75)
        pauseButton.zPosition = 100
        pauseButton.alpha = 0
        self.addChild(pauseButton)
            
        let pulseOut = SKAction.fadeAlphaTo(0.4, duration: 0.75)
        let pulseIn = SKAction.fadeInWithDuration(0.75)
        let combo = SKAction.sequence([pulseIn, pulseOut])
        let repeatAction = SKAction.repeatActionForever(combo)
        pauseButton.runAction(repeatAction, withKey: "pauseRepeat")
        
        if pauseButton != nil{
            animator.simpleAnimationForDuration(0.5, animation: {
                self.pauseButton.alpha = 1
            })
        }
    }
    
    func pauseGame(){
        if gameOn == true{
            
            timer.invalidate()
            
            gamePaused = true
            if pauseButton != nil {
                UIView.animateWithDuration(0.5, animations: {
                    self.pauseButton.alpha = 0
                    }, completion: { (value: Bool) in
                        self.pauseButton.removeFromParent()
                        self.pauseButton.removeActionForKey("pauseRepeat")
                        self.pauseButton = nil
                })
            }
            
            bullets.speed = 0
            defenseBullets?.speed = 0
            
            if reloading == true{
                if reloadTimer != nil {
                    reloadTimer.invalidate()
                }
                
                if bulletCountView != nil {
                    
                    animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
                        self.bulletCountView.transform = CGAffineTransformMakeScale(0, 0)
                        }, animation2: {
                            self.bulletCountView.removeFromSuperview()
                    })
                    
                }
                
            }
          self.view?.addSubview(menu)
          menu.showMenu("pause")
          menu.displayScoreLabels(&time, timeHighScore: (time > timeHighScore) ? true : false, score: &defenseScore!, newHighScore: (Double(defenseScore!) > highScore) ? true : false)
        }
    }
    
    func resumeGame(){
        
        menu.animateOut()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("increaseTime"), userInfo: nil, repeats: true)
                
            pauseButton = SKSpriteNode(imageNamed: "pauseButton")
            pauseButton.size = CGSizeMake(self.frame.width * 0.2, self.frame.width * 0.2)
            pauseButton.position = CGPointMake(CGRectGetMaxX(backgroundView.frame) - pauseButton.frame.width * 0.75, CGRectGetMinY(backgroundView.frame) + pauseButton.frame.height * 0.75)
            pauseButton.zPosition = 100
            pauseButton.alpha = 0
            self.addChild(pauseButton)
        
        if pauseButton != nil {
            animator.simpleAnimationForDuration(0.5, animation: {
                self.pauseButton.alpha = 1
            })
        }
        
        gamePaused = false
        bullets.speed = 1
        defenseBullets?.speed = 1
        userNode.speed = 1
        
        if reloading == true {
            reloadTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("decreaseReloadTime"), userInfo: nil, repeats: true)
            setReloadingAnimation()
        }
        
    }
    
    var timeScoreAchieved = false
    
    func increaseTime(){
        time += 0.1
        timeLabel.text = NSString(format: "%.01f", time) as String
        
        if time > timeHighScore && timeLabel.layer.borderWidth == 0 && timeScoreAchieved == false {
            timeLabel.layer.addAnimation(animator.caBasicAnimation(0, to: 5, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "increaseBorder")
            timeLabel.layer.borderWidth = 5
            timeScoreAchieved = true
        }
        
        if divisibleBy10(CGFloat(time)) == true{
            timerDelegate.increaseDifficulty()
        }
    }
    
    func divisibleBy10(n: CGFloat) -> Bool{
        return n % 10 == 0 || 0 - (n % 10) <= 0.1 && 0 - (n % 10) >= -0.1
    }
    
    func increaseDifficulty() {
        diffNum = diffNum - 2
        
        print("difficulty INCREASED!!!!!!!! ")
    }
    
    func moveUserNode(){
        if motionManager!.accelerometerAvailable == true{
            motionManager!.deviceMotionUpdateInterval = 0.001
            
            motionManager!.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler:{
                deviceManager, error in
                
                if self.gameOn == true && self.gamePaused == false{
                    
                    self.roll = CGFloat(self.motionManager!.deviceMotion!.attitude.roll)
                    self.pitch = CGFloat(-self.motionManager!.deviceMotion!.attitude.pitch) + CGFloat(self.calibY)
                    
                    //Keep userNode on screen
                    
                    self.newPosition = CGPointMake(self.userNode.position.x + (CGFloat(self.roll) * 20) , self.userNode.position.y + (CGFloat(self.pitch) * 20))
                    self.userNode.position = self.newPosition
                    
                }
                else if (self.gameOn == false || self.gamePaused == true) && self.motionManager != nil{
                    self.motionManager!.stopDeviceMotionUpdates()
                }
            })
        }
    }
    
    func keepUserNodeOnScreen(){
        if userNode.position.x >= rightBound{
            userNode.position.x = rightBound
            
        }
        if userNode.position.x <= leftBound{
            userNode.position.y = userNode.position.y
            userNode.position.x = leftBound
        }
        if userNode.position.y >= upperBound{
            userNode.position.x = userNode.position.x
            userNode.position.y = upperBound
        }
        if userNode.position.y <= bottomBound{
            userNode.position.x = userNode.position.x
            userNode.position.y = bottomBound
        }
        
    }
    
    func generateAndShootBullets(){
        //difficulty increases by increacing probability of generation
        
        //1= right 2= top 3= left 4= bottom
        direction = arc4random_uniform(4) + 1
        
        genOrNot = arc4random_uniform(100)
        
        //random starting point
        let ranY: CGFloat = CGFloat(arc4random_uniform(UInt32(self.frame.height)))
        let ranX: CGFloat = CGFloat(arc4random_uniform(UInt32(self.frame.width)))
        
        //Random speed
        let ranSpeed = Double(arc4random_uniform(5) + 2)
        
        let remove = SKAction.removeFromParent()
        
        //random gen:
        if genOrNot > diffNum{
            
            //Scaling
            let scale = CGFloat(0.9 + Double(arc4random_uniform(30) / 100))
            
            colorChoose = arc4random_uniform(3)
            
            self.chooseBulletTexture()
            let bullet: SKSpriteNode = SKSpriteNode()
            bullet.texture = bulletTexture
            if upperBound > 1000{
                bullet.size = CGSize(width: scale * bulletTexture.size().width / 20, height: scale * bulletTexture.size().height / 20)
            }
            else{
                bullet.size = CGSize(width: scale * bulletTexture.size().width / 30, height: scale * bulletTexture.size().height / 30)
            }
            
            bullet.position = (direction == 1) ? CGPointMake(rightBound + (bullet.size.width / 2), ranY) : (direction == 2) ? CGPointMake(ranX, upperBound + (bullet.size.width / 2)) : (direction == 3) ? CGPointMake(leftBound - (bullet.size.width / 2), ranY) : CGPointMake(ranX, bottomBound - (bullet.size.width / 2))

            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
            bullet.physicsBody?.dynamic = true
            bullet.physicsBody?.allowsRotation = false
            bulletArray.append(bullet)
            bullet.physicsBody?.categoryBitMask = bulletCategory
            bullet.physicsBody?.contactTestBitMask = userCategory
            bullet.physicsBody?.collisionBitMask = 4294967295 | defenseBulletCategory
            bullets.addChild(bullet)
            
            //Shoot action
            let shoot = SKAction.moveTo((direction == 1) ? CGPointMake(leftBound - 25, ranY) : (direction == 2) ? CGPointMake(ranX, bottomBound - 25) : (direction == 3) ? CGPointMake(rightBound + 25, ranY) : CGPointMake(ranX, upperBound + 25), duration: ranSpeed)
            
            let rotate = SKAction.rotateByAngle(CGFloat(M_PI / 2), duration: 0.0000001)
            let shootAndRemove = (direction == 2 || direction == 4) ? SKAction.sequence([rotate, shoot, remove]) : SKAction.sequence([shoot, remove])
            
            bullet.runAction(shootAndRemove)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
            
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == bulletCategory && secondBody.categoryBitMask == 4294967295{//Bullet hit userNode
            self.gameOverAnimation(userNode.position)
            self.gameOver()
        }
            
        else if firstBody.categoryBitMask == bulletCategory && secondBody.categoryBitMask == defenseBulletCategory{//Player shot a bullet
            explosionAnimation(firstBody.node!.position)
            firstBody.node?.removeFromParent()
            defenseScore = defenseScore! + 1
            scoreLabel.text = "\(defenseScore!) Hits"
            
            if defenseScore > Int(highScore) && scoreLabel.layer.borderWidth == 0{
                scoreLabel.layer.addAnimation(animator.caBasicAnimation(0, to: 5, repeatCount: 0, keyPath: "borderWidth", duration: 0.25), forKey: "increaseBorder")
                scoreLabel.layer.borderWidth = 5
            }
        }
            
        else if firstBody.categoryBitMask == defenseBulletCategory && secondBody.categoryBitMask == defenseBulletCategory{//Defense bullets collided
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
        }
    }
    
    func explosionAnimation(pos: CGPoint){
        var explosion = SKShapeNode(circleOfRadius: 25)
        self.addChild(explosion)
        explosion.position = pos
        explosion.setScale(0)
        explosion.fillColor = UIColor.whiteColor()

        let grow = SKAction.scaleTo(1.5, duration: 0.25)
        let shrink = SKAction.scaleTo(0, duration: 0.25)
        let fadeOut = SKAction.fadeAlphaTo(0, duration: 0.25)
        let group = SKAction.group([shrink, fadeOut])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([grow, group, remove])
        
        explosion.runAction(sequence)
    }
    
    func gameOverAnimation(pos: CGPoint){
        explosionAnimation(pos)
        let pulsateOut = SKAction.scaleXTo(2, y: 2, duration: 0.25)
        let pulsateIn = SKAction.scaleXTo(1, y: 1, duration: 0.25)
        let unSeq = SKAction.sequence([pulsateOut, pulsateIn])
        let `repeat` = SKAction.repeatActionForever(unSeq)
        userNode.runAction(`repeat`, withKey: "pulsate")
        
    }
    
    func chooseBulletTexture(){
        if colorChoose == 1{
            bulletTexture = SKTexture(image: blueBulletImage!)
        }
        else if colorChoose == 2{
            bulletTexture = SKTexture(image: greenBulletImage!)
        }
        else{
            bulletTexture = SKTexture(image: redBulletImage!)
        }
    }
    
    //Save new defense high score
    func saveDefenseHighScore(){
        dataManager.saveObjectInEntity("DefenseMode", objects: [defenseScore!], keys: ["defenseHighScore"], deletePrevious: true)
    }
    
    func saveTimeHighScore() {
        dataManager.saveObjectInEntity("Time", objects: [time], keys: ["timeHighScore"], deletePrevious: true)
    }
    
    //ReplayKit RPPreviewViewControllerDelegate
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        previewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func previewController(previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        
    }
    
    //runs when user loses a game
    func gameOver(){
        
        self.view?.addSubview(menu)
        menu.showMenu("gameOver")
        menu.displayScoreLabels(&time, timeHighScore: (time > timeHighScore) ? true : false, score: &defenseScore!, newHighScore: (Double(defenseScore!) > highScore) ? true : false)
        
        timeLabel.layer.borderWidth = 0
        scoreLabel.layer.borderWidth = 0
        
        scoreLabel.layer.addAnimation(animator.caBasicAnimation(5, to: 0, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "shrink")
        timeLabel.layer.addAnimation(animator.caBasicAnimation(5, to: 0, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "shrink")
        
        timer.invalidate()
        timer = nil
        
        checkAchievements()
        gameOn = false
        if pauseButton != nil{
            UIView.animateWithDuration(0.5, animations: {
                self.pauseButton.alpha = 0
                }, completion: { (value: Bool) in
                    self.pauseButton.removeFromParent()
                    self.pauseButton.removeActionForKey("pauseRepeat")
                    self.pauseButton = nil
            })
        }
        
        if reloadTimer != nil {
            reloadTimer.invalidate()
            reloadTimer = nil
        }

        if bulletCountView != nil {
            animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
                self.bulletCountView.transform = CGAffineTransformMakeScale(0.00000001, 0.0000000001)
                }, animation2: {
                    self.bulletCountView.removeFromSuperview()
            })
            
        }
        
        reloadTime = 0
        
        userNode.physicsBody = SKPhysicsBody(circleOfRadius: userNode.size.width / 2)
        userNode.physicsBody?.allowsRotation = false
        bullets.speed = 0
        
        //Remove all children and actions in the bullet array
        bullets.removeAllActions()
        bullets.removeAllChildren()
        removeChildrenAndActionsInArray(&bulletArray!)
        bullets.removeFromParent()
        bullets = nil
        
        
        defenseBullets!.removeAllActions()
        defenseBullets!.removeAllChildren()
        removeChildrenAndActionsInArray(&defenseBulletArray!)
        defenseBullets!.removeFromParent()
        defenseBullets = nil
        
        if sharedRecorder.available == true && record == true && sharedRecorder.recording == true{
            recordingLabel.removeFromSuperview()
            recordingLabel = nil
            sharedRecorder.stopRecordingWithHandler({
                (previewVC: RPPreviewViewController?, error: NSError?) -> Void in
                if previewVC != nil {
                    self.previewViewController = previewVC!
                    self.previewViewController.previewControllerDelegate = self
                    self.menu.addViewReplayButton()
                }
            })
        }
        
        if Double(defenseScore!) > highScore{
            self.reportScore(score: defenseScore!, leaderboardIdentifier: "defenseHighScores")
            highScore = Double(defenseScore!)
            self.saveDefenseHighScore()
        }
        if time > timeHighScore {
            self.reportScore(score: Int(time * 10), leaderboardIdentifier: "high_Scores")
            timeHighScore = time
            self.saveTimeHighScore()
        }
        else {
            previewViewController = nil
        }
        time = 0
    }
    
    func removeChildrenAndActionsInArray(inout array: [SKNode]) {
        for a in array {
            a.removeAllChildren()
            a.removeAllActions()
        }
        self.removeChildrenInArray(array)
        array.removeAll()
    }

    //GameCenter
    func checkAchievements(){
        gameCenterLoadAchievements()
        
        
        if time >= 20{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[0] )
        }
        if time >= 40{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[1])
        }
        if time >= 60{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[2])
        }
        if time >= 90{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[6])
        }
        if time >= 120{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[5])
        }
        if time <= 2{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[3])
        }
        if (time % 1 == 0) {
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[4])
        }
    
        if defenseScore >= 5{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[7])
        }
        if defenseScore >= 10{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[8])
        }
        if defenseScore >= 20{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[9])
        }
        if defenseScore >= 40{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[10])
        }
        if defenseScore >= 60{
            addProgressToAnAchievement(progress: 100, achievementIdentifier: achievementIdentifiers[11])
        }
    
    }
    
    func reportScore(score uScore: Int,leaderboardIdentifier uleaderboardIdentifier: String ) {
        let scoreReporter = GKScore(leaderboardIdentifier: uleaderboardIdentifier)
        scoreReporter.value = Int64(uScore)
        let scoreArray: [GKScore] = [scoreReporter]
        GKScore.reportScores(scoreArray, withCompletionHandler: {(error : NSError?) -> Void in
            if error != nil {
                NSLog(error!.localizedDescription)
            }
            else{
                print("New high score: \(uScore) submitted to Game Center", terminator: "")
            }
        })
    }
    
    func gameCenterLoadAchievements(){
        /* load all prev. achievements for GameCenter for the user to progress can be added */
        
        GKAchievement.loadAchievementsWithCompletionHandler({ (allAchievements: [GKAchievement]?, error: NSError?) -> Void in
            if error != nil{
                print("Game Center: could not load achievements, error: \(error)", terminator: "")
            } else {
                if allAchievements != nil{
                    for anAchievement in allAchievements!  {
                        self.gameCenterAchievements[anAchievement.identifier!] = anAchievement
                        print(anAchievement, terminator: "")
                    }
                }
            }
        })
        
    }
    
    /**
    If achievement is Finished
    - parameter achievementIdentifier:
    */  
    
    func isAchievementFinished(achievementIdentifier uAchievementId:String) -> Bool{
        let lookupAchievement:GKAchievement? = gameCenterAchievements[uAchievementId]
        if let achievement = lookupAchievement {
            if achievement.percentComplete == 100 {
                return true
            }
        } else {
            gameCenterAchievements[uAchievementId] = GKAchievement(identifier: uAchievementId)
            return isAchievementFinished(achievementIdentifier: uAchievementId)
        }
        return false
    }
    
    /**
    Add progress to an achievement
    
    - parameter Progress: achievement Double (ex: 10% = 10.00)
    - parameter ID: Achievement
    */
    
    func addProgressToAnAchievement(progress uProgress:Double,achievementIdentifier uAchievementId:String) {
        let lookupAchievement:GKAchievement? = gameCenterAchievements[uAchievementId]
        
        if let achievement = lookupAchievement {
            if achievement.percentComplete != 100 {
                achievement.percentComplete = uProgress
                
                if uProgress == 100.0  {
                    /* show banner only if achievement is fully granted (progress is 100%) */
                    achievement.showsCompletionBanner=true
                }
                
                /* try to report the progress to the Game Center */
                GKAchievement.reportAchievements([achievement], withCompletionHandler:  {(error:NSError?) -> Void in
                    if error != nil {
                        print("Couldn't save achievement (\(uAchievementId)) progress to \(uProgress) %", terminator: "")
                    }
                })
            }
            /* Is Finish */
        } else {
            /* never added  progress for this achievement, create achievement now, recall to add progress */
            print("No achievement with ID (\(uAchievementId)) was found, no progress for this one was recoreded yet. Create achievement now.", terminator: "")
            gameCenterAchievements[uAchievementId] = GKAchievement(identifier: uAchievementId)
            /* recursive recall this func now that the achievement exist */
            addProgressToAnAchievement(progress: uProgress, achievementIdentifier: uAchievementId)
        }
    }
    
    func resetAchievements(achievementIdentifier uAchievementId:String) {
        let lookupAchievement:GKAchievement? = gameCenterAchievements[uAchievementId]
        
        if let achievement = lookupAchievement {
            GKAchievement.resetAchievementsWithCompletionHandler({ (error:NSError?) -> Void in
                if error != nil {
                    print("Couldn't Reset achievement (\(uAchievementId))", terminator: "")
                } else {
                    print("Reset achievement (\(uAchievementId))", terminator: "")
                }
            })
            
        } else {
            print("No achievement with ID (\(uAchievementId)) was found, no progress for this one was recoreded yet. Create achievement now.", terminator: "")
            gameCenterAchievements[uAchievementId] = GKAchievement(identifier: uAchievementId)
            /* recursive recall this func now that the achievement exist */
            self.resetAchievements(achievementIdentifier: uAchievementId)
        }
    }
    
    /**
    Remove All Achievements
    */
    func resetAllAchievements() {
        
        for lookupAchievement in gameCenterAchievements {
            let achievementID = lookupAchievement.0
            let lookupAchievement:GKAchievement? =  lookupAchievement.1
            
            if let achievement = lookupAchievement {
                GKAchievement.resetAchievementsWithCompletionHandler({ (error:NSError?) -> Void in
                    if error != nil {
                        print("Couldn't Reset achievement (\(achievementID))", terminator: "")
                    } else {
                        print("Reset achievement (\(achievementID))", terminator: "")
                    }
                })
                
            } else {
                print("No achievement with ID (\(achievementID)) was found, no progress for this one was recoreded yet. Create achievement now.", terminator: "")
                gameCenterAchievements[achievementID] = GKAchievement(identifier: achievementID)
                /* recursive recall this func now that the achievement exist */
                self.resetAchievements(achievementIdentifier: achievementID)
            }
        }
    }
    
    func returnToMainMenu(){
        
        for child in self.children {
            child.removeAllActions()
            child.removeAllChildren()
            child.removeFromParent()
        }
        
        defenseBullets?.removeAllChildren()
        defenseBullets?.removeAllActions()
        defenseBullets?.removeFromParent()
        
        if bullets != nil {
            bullets.removeAllActions()
            bullets.removeAllChildren()
            bullets.removeFromParent()
        }
        
        self.deallocateAllProperties()
        
        print( "DB : \(defenseBullets) Bullets: \(bullets)")
        
        menu.animateOut()
        menu = nil
        
        if motionManager != nil{
           motionManager!.stopDeviceMotionUpdates()
        }
    
        self.removeAllActions()
        self.removeAllChildren()
        
        motionManager = nil
        
        gameVC!.performSegueWithIdentifier("menu", sender: self)
    }
    
    func deallocateAllProperties () {
        
        userNode.removeActionForKey("pulsate")

        print(userNode = nil,
        bullets = nil,
        defenseBullets = nil,
        defenseScore = nil,
        scoreLabel = nil,
        reloadTimer = nil,
        timer = nil,
        timeLabel = nil,
        notificationLabel = nil,
        pauseButton = nil)
        
        bulletCountView.removeFromSuperview()
        backgroundView.removeFromSuperview()
        bulletCountView = nil
        backgroundView = nil
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if gameOn == true && gamePaused == false{
            self.moveUserNode()
            self.generateAndShootBullets()
            self.keepUserNodeOnScreen()
        }
    }
    
    deinit {
        print("SKSCENE DEINITIALIZED")
        
    }
    
    
    
    
    
    //GameForegroundViewDelegate
    
    func menuDidSelectHome() {
        self.returnToMainMenu()
    }
    
    func menuDidSelectRestart() {
        self.setGame()
    }
    
    func menuDidSelectRecalibrate() {
        self.calibrateAccel()
    }
    
    func menuDidSelectResume() {
        self.resumeGame()
    }
    
}
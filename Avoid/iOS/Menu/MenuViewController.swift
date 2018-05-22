//
//  Menu.swift
//  Avoid 2
//
//  Created by Collin DeWaters on 11/15/14.
//  Copyright (c) 2014 Collin DeWaters. All rights reserved.
//
import UIKit
import CoreData
import AVFoundation
import GameKit
import Darwin

public var animator = Animator()

var menu: MenuViewController!
var canUseGameCenter: Bool!

let userNodeTextures = ["userNodeNavy", "userNodeWhite", "userNode", "userNodePink", "userNodeYellow", "userNodeGreen"].map{
    UIImage(named: $0)!
}

class MenuViewController: UIViewController, GKGameCenterControllerDelegate, BackgroundSwitcherDelegate{
    
    //MARK: - IBOutlets.
    @IBOutlet weak var userNodeButton: UIButton!
    @IBOutlet weak var scoresButton: UIButton!
    @IBOutlet weak var changeBackgroundButton: UIButton!
    @IBOutlet weak var avo1d: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var defenseHSLabel: UILabel!
    @IBOutlet weak var timeHSLabel: UILabel!
    
    //MARK: - Properties.
    var localPlayer = GKLocalPlayer.localPlayer()
    var backgroundSelectorOpen = false
    var leaderboardIdentifier: String? = nil
    var gameCenterEnabled: Bool = false
    var highScore = Int()
    var timeHighScore = Double()
    var effect: UIVisualEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
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
    
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if skView != nil {
           // scene.parent?.removeFromParent()
            //scene = nil
            skView.removeFromSuperview()
            //print("Scene: \(scene), VIEW: \(skView)")
        }
        
        
        self.addBackgroundAndStrokeToButton(button: playButton)
        self.addBackgroundAndStrokeToButton(button: scoresButton)
        
        userNodePicker = UserNodePicker(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: userNodeButton.frame.height * 2), center: CGPoint(x: view.frame.width / 2, y: userNodeButton.center.y))
        self.view.addSubview(userNodePicker)
        self.view.bringSubview(toFront: userNodeButton)
        
        menu = self
        
        defenseHSLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        timeHSLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
        timeHSLabel.superview?.transform = CGAffineTransform(scaleX: 0, y: 0)
        timeHSLabel.superview?.layer.cornerRadius = 30
        timeHSLabel.superview?.layer.masksToBounds = true
        
        avo1d.layer.shadowColor = UIColor.white.cgColor
        avo1d.layer.shadowOffset = CGSize(width: 0, height: 0)
        avo1d.layer.shadowOpacity = 0.9
        avo1d.textColor = UIColor.white
        avo1d.layer.shadowRadius = 7
                
        //Load scores, login to game center
        self.loginToGameCenter()
        
        if backgroundImage.image == nil{
            backgroundImage.image = UIImage(named: "backgroundRed")
        }
        
        backgroundSelector = BackgroundSwitcher(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2.5), center: CGPoint(x: view.center.x, y: view.frame.maxY + (view.frame.height / 5)), currentBackground: backgroundImage.image!, delegate: self)
        backgroundSelector.layer.zPosition = 20
        
        view.addSubview(backgroundSelector)
        view.bringSubview(toFront: backgroundSelector)
        
        //Keep device from sleeping
        UIApplication.shared.isIdleTimerDisabled = false
        
        backgroundImage.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        
        //Parallax Effect
        // Set vertical effect
        let verticalMotionEffect : UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        
        // Set horizontal effect
        let horizontalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.x",
                                    type: .tiltAlongHorizontalAxis)
        
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
                self.view.bringSubview(toFront: v)
            }
        }
        
        loadUserDesign()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Load current usernode texture
        self.loadUserDesign()
                
        if canUseGameCenter != nil {
            if canUseGameCenter == true {
                loadHighestLocalPlayerScore(leaderboardID: "defenseHighScores")
                loadHighestLocalPlayerTime(leaderboardID: "high_Scores")
                
            }
            else {
                loadDefenseHighScoreFromCoreData()
                loadTimeHighScoreFromCoreData()
            }
        }
        
        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        swipeLeft = UISwipeGestureRecognizer(target: self, action:  #selector(self.respondToSwipeGesture(gesture:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        swipeDown = UISwipeGestureRecognizer(target: self, action:  #selector(self.respondToSwipeGesture(gesture:)))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        swipeUp = UISwipeGestureRecognizer(target: self, action:  #selector(self.respondToSwipeGesture(gesture:)))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
    }
    
    @IBAction func toggleRecordGame(sender: UIButton) {
        recordGame = (recordGame == true) ? false : true
        savePersonalDesignChanges()
        print(recordGame)
        
        animator.simpleAnimationForDuration(0.25, animation: {
            (self.recordGame == true) ? sender.setTitle("Rec: On", for: .normal) : sender.setTitle("Rec: Off", for: .normal)
            sender.transform = .identity
        })
        
        
    }
    
    @IBAction func userDidOpenNodePicker(sender: UIButton) {
        userNodePicker.center = sender.center
        userNodePicker.activate(withImage: sender.imageView!.image!)
        animator.simpleAnimationForDuration(0.3, animation: {
            sender.transform = .identity
        })
    }
    
    func addBackgroundAndStrokeToButton(button: UIButton) {
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        
        button.setTitleColor(UIColor(rgba: "#00335b"), for: .highlighted)
    }
    
    //Protocol for background switcher
    func backgroundSwitcherDidOpen() {
        backgroundSelectorOpen = true
        
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
            sender.transform = .identity
        })
        backgroundSelector.animateIn()
        view.bringSubview(toFront: backgroundSelector)
        
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
    

    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if backgroundSelectorOpen == false{
            
                switch swipeGesture.direction {
                case UISwipeGestureRecognizerDirection.up:
                    if backgroundSelectorOpen == false{
                        backgroundSelectorOpen = true
                        backgroundSelector.animateIn()
                    }
                    view.bringSubview(toFront: backgroundSelector)
                
                default:
                    break
                }
            }
            
            else if swipeGesture.direction == .down{
                backgroundSelector.animateOut(sender: nil)
                backgroundSelectorOpen = false
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func savePersonalDesignChanges(){
        dataManager.saveObjectInEntity("Personal", objects: [UIImagePNGRepresentation(userNodeButton.imageView!.image!)! as NSObject, UIImageJPEGRepresentation(backgroundImage.image!, 1)! as NSObject, recordGame as! NSObject], keys: ["uNColor", "background", "replayKit"], deletePrevious: true)
    }
    
    func loadUserDesign(){
        let results = dataManager.loadObjectInEntity("Personal")
        
        if results!.count > 0{
            let res = results?.object(at: 0) as! NSManagedObject
            let data = res.value(forKey: "uNColor") as! NSData
            let bgData = res.value(forKey: "background") as! NSData
            let returnedImage = UIImage(data: data as Data)
            let returnedBackgroundImage = UIImage(data: bgData as Data)
            
            recordGame = (res.value(forKey: "replayKit") == nil) ? true : res.value(forKey: "replayKit") as! Bool
            (recordGame == true) ? recordButton.setTitle("Rec: On", for: .normal) : recordButton.setTitle("Rec: Off", for: .normal)
            backgroundImage.image = returnedBackgroundImage
            userNodeButton.setImage(returnedImage, for: .normal)
            
        }
        else{
            backgroundImage.image = UIImage(named: "backgroundRed")
            userNodeButton.setImage(UIImage(named: "userNodeNavy"), for: .normal)
            recordGame = true
            recordButton.setTitle("Rec: On", for: .normal)
            print("No results")
        }
        recordButton.backgroundColor = UIColor(rgba: "#00335b").withAlphaComponent(0.5)
        recordButton.layer.cornerRadius = 15
        recordButton.layer.masksToBounds = true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func goToGame(sender: UIButton) {
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = .identity
        })
        savePersonalDesignChanges()
        self.performSegue(withIdentifier: "goToGame", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        backgroundSelector = nil
        for var view: UIView in self.view.subviews {
            view.removeFromSuperview()
        }
        
        var desVC = segue.destination as! GameViewController
        desVC.highScore = Double(self.highScore)
        desVC.highestTime = Double(self.timeHighScore)
    }
    

    @IBAction func showGameCenter(sender: UIButton) {
        
        animator.simpleAnimationForDuration(0.1, animation: {
            sender.transform = .identity
        })
        
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        self.present(gc, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController)
    {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func loadDefenseHighScoreFromCoreData(){
        //Get corner radius based on device type
        let results = dataManager.loadObjectInEntity("DefenseMode")
        
        if results!.count > 0{
            let res = results?.object(at: 0) as! NSManagedObject
            highScore = res.value(forKey: "defenseHighScore") as! Int
        }
        else{
            highScore = 0
            
            print("No results", terminator: "")
        }
        
        prepareHighScoreLabelWithScore(score: &highScore)
    }
    
    func loadTimeHighScoreFromCoreData() {
        let results = dataManager.loadObjectInEntity("Time")
        
        if results!.count > 0{
            let res = results?.object(at: 0) as! NSManagedObject
            timeHighScore = res.value(forKey: "timeHighScore") as! Double
        }
        else{
            timeHighScore = 0
            
            print("No results", terminator: "")
        }
        
        prepareTimeScoreLabelWithScore(score: &timeHighScore)
    }
    
    func prepareHighScoreLabelWithScore( score: inout Int) {
        let cornerRadius: CGFloat = CGFloat((UIDevice.current.userInterfaceIdiom == .pad) ? 60 : 40)
        let fontSize = CGFloat((UIDevice.current.userInterfaceIdiom == .pad) ? 23 : 15)
        
        defenseHSLabel.layer.cornerRadius = cornerRadius
        defenseHSLabel.layer.masksToBounds = true
        defenseHSLabel.backgroundColor = UIColor(rgba: "#00335b").withAlphaComponent(0.75)
        defenseHSLabel.font = UIFont(name: "Rubik", size: fontSize)
        
        defenseHSLabel.text = String(format: "\(score)\nHits")
        
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.defenseHSLabel.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            self.defenseHSLabel.superview?.transform = .identity
            }, animation2: {
                animator.simpleAnimationForDuration(0.05, animation: {
                    self.defenseHSLabel.transform = .identity
                })
        })
        
    }
    
    func prepareTimeScoreLabelWithScore( score: inout Double) {
        let cornerRadius: CGFloat = CGFloat((UIDevice.current.userInterfaceIdiom == .pad) ? 60 : 40)
        let fontSize = CGFloat((UIDevice.current.userInterfaceIdiom == .pad) ? 23 : 15)
        
        timeHSLabel.layer.cornerRadius = cornerRadius
        timeHSLabel.layer.masksToBounds = true
        timeHSLabel.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        timeHSLabel.textColor = UIColor(rgba: "#00335b")
        timeHSLabel.font = UIFont(name: "Rubik", size: fontSize)
        
        timeHSLabel.text = "\(NSString(format: "%.01f", score) as String)\nSeconds"
        
        
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.timeHSLabel.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            self.timeHSLabel.superview?.transform = .identity
            }, animation2: {
                animator.simpleAnimationForDuration(0.05, animation: {
                    self.timeHSLabel.transform = .identity
                })
        })
        
    }
    
    
    //MARK: - Game Center.
    func loadHighestLocalPlayerScore (leaderboardID: String) {
        let leaderBoardRequest = GKLeaderboard()
        leaderBoardRequest.identifier = leaderboardID
        
        leaderBoardRequest.loadScores { (scores, error) -> Void in
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
                self.prepareHighScoreLabelWithScore(score: &self.highScore)
                
            }
        }
    }
    
    func loadHighestLocalPlayerTime(leaderboardID: String) {
        let leaderBoardRequest = GKLeaderboard()
        leaderBoardRequest.identifier = leaderboardID
        
        leaderBoardRequest.loadScores { (scores, error) -> Void in
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
                
                
                self.prepareTimeScoreLabelWithScore(score: &self.timeHighScore)
            }
        }
    }
    

    //GameCenter login
    func loginToGameCenter() {
       var score = 0
       localPlayer.authenticateHandler = {( gameCenterVC: UIViewController?, gameCenterError: Error?) -> Void in
       
            if gameCenterVC != nil { //not signed in
                self.present(gameCenterVC!, animated: true, completion: { () -> Void in
                    if GKLocalPlayer.localPlayer().isAuthenticated {
                        self.loadHighestLocalPlayerScore(leaderboardID: "defenseHighScores")
                        self.loadHighestLocalPlayerScore(leaderboardID: "high_Scores")
                    }
                    else {
                        score = 0
                    }
                })
            }
                
            else { //Either declined gamecenter or is signed in
                
                if self.localPlayer.isAuthenticated == true {//signed in
                    //self.self
                    canUseGameCenter = true
                    
                    self.loadHighestLocalPlayerScore(leaderboardID: "defenseHighScores")
                    self.loadHighestLocalPlayerTime(leaderboardID: "high_Scores")
                    
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

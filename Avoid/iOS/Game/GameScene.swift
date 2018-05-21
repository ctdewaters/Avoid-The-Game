//
//  GameScene.swift
//  avo1d
//
//  Created by Collin DeWaters on 10/26/14.
//  Copyright (c) 2014 Collin DeWaters. All rights reserved.
//

import SpriteKit
import CoreMotion
import CoreData
import GameKit
import UIKit
import ReplayKit

protocol GameTimerDelegate{
    func increaseDifficulty()
}

//Bullet textures
let blueBulletImage = UIImage(named: "blueBullet")
let redBulletImage = UIImage(named: "redBullet")
let greenBulletImage = UIImage(named: "greenBullet")
let defenseBulletImage = UIImage(named: "defenseBullet")

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
    var reloadTimer: Timer!
    var reloadTime = Double()
    var reloading = Bool()
    
    var recordingLabel: UILabel!
    
    //ReplayKit
    let sharedRecorder = RPScreenRecorder.shared()
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
    var timer: Timer!
    var diffNum: UInt32!
    
    var tapLocationTarget: UIImageView!
    
    var convertedTimeInterval = TimeInterval()
    
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
        
    override func didMove(to view: SKView) {
        
        super.didMove(to: view)
        
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
        leftBound = view.frame.minX + 7.5
        upperBound = view.frame.height - 7.5
        bottomBound = view.frame.minY + 7.5
        viewFrame = view.frame
        
        loadSettingsFromCoreData()
        
        //game is not running
        gameOn = false
        
        //timer delegate
        timerDelegate = self
        
        //setting up the user node
        if upperBound > 1000{
            userNode.size = CGSize(width: 30, height: 30)
        }
        else{
            userNode.size = CGSize(width: 20, height: 20)
        }
        userNode.position = CGPoint(x: rightBound / 2, y: bottomBound)
        userNode.physicsBody = SKPhysicsBody(circleOfRadius: userNode.size.width / 2)
        userNode.physicsBody?.isDynamic = true
        userNode.physicsBody?.allowsRotation = false
        userNode.physicsBody?.categoryBitMask = userCategory
        userNode.physicsBody?.contactTestBitMask = bulletCategory
        userNode.physicsBody?.collisionBitMask = 0
        self.addChild(userNode)
        
        gamePaused = false
        
        setWelcomeScreen()
        
    }
    
    func setHighScoreAndTimeLabels(){
        
        let fontSize = CGFloat((UIDevice.current.userInterfaceIdiom == .pad) ? 23 : 17)
        
        //setting up high score label
        
        timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.2, height: self.frame.width * 0.2))
        timeLabel.center = CGPoint(x: backgroundView.frame.minX + timeLabel.frame.width * 0.75, y: backgroundView.frame.maxY - timeLabel.frame.height * 0.75)
        timeLabel.alpha = 0.75
        timeLabel.layer.cornerRadius = self.frame.width * 0.1
        timeLabel.layer.masksToBounds = true
        timeLabel.layer.borderColor = UIColor(rgba: "#00335b").cgColor
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont(name: "Rubik", size: fontSize)
        timeLabel.textColor = UIColor(rgba: "#00335b")
        timeLabel.backgroundColor = .white
        self.backgroundView.addSubview(timeLabel)
        
        //setting time label
        
        time = 0
        
        scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.2, height: self.frame.width * 0.2))
        scoreLabel.center = CGPoint(x: self.view!.center.x, y: backgroundView.frame.maxY - scoreLabel.frame.height * 0.75)
        scoreLabel.alpha = 0.7
        scoreLabel.layer.cornerRadius = self.frame.width * 0.1
        scoreLabel.layer.masksToBounds = true
        scoreLabel.layer.borderColor = UIColor.white.cgColor
        scoreLabel.font = UIFont(name: "Audiowide", size: fontSize)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = .white
        scoreLabel.backgroundColor = UIColor(rgba: "#00335b")
        self.backgroundView.addSubview(scoreLabel)
        setGame()
    }
    
    func loadSettingsFromCoreData(){
        
        var results = dataManager.loadObjectInEntity("Personal")
        
        if results!.count > 0{
            var res = results?.object(at: 0) as? NSManagedObject
            var uNColor = res!.value(forKey: "uNColor") as? Data
            var bg = res!.value(forKey: "background") as? Data
            record = res!.value(forKey: "replayKit") as! Bool
            print(record)
            
            backgroundView = UIImageView(frame: self.view!.frame)
            backgroundView.image = UIImage(data: bg!)!
            backgroundView.contentMode = .scaleAspectFill
            self.view?.superview?.addSubview(backgroundView)
            self.view?.superview?.sendSubview(toBack: backgroundView)
            
            self.view!.backgroundColor = .clear
            self.backgroundColor = .clear

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
        bulletCountView = BulletCountView(frame: CGRect(x: 0, y: 0, width: backgroundView.frame.width * 0.333, height: backgroundView.frame.width * 0.333), center: backgroundView.center, bulletCount: remainingBullets)
        backgroundView.addSubview(bulletCountView)
        bulletCountView.transform = CGAffineTransform(scaleX: 0, y: 0)
        animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.bulletCountView.transform = CGAffineTransform(scaleX: 1, y: 1)
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
        notificationLabel.position = CGPoint(x: rightBound / 2, y: upperBound / 2)
        notificationLabel.alpha = 0.75
        notificationLabel.fontColor = SKColor.white
        notificationLabel.fontSize = 20
        notificationLabel.fontName = "Audiowide"
        
        let returnToRegularSize = SKAction.scaleX(to: 1, y: 1, duration: 0.2)
        userNode.run(returnToRegularSize)
        userNode.removeAction(forKey: "pulsate")
        
        let moveToCenter: SKAction = SKAction.move(to: CGPoint(x: rightBound / 2, y: upperBound / 2), duration: 0.5)
        userNode.run(moveToCenter)
        
        tapToBegin = true
        
        if notificationLabel.parent == nil{
            self.addChild(notificationLabel)
        }
    }
    
    var calibrateTimer: Timer!
    
    func calibrateAccel(){
        motionManager!.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler:{
            deviceManager, error in
            self.calibrateTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(GameScene.stopUpdates), userInfo: nil, repeats: false)
            
            self.calibY = self.motionManager!.deviceMotion!.attitude.pitch
            print(self.calibY)
        })
    }
    
    @objc func stopUpdates(){
        self.motionManager!.stopDeviceMotionUpdates()
        if calibrateTimer != nil {
            calibrateTimer.invalidate()
            calibrateTimer = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        for touch: AnyObject in touches {
            location = touch.location(in: self)
            
            //Pause and menu interfacing
            if tapToBegin == true{ //user just opened game or pressed restart
                self.startGame()
            }
                
            else if gameOn == true && gamePaused == false{ //game is on (user pausing game or tapping to move node)
                if pauseButton.contains(location){
                    self.pauseGame()
                }
                else {
                    
                    if remainingBullets > 0{ //Shoot a defense bullet
                        generateAndShootDefenseBullet(location)
                    }
                    
                    if remainingBullets == 0 && pauseButton.frame.contains(location) != true{//ran out of defense bullets
                        
                        if (bulletCountView != nil || bulletCountView.superview != nil) && reloadTimer == nil{
                            
                            reloadTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GameScene.decreaseReloadTime), userInfo: nil, repeats: true)
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
        
        bulletCountView.label.layer.add(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.35), forKey: "rotateUp")
        
        bulletCountView.label.font = UIFont(name: "Audiowide", size: 22)
        bulletCountView.label.text = "Reloading"
        
    }
    
    @objc func decreaseReloadTime(){
        reloadTime = reloadTime + 0.1
                
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
            
            bulletCountView.label.layer.add(animator.caBasicAnimation(2 * M_PI, to: 0, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.35), forKey: "rotateDown")
            bulletCountView.label.font = UIFont(name: "Audiowide", size: 22)
            bulletCountView.label.text = "\(remainingBullets)"
            
        }
    }
    
    //Defense bullets
    func generateAndShootDefenseBullet(_ loc: CGPoint){
        if pauseButton.frame.contains(location) == false && gamePaused == false && gameOn == true && tapToBegin == false{
            
            let defenseBullet = SKSpriteNode(color: UIColor.black, size: CGSize(width: 20, height: 7))
            defenseBullet.texture = SKTexture(image: defenseBulletImage!)
            
            let emmiter = SKEmitterNode(fileNamed: "DefenseParticle.sks")
            emmiter?.targetNode = scene
            defenseBullet.addChild(emmiter!)
            
            defenseBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: defenseBullet.size.width - 3, height: defenseBullet.size.height))
            defenseBullet.physicsBody?.categoryBitMask = defenseBulletCategory
            defenseBullet.physicsBody?.contactTestBitMask = bulletCategory | defenseBulletCategory
            defenseBullet.physicsBody?.collisionBitMask = 0
            defenseBullet.physicsBody?.allowsRotation = true
            defenseBullet.physicsBody?.friction = 0
            defenseBullet.position = userNode.position
            defenseBullet.alpha = 0
            defenseBullets!.addChild(defenseBullet)
            defenseBulletArray.append(defenseBullet)
            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let rotateBullet = SKAction.rotate(byAngle: rotateBulletToCorrectAngle(location, node: userNode.position), duration: 0.001)
            //Vectors
            let bulletVector = lineOfBullet(location, node: userNode.position)
            let recoil = CGVector(dx: bulletVector.dx * -0.025, dy: bulletVector.dy * -0.025)
            
            let shootBullet = SKAction.move(by: bulletVector, duration: 5)
            let group = SKAction.group([fadeIn, shootBullet])
            let shoot = SKAction.sequence([rotateBullet, group])
            defenseBullet.run(shoot)
            
            let recoilAction = SKAction.move(by: recoil, duration: 0.2)
            
            userNode.run(recoilAction)
            
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
                bulletCountView.label.layer.add(animator.caBasicAnimation(0, to: 2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.3), forKey: "rotateBulletCountLabel")
                bulletCountView.label.text = "\(remainingBullets)"
            }
            
            generateTapNode(atLocation: loc)
        }
    }
    
    func generateTapNode(atLocation loc: CGPoint) {
        let tapPath = UIBezierPath(arcCenter: loc, radius: CGFloat((self.frame.width * 0.15) / 2), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        
        let shape = SKShapeNode(path: tapPath.cgPath, centered: true)
        shape.zPosition = userNode.zPosition + 5
        shape.fillColor = SKColor.clear
        shape.strokeColor = SKColor.white.withAlphaComponent(0.7)
        shape.setScale(0)
        shape.lineWidth = 3
        shape.position = loc
        self.addChild(shape)
        
    
        let grow = SKAction.scale(to: 1.3, duration: 0.4)
        let shrink = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([grow, shrink, fadeOut, remove])
        shape.run(sequence)
    }
    
    func rotateBulletToCorrectAngle(_ loc: CGPoint, node: CGPoint)-> CGFloat{
        let xOffset = loc.x - node.x
        let yOffset = loc.y - node.y
        let angle = atan(yOffset/xOffset)
        return CGFloat(angle)
    }
    
    func lineOfBullet(_ loc: CGPoint, node:CGPoint) -> CGVector{
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
        
        if sharedRecorder.isAvailable == true && record == true{
            print("\n\n\nWE WILL RECORD THIS TIME\n\n\n\n")
            sharedRecorder.startRecording(withMicrophoneEnabled: false , handler: { (error: Error?) in
                DispatchQueue.main.async {
                    if error != nil {
                        //pause game and show error
                        print(error)
                        self.pauseGame()
                    }
                    else {
                        self.recordingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.15, height: 35))
                        self.recordingLabel.text = "•REC"
                        self.recordingLabel.textAlignment = .center
                        self.recordingLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                        self.recordingLabel.layer.cornerRadius = 35 / 2
                        self.recordingLabel.layer.masksToBounds = true
                        self.recordingLabel.font = UIFont(name: "Rubik", size: 23)
                        self.recordingLabel.textColor = .red
                        self.recordingLabel.center = CGPoint(x: self.backgroundView.frame.maxX - self.recordingLabel.frame.width / 2 - 5, y: self.backgroundView.frame.minY + 25)
                        self.backgroundView.addSubview(self.recordingLabel)
                    }
                }
            })
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GameScene.increaseTime), userInfo: nil, repeats: true)
        
        userNode.physicsBody = SKPhysicsBody(circleOfRadius: userNode.size.width / 2)
        userNode.speed = 1
    
        diffNum = 98
        
        notificationLabel.removeFromParent()
        gameOn = true
        tapToBegin = false
        
        gamePaused = false
        
        pauseButton = SKSpriteNode(imageNamed: "pauseButton")
        pauseButton.size = CGSize(width: self.frame.width * 0.2, height: self.frame.width * 0.2)
        pauseButton.position = CGPoint(x: backgroundView.frame.maxX - pauseButton.frame.width * 0.75, y: backgroundView.frame.minY + pauseButton.frame.height * 0.75)
        pauseButton.zPosition = 100
        pauseButton.alpha = 0
        self.addChild(pauseButton)
            
        let pulseOut = SKAction.fadeAlpha(to: 0.4, duration: 0.75)
        let pulseIn = SKAction.fadeIn(withDuration: 0.75)
        let combo = SKAction.sequence([pulseIn, pulseOut])
        let repeatAction = SKAction.repeatForever(combo)
        pauseButton.run(repeatAction, withKey: "pauseRepeat")
        
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
                UIView.animate(withDuration: 0.5, animations: {
                    self.pauseButton.alpha = 0
                    }, completion: { (value: Bool) in
                        self.pauseButton.removeFromParent()
                        self.pauseButton.removeAction(forKey: "pauseRepeat")
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
                        self.bulletCountView.transform = CGAffineTransform(scaleX: 0, y: 0)
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
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GameScene.increaseTime), userInfo: nil, repeats: true)
                
            pauseButton = SKSpriteNode(imageNamed: "pauseButton")
            pauseButton.size = CGSize(width: self.frame.width * 0.2, height: self.frame.width * 0.2)
            pauseButton.position = CGPoint(x: backgroundView.frame.maxX - pauseButton.frame.width * 0.75, y: backgroundView.frame.minY + pauseButton.frame.height * 0.75)
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
            reloadTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GameScene.decreaseReloadTime), userInfo: nil, repeats: true)
            setReloadingAnimation()
        }
        
    }
    
    var timeScoreAchieved = false
    
    @objc func increaseTime(){
        time += 0.1
        timeLabel.text = NSString(format: "%.01f", time) as String
        
        if time > timeHighScore && timeLabel.layer.borderWidth == 0 && timeScoreAchieved == false {
            timeLabel.layer.add(animator.caBasicAnimation(0, to: 5, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "increaseBorder")
            timeLabel.layer.borderWidth = 5
            timeScoreAchieved = true
        }
        
        if divisibleBy10(CGFloat(time)) == true{
            timerDelegate.increaseDifficulty()
        }
    }
    
    func divisibleBy10(_ n: CGFloat) -> Bool{
        return n.truncatingRemainder(dividingBy: 10) == 0 || 0 - (n.truncatingRemainder(dividingBy: 10)) <= 0.1 && 0 - (n.truncatingRemainder(dividingBy: 10)) >= -0.1
    }
    
    func increaseDifficulty() {
        diffNum = diffNum - 2
        
        print("difficulty INCREASED!!!!!!!! ")
    }
    
    func moveUserNode(){
        if motionManager!.isAccelerometerAvailable == true{
            motionManager!.deviceMotionUpdateInterval = 0.001
            
            motionManager!.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler:{
                deviceManager, error in
                
                if self.gameOn == true && self.gamePaused == false{
                    
                    self.roll = CGFloat(self.motionManager!.deviceMotion!.attitude.roll)
                    self.pitch = CGFloat(-self.motionManager!.deviceMotion!.attitude.pitch) + CGFloat(self.calibY)
                    
                    //Keep userNode on screen
                    
                    self.newPosition = CGPoint(x: self.userNode.position.x + (CGFloat(self.roll) * 20) , y: self.userNode.position.y + (CGFloat(self.pitch) * 20))
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
            
            bullet.position = (direction == 1) ? CGPoint(x: rightBound + (bullet.size.width / 2), y: ranY) : (direction == 2) ? CGPoint(x: ranX, y: upperBound + (bullet.size.width / 2)) : (direction == 3) ? CGPoint(x: leftBound - (bullet.size.width / 2), y: ranY) : CGPoint(x: ranX, y: bottomBound - (bullet.size.width / 2))

            
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
            bullet.physicsBody?.isDynamic = true
            bullet.physicsBody?.allowsRotation = false
            bulletArray.append(bullet)
            bullet.physicsBody?.categoryBitMask = bulletCategory
            bullet.physicsBody?.contactTestBitMask = userCategory
            bullet.physicsBody?.collisionBitMask = 4294967295 | defenseBulletCategory
            bullets.addChild(bullet)
            
            //Shoot action
            let shoot = SKAction.move(to: (direction == 1) ? CGPoint(x: leftBound - 25, y: ranY) : (direction == 2) ? CGPoint(x: ranX, y: bottomBound - 25) : (direction == 3) ? CGPoint(x: rightBound + 25, y: ranY) : CGPoint(x: ranX, y: upperBound + 25), duration: ranSpeed)
            
            let rotate = SKAction.rotate(byAngle: CGFloat(M_PI / 2), duration: 0.0000001)
            let shootAndRemove = (direction == 2 || direction == 4) ? SKAction.sequence([rotate, shoot, remove]) : SKAction.sequence([shoot, remove])
            
            bullet.run(shootAndRemove)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
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
                scoreLabel.layer.add(animator.caBasicAnimation(0, to: 5, repeatCount: 0, keyPath: "borderWidth", duration: 0.25), forKey: "increaseBorder")
                scoreLabel.layer.borderWidth = 5
            }
        }
            
        else if firstBody.categoryBitMask == defenseBulletCategory && secondBody.categoryBitMask == defenseBulletCategory{//Defense bullets collided
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
        }
    }
    
    func explosionAnimation(_ pos: CGPoint){
        let explosion = SKShapeNode(circleOfRadius: 25)
        self.addChild(explosion)
        explosion.position = pos
        explosion.setScale(0)
        explosion.fillColor = UIColor.white

        let grow = SKAction.scale(to: 1.5, duration: 0.25)
        let shrink = SKAction.scale(to: 0, duration: 0.25)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.25)
        let group = SKAction.group([shrink, fadeOut])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([grow, group, remove])
        
        explosion.run(sequence)
    }
    
    func gameOverAnimation(_ pos: CGPoint){
        explosionAnimation(pos)
        let pulsateOut = SKAction.scaleX(to: 2, y: 2, duration: 0.25)
        let pulsateIn = SKAction.scaleX(to: 1, y: 1, duration: 0.25)
        let unSeq = SKAction.sequence([pulsateOut, pulsateIn])
        let `repeat` = SKAction.repeatForever(unSeq)
        userNode.run(`repeat`, withKey: "pulsate")
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
        dataManager.saveObjectInEntity("DefenseMode", objects: [defenseScore! as NSObject], keys: ["defenseHighScore"], deletePrevious: true)
    }
    
    func saveTimeHighScore() {
        dataManager.saveObjectInEntity("Time", objects: [time as NSObject], keys: ["timeHighScore"], deletePrevious: true)
    }
    
    //ReplayKit RPPreviewViewControllerDelegate
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        
    }
    
    //runs when user loses a game
    func gameOver(){
        
        self.view?.addSubview(menu)
        menu.showMenu("gameOver")
        menu.displayScoreLabels(&time, timeHighScore: (time > timeHighScore) ? true : false, score: &defenseScore!, newHighScore: (Double(defenseScore!) > highScore) ? true : false)
        
        timeLabel.layer.borderWidth = 0
        scoreLabel.layer.borderWidth = 0
        
        scoreLabel.layer.add(animator.caBasicAnimation(5, to: 0, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "shrink")
        timeLabel.layer.add(animator.caBasicAnimation(5, to: 0, repeatCount: 0, keyPath: "borderWidth", duration: 0.5), forKey: "shrink")
        
        timer.invalidate()
        timer = nil
        
        checkAchievements()
        gameOn = false
        if pauseButton != nil{
            UIView.animate(withDuration: 0.5, animations: {
                self.pauseButton.alpha = 0
                }, completion: { (value: Bool) in
                    self.pauseButton.removeFromParent()
                    self.pauseButton.removeAction(forKey: "pauseRepeat")
                    self.pauseButton = nil
            })
        }
        
        if reloadTimer != nil {
            reloadTimer.invalidate()
            reloadTimer = nil
        }

        if bulletCountView != nil {
            animator.complexAnimationForDuration(0.25, delay: 0, animation1: {
                self.bulletCountView.transform = CGAffineTransform(scaleX: 0.00000001, y: 0.0000000001)
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
        
        if sharedRecorder.isAvailable == true && record == true && sharedRecorder.isRecording == true{
            recordingLabel.removeFromSuperview()
            recordingLabel = nil
            sharedRecorder.stopRecording(handler: {
                (previewVC: RPPreviewViewController?, error: NSError?) -> Void in
                if previewVC != nil {
                    self.previewViewController = previewVC!
                    self.previewViewController.previewControllerDelegate = self
                    self.menu.addViewReplayButton()
                }
            } as! (RPPreviewViewController?, Error?) -> Void)
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
    
    func removeChildrenAndActionsInArray(_ array: inout [SKNode]) {
        for a in array {
            a.removeAllChildren()
            a.removeAllActions()
        }
        self.removeChildren(in: array)
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
        if (time.truncatingRemainder(dividingBy: 1) == 0) {
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
        GKScore.report(scoreArray, withCompletionHandler: {(error : Error?) -> Void in
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
        
        GKAchievement.loadAchievements(completionHandler: { (allAchievements: [GKAchievement]?, error: Error?) -> Void in
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
                GKAchievement.report([achievement], withCompletionHandler:  {(error: Error?) -> Void in
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
            GKAchievement.resetAchievements(completionHandler: { (error: Error?) -> Void in
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
                GKAchievement.resetAchievements(completionHandler: { (error: Error?) -> Void in
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
        
        gameVC!.performSegue(withIdentifier: "menu", sender: self)
    }
    
    func deallocateAllProperties () {
        
        userNode.removeAction(forKey: "pulsate")

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
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        if gameOn == true && gamePaused == false{
            self.moveUserNode()
            self.generateAndShootBullets()
            self.keepUserNodeOnScreen()
        }
    }
    
    //MARK: - GameForegroundViewDelegate
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}


public extension UIColor {
    public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        if rgba.hasPrefix("#") {
            let index = rgba.characters.index(rgba.startIndex, offsetBy: 1)
            let hex = rgba.substring(from: index)
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexInt64(&hexValue) {
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

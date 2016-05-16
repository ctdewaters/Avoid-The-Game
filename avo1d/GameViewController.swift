//
//  GameViewController.swift
//  avo1d
//
//  Created by Collin DeWaters on 10/26/14.
//  Copyright (c) 2014 CDWApps. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            let sceneData: NSData?
            do {
                sceneData = try NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            }
            catch {
                sceneData = nil
            }
            
            let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData!)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

weak var gameVC: GameViewController?
var skView: SKView!
weak var scene: GameScene?


class GameViewController: UIViewController  {
    
    var highestTime: Double!
    var highScore: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameVC = self
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        menu = nil
        //scene = nil
        if skView != nil {
             skView.removeFromSuperview()
        }
        skView = nil
        
            scene = GameScene.unarchiveFromFile("GameScene") as? GameScene
        
            // Configure the view.
            skView = SKView(frame: self.view.frame)
            skView.showsFPS = false
            skView.showsNodeCount = false
            view.addSubview(skView)
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene!.scaleMode = .ResizeFill
            scene!.backgroundColor = .clearColor()
        
            skView.presentScene(scene!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        for v in skView.subviews {
            v.removeFromSuperview()
        }
    }
    
    func deinitScene () {
        print("scene should deinit")
    }
}

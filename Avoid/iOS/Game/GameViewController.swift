//
//  GameViewController.swift
//  avo1d
//
//  Created by Collin DeWaters on 10/26/14.
//  Copyright (c) 2014 Collin DeWaters. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

extension SKNode {
    class func unarchiveFromFile(_ file : NSString) -> SKNode? {
        if let path = Bundle.main.path(forResource: file as String, ofType: "sks") {
            let sceneData: Data?
            do {
                sceneData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            }
            catch {
                sceneData = nil
            }
            
            let archiver = NSKeyedUnarchiver(forReadingWith: sceneData!)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
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
        
        UIApplication.shared.isIdleTimerDisabled = true
        
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
            scene!.scaleMode = .resizeFill
            scene!.backgroundColor = .clear
        
            skView.presentScene(scene!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        for v in skView.subviews {
            v.removeFromSuperview()
        }
    }
    
    func deinitScene () {
        print("scene should deinit")
    }
}

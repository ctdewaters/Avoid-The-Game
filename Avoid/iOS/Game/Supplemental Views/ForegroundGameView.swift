//
//  ForegroundGameView.swift
//  Avoid: The Game
//
//  Created by Collin DeWaters on 5/21/18.
//  Copyright © 2018 CDWApps. All rights reserved.
//

import UIKit

protocol GameForegroundViewDelegate {
    func menuDidSelectRecalibrate()
    func menuDidSelectResume()
    func menuDidSelectRestart()
    func menuDidSelectHome()
}

class ForegroundGameView: UIView, AvoidButtonDelegate {
    var delegate: GameForegroundViewDelegate?
    
    var resumeButton = AvoidButton()
    var calibrateButton = AvoidButton()
    var restartButton = AvoidButton()
    var exitButton = AvoidButton()
    
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
        self.backgroundColor = UIColor.clear
        background = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        background.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showMenu(_ menuType: String) {
        
        self.addSubview(background)
        self.sendSubview(toBack: background)
        self.background.alpha = 0
        
        animator.simpleAnimationForDuration(0.5, animation: {
            self.alpha = 1
            self.background.alpha = 1
        })
        
        switch menuType {
        case "pause" : //Setup pause menu
            
            titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height * 0.3))
            titleLabel.text = "Game Paused"
            titleLabel.textColor = UIColor(rgba: "#FFFFFF")
            titleLabel.font = UIFont(name: "Audiowide", size: 40)
            titleLabel.textAlignment = .center
            titleLabel.center = CGPoint(x: self.center.x, y: self.frame.minY + titleLabel.frame.height / 2)
            self.addSubview(titleLabel)
            titleLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
            titleLabel.alpha = 1
            
            animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
                self.titleLabel.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                self.background.alpha = 1
            }, animation2: {
                animator.simpleAnimationForDuration(0.15, animation: {
                    self.titleLabel.transform = .identity
                })
            })
            
            setUpPauseMenu()
            
            break
        case "gameOver" :
            titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height * 0.3))
            titleLabel.text = "Game Over"
            titleLabel.textColor = UIColor(rgba: "#FFFFFF")
            titleLabel.font = UIFont(name: "Audiowide", size: 40)
            titleLabel.textAlignment = .center
            titleLabel.center = CGPoint(x: self.center.x, y: self.frame.minY + titleLabel.frame.height / 2)
            self.addSubview(titleLabel)
            titleLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
            titleLabel.alpha = 1
            
            animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
                self.titleLabel.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                self.background.alpha = 1
            }, animation2: {
                animator.simpleAnimationForDuration(0.15, animation: {
                    self.titleLabel.transform = .identity
                })
            })
                        
            setUpGameOverMenu()
            
            break
        default:
            break
        }
    }
    
    func displayScoreLabels(_ time: inout Double, timeHighScore: Bool, score: inout Int, newHighScore: Bool) {
        timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        timeLabel.center = CGPoint(x: self.frame.width / 2 - self.frame.width / 4.5, y: (self.frame.height / 2 + titleLabel.center.y) / 2)
        timeLabel.text =  "\(NSString(format: "%.01f", time) as String)\nSeconds"
        timeLabel.font = UIFont(name: "Rubik", size: 20)
        timeLabel.backgroundColor = UIColor.white
        timeLabel.layer.cornerRadius = 50
        timeLabel.textColor = UIColor(rgba: "#00335b")
        timeLabel.layer.masksToBounds = true
        timeLabel.textAlignment = .center
        timeLabel.numberOfLines = 3
        timeLabel.alpha = 0
        self.addSubview(timeLabel)
        
        scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scoreLabel.center = CGPoint(x: self.frame.width / 2 +  self.frame.width / 4.5, y: (self.frame.height / 2 + titleLabel.center.y) / 2)
        scoreLabel.text = "\(score)\nHits"
        scoreLabel.font = UIFont(name: "Rubik", size: 20)
        scoreLabel.backgroundColor = UIColor(rgba: "#00335b")
        scoreLabel.textColor = UIColor.white
        scoreLabel.layer.cornerRadius = 50
        scoreLabel.layer.masksToBounds = true
        scoreLabel.textAlignment = .center
        scoreLabel.numberOfLines = 3
        scoreLabel.alpha = 0
        self.addSubview(scoreLabel)
        
        if timeHighScore == true {
            timeLabel.layer.borderColor = UIColor(rgba: "#00335b").cgColor
            timeLabel.layer.borderWidth = 5
        }
        if newHighScore == true {
            scoreLabel.layer.borderColor = UIColor.white.cgColor
            scoreLabel.layer.borderWidth = 5
        }
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.scoreLabel.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.scoreLabel.alpha = 1
            self.timeLabel.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.timeLabel.alpha = 1
        }, animation2: {
            animator.simpleAnimationForDuration(0.15, animation: {
                self.scoreLabel.transform = .identity
                self.timeLabel.transform = .identity
            })
        })
        
        //Finish all of this up
    }
    
    func addViewReplayButton() {
        viewReplayButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.4, height: 40))
        viewReplayButton.setTitle("View Replay", for: UIControlState())
        viewReplayButton.titleLabel?.font = UIFont(name: "Audiowide", size: 15)
        viewReplayButton.titleLabel?.textColor = UIColor.white
        viewReplayButton.backgroundColor = UIColor(rgba: "#00335b").withAlphaComponent(0.75)
        viewReplayButton.layer.cornerRadius = 20
        viewReplayButton.layer.masksToBounds = true
        viewReplayButton.center = CGPoint(x: self.center.x, y: calibrateButton.center.y + calibrateButton.frame.height / 2 + 45)
        viewReplayButton.addTarget(nil, action: #selector(ForegroundGameView.showReplay), for: .touchUpInside)
        viewReplayButton.alpha = 0
        self.addSubview(viewReplayButton)
        
        animator.simpleAnimationForDuration(0.35, animation: {
            self.viewReplayButton.alpha = 1
        })
    }
    
    @objc func showReplay() {
        animator.simpleAnimationForDuration(0.15, animation: {
            self.viewReplayButton.transform = .identity
        })
        gameVC?.present(scene!.previewViewController, animated: true, completion: nil)
    }
    
    
    func setUpMenuButton (_ button: AvoidButton, withTitle title: String, andTitleColor titleColor: UIColor, atCenter center: CGPoint, withSelector selector: Selector) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "Audiowide", size: 15)
        button.layer.cornerRadius = 10
        button.layer.zPosition += button.frame.width
        button.layer.masksToBounds = true
        button.center = center
        button.addTarget(self, action: selector, for: UIControlEvents.touchUpInside)
        button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        button.delegate = self
        
        self.addSubview(button)
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
        }, animation2: {
            animator.simpleAnimationForDuration(0.15, animation: {
                button.transform = .identity
            })
        })
    }
    
    func setCalibratedLabel () {
        calibratedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 50))
        calibratedLabel.text = "Device Recalibrated"
        calibratedLabel.transform = CGAffineTransform(scaleX: 0, y: 1)
        calibratedLabel.center = CGPoint(x: self.frame.width / 2, y: calibrateButton.center.y + calibrateButton.frame.height / 2 + 120)
        calibratedLabel.textAlignment = .center
        calibratedLabel.font = UIFont(name: "Audiowide", size: 20)
        calibratedLabel.textColor = .lightText
        self.addSubview(calibratedLabel)
    }
    
    var calibrateTimer: Timer!
    
    func animateCalibratedLabel () {
        calibratedLabel.transform = CGAffineTransform(scaleX: 0, y: 1)
        calibrateTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ForegroundGameView.shrinkCalibratedLabel), userInfo: nil, repeats: false)
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.calibratedLabel.transform = CGAffineTransform(scaleX: 1.25, y: 1)
        }, animation2: {
            animator.simpleAnimationForDuration(0.1, animation: {
                self.calibratedLabel.transform = .identity
            })
        })
    }
    
    @objc func shrinkCalibratedLabel () {
        animator.simpleAnimationForDuration(0.35, animation: {
            self.calibratedLabel.transform = CGAffineTransform(scaleX: 0.00000001, y: 1)
        })
        calibrateTimer.invalidate()
    }
    
    func setUpPauseMenu () {
        self.resumeButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))
        self.calibrateButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))
        self.exitButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))
        
        setUpMenuButton(calibrateButton, withTitle: "Recalibrate", andTitleColor: UIColor(rgba: "#30c62b"), atCenter: CGPoint(x: self.frame.width / 2, y: self.frame.midY + ((self.frame.width * 0.3) / 2)), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setUpMenuButton(resumeButton, withTitle: "Resume", andTitleColor: UIColor(rgba: "#00335b"), atCenter: CGPoint(x: (self.frame.width / 2) - (self.frame.width * 0.3) + 20, y: self.frame.midY), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setUpMenuButton(exitButton, withTitle: "Quit", andTitleColor: .red, atCenter: CGPoint(x: (self.frame.width / 2) + (self.frame.width * 0.3) - 20, y: self.frame.midY), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setCalibratedLabel()
    }
    
    func setUpGameOverMenu () {
        self.calibrateButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))
        self.restartButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))
        self.exitButton = AvoidButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.3, height: 40))

        setUpMenuButton(calibrateButton, withTitle: "Recalibrate", andTitleColor: UIColor(rgba: "#30c62b"), atCenter: CGPoint(x: self.frame.width / 2, y: self.frame.midY + ((self.frame.width * 0.3) / 2)), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setUpMenuButton(restartButton, withTitle: "Restart", andTitleColor: UIColor(rgba: "#00335b"), atCenter: CGPoint(x: (self.frame.width / 2) - (self.frame.width * 0.3) + 20, y: self.frame.midY), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setUpMenuButton(exitButton, withTitle: "Quit", andTitleColor: .red, atCenter: CGPoint(x: (self.frame.width / 2) + (self.frame.width * 0.3) - 20, y: self.frame.midY), withSelector: #selector(ForegroundGameView.didSelectButton(_:)))
        setCalibratedLabel()
    }
    
    @objc func didSelectButton (_ sender: UIButton) {
        sender.unhighlight()
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
        animator.simpleAnimationForDuration(0.35, animation: {
            self.selectedButton.alpha = 0
            self.calibrateButton.alpha = 0
            self.exitButton.alpha = 0
            self.restartButton.alpha = 0
            self.resumeButton.alpha = 0
        })
        
        animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            self.selectedButton.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.background.alpha = 0
            self.scoreLabel.transform = CGAffineTransform(scaleX: 0.00000000001, y: 0.00000000001)
            self.timeLabel.transform = CGAffineTransform(scaleX: 0.00000000001, y: 0.00000000001)
            self.titleLabel.alpha = 0
            
        }, animation2: {
            animator.complexAnimationForDuration(0.35, delay: 0, animation1: {
            }, animation2: {
                for v in self.subviews {
                    v.removeFromSuperview()
                }
                self.removeFromSuperview()
            })
        })
    }
    
    //Avo1dButtonDelegate
    func touchDidEnd(_ button: AvoidButton) {
        didSelectButton(button)
    }
    
}

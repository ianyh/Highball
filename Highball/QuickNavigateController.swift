//
//  QuickNavigateController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import pop

enum QuickNavigationOption {
    case Dashboard
    case Likes
    case Settings
}

class QuickNavigateController: UIViewController {
    var startingPoint: CGPoint!
    var completion: ((QuickNavigationOption?) -> ())?
    var navigationOption: QuickNavigationOption?
    
    private let radius: CGFloat = 70
    
    private var backgroundButton: UIButton!
    
    private var startButton: UIButton!
    
    private var dashboardButton: UIButton!
    private var likesButton: UIButton!
    private var settingsButton: UIButton!

    var showingOptions: Bool = false {
        didSet {
            self.startButton.layer.pop_removeAllAnimations()
            self.dashboardButton.layer.pop_removeAllAnimations()
            self.likesButton.layer.pop_removeAllAnimations()
            self.settingsButton.layer.pop_removeAllAnimations()
            
            if self.showingOptions {
                for button in [ self.dashboardButton, self.likesButton, self.settingsButton ] {
                    let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"

                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }
                
                let onLeft = self.startButton.center.x < CGRectGetMidX(self.view.bounds)
                let center = self.view.convertPoint(self.startButton.center, toView: nil)
                let distanceFromTop = center.y
                let distanceFromBottom = UIScreen.mainScreen().bounds.size.height - center.y - 50
                var angleFromTop: CGFloat = CGFloat(-M_PI_2) / 4
                var angleFromBottom: CGFloat = CGFloat(-M_PI_2) / 4
                
                if distanceFromTop < self.radius {
                    angleFromTop = acos(distanceFromTop / self.radius)
                }
                
                if distanceFromBottom < self.radius {
                    angleFromBottom = acos(distanceFromBottom / self.radius)
                }
                
                let startAngle = CGFloat(M_PI_2) + angleFromTop
                let endAngle = CGFloat(M_PI + M_PI_2) - angleFromBottom
                let initialAngle = startAngle + (endAngle - startAngle) / 5
                let angleInterval = (endAngle - startAngle) / 3
                
                for (index, button) in [ self.dashboardButton, self.likesButton, self.settingsButton ].enumerate() {
                    let center = self.startButton.center
                    let angleOffset = angleInterval * CGFloat(index)
                    let angle = initialAngle + angleOffset
                    let y = center.y - self.radius * sin(angle)
                    var x: CGFloat!
                    if onLeft {
                        x = center.x - self.radius * cos(angle)
                    } else {
                        x = center.x + self.radius * cos(angle)
                    }
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
                    
                    positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: x, y: y))
                    positionAnimation.springBounciness = 20
                    positionAnimation.name = "move"
                    positionAnimation.beginTime = CACurrentMediaTime() + 0.01
                    
                    button.layer.position = self.startButton.center
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            } else {
                for button in [ self.dashboardButton, self.likesButton, self.settingsButton ] {
                    let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 0
                    opacityAnimation.name = "opacity"
                    
                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                    
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
                    positionAnimation.toValue = NSValue(CGPoint: self.startButton.center)
                    positionAnimation.name = "moveReblog"
                    
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.opaque = false
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        self.backgroundButton = UIButton(type: .System)
        self.backgroundButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.startButton = UIButton(type: .System)
        self.startButton.setImage(UIImage(named: "Reblog"), forState: UIControlState.Normal)
        self.startButton.tintColor = UIColor.grayColor()
        self.startButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.startButton.sizeToFit()
        self.startButton.hidden = true

        self.dashboardButton = UIButton(type: .System)
        self.dashboardButton.setTitle("D", forState: UIControlState.Normal)
        self.dashboardButton.addTarget(self, action: Selector("dashboard:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.likesButton = UIButton(type: .System)
        self.likesButton.setTitle("L", forState: UIControlState.Normal)
        self.likesButton.addTarget(self, action: Selector("likes:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.settingsButton = UIButton(type: .System)
        self.settingsButton.setTitle("S", forState: UIControlState.Normal)
        self.settingsButton.addTarget(self, action: Selector("settings:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.view.addSubview(self.backgroundButton)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.dashboardButton)
        self.view.addSubview(self.likesButton)
        self.view.addSubview(self.settingsButton)
        
        constrain(self.backgroundButton, self.view) { backgroundButton, view in
            backgroundButton.edges == view.edges; return
        }
        
        constrain(self.startButton, self.view) { startButton, view in
            startButton.centerX == view.left + self.startingPoint.x
            startButton.centerY == view.top + self.startingPoint.y
            startButton.height == 40
            startButton.width == 40
        }
        
        for button in [ self.dashboardButton, self.likesButton, self.settingsButton ] {
            button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
            button.tintColor = UIColor.whiteColor()
            button.backgroundColor = backgroundColorForButton(button)
            button.layer.cornerRadius = 30
            button.layer.opacity = 0
            button.sizeToFit()
            constrain(button, self.startButton) { button, startButton in
                button.center == startButton.center
                button.height == 60
                button.width == 60
            }
        }

        var startButtonFrame = self.startButton.frame
        startButtonFrame.origin = self.startingPoint
        self.startButton.frame = startButtonFrame
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.showingOptions = true
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.showingOptions = false
    }

    func exit(sender: UIButton) {
        self.finishWithOption(nil)
    }

    func dashboard(sender: UIButton) {
        self.finishWithOption(QuickNavigationOption.Dashboard)
    }

    func likes(sender: UIButton) {
        self.finishWithOption(QuickNavigationOption.Likes)
    }

    func settings(sender: UIButton) {
        self.finishWithOption(QuickNavigationOption.Settings)
    }

    func finishWithOption(option: QuickNavigationOption?) {
        if let completion = self.completion {
            completion(option)
        }
        self.completion = nil
    }
    
    func backgroundColorForButton(button: UIButton) -> (UIColor) {
        let backgroundColor = UIColor.flatBlackColor()
        return backgroundColor
    }
}

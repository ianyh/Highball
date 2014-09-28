//
//  QuickReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

enum QuickReblogAction {
    case Reblog(ReblogType)
    case Share
}

class QuickReblogViewController: UIViewController {
    var startingPoint: CGPoint!

    private let radius: CGFloat = 55

    private var backgroundButton: UIButton!

    private var startButton: UIButton!

    private var reblogButton: UIButton!
    private var queueButton: UIButton!
    private var scheduleButton: UIButton!

    private var selectedButton: UIButton? {
        didSet {
            for button in [ self.reblogButton, self.queueButton, self.scheduleButton ] {
                button.tintColor = UIColor.whiteColor()
            }

            if let button = self.selectedButton {
                button.tintColor = UIColor.pastelGreenColor()
            }
        }
    }
    
    var showingOptions: Bool = false {
        didSet {
            self.startButton.layer.pop_removeAllAnimations()
            self.reblogButton.layer.pop_removeAllAnimations()
            self.queueButton.layer.pop_removeAllAnimations()
            self.scheduleButton.layer.pop_removeAllAnimations()
            
            if self.showingOptions {
                for button in [ self.reblogButton, self.queueButton, self.scheduleButton ] {
                    var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"
                    
                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }

                let onLeft = self.startButton.center.x < CGRectGetMidX(self.view.bounds)
                let center = self.view.convertPoint(self.startButton.center, toView: nil)
                let distanceFromTop = center.y + 50
                let distanceFromBottom = UIScreen.mainScreen().bounds.size.height - center.y - 50
                var angleFromTop: CGFloat = CGFloat(-M_PI_2) / 3
                var angleFromBottom: CGFloat = CGFloat(-M_PI_2) / 3
                
                if distanceFromTop < self.radius {
                    angleFromTop = acos(distanceFromTop / self.radius)
                }
                
                if distanceFromBottom < self.radius {
                    angleFromBottom = acos(distanceFromBottom / self.radius)
                }
                
                let startAngle = CGFloat(M_PI_2) + angleFromTop
                let endAngle = CGFloat(M_PI + M_PI_2) - angleFromBottom
                let initialAngle = startAngle + (endAngle - startAngle) / 6
                let angleInterval = (endAngle - startAngle) / 3
                
                for (index, button) in enumerate([ self.reblogButton, self.queueButton, self.scheduleButton ]) {
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
                for button in [ self.reblogButton, self.queueButton, self.scheduleButton ] {
                    var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 0
                    opacityAnimation.name = "opacity"
                    
                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                    
                    var positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
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

        self.backgroundButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.backgroundButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.startButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.startButton.setImage(UIImage(named: "Reblog"), forState: UIControlState.Normal)
        self.startButton.tintColor = UIColor.grayColor()
        self.startButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.startButton.sizeToFit()

        self.reblogButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.reblogButton.setImage(UIImage(named: "Reblog"), forState: UIControlState.Normal)
        self.reblogButton.tintColor = UIColor.whiteColor()
        self.reblogButton.layer.opacity = 0
        self.reblogButton.addTarget(self, action: Selector("reblog:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.reblogButton.sizeToFit()

        self.queueButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.queueButton.setImage(UIImage(named: "Queue"), forState: UIControlState.Normal)
        self.queueButton.tintColor = UIColor.whiteColor()
        self.queueButton.layer.opacity = 0
        self.queueButton.addTarget(self, action: Selector("queue:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.queueButton.sizeToFit()

        self.scheduleButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.scheduleButton.setImage(UIImage(named: "Schedule"), forState: UIControlState.Normal)
        self.scheduleButton.tintColor = UIColor.whiteColor()
        self.scheduleButton.layer.opacity = 0
        self.scheduleButton.addTarget(self, action: Selector("schedule:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.scheduleButton.sizeToFit()

        self.view.addSubview(self.backgroundButton)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.reblogButton)
        self.view.addSubview(self.queueButton)
        self.view.addSubview(self.scheduleButton)

        self.backgroundButton.snp_makeConstraints { maker in
            let insets = UIEdgeInsetsZero
            maker.edges.equalTo(self.view).insets(insets)
        }

        self.startButton.snp_makeConstraints { (maker) -> () in
            maker.height.equalTo(40)
            maker.width.equalTo(40)
            maker.centerX.equalTo(self.view.snp_left).offset(Float(self.startingPoint.x))
            maker.centerY.equalTo(self.view.snp_top).offset(Float(self.startingPoint.y))
        }

        self.reblogButton.snp_makeConstraints { (maker) -> () in
            maker.center.equalTo(self.startButton.snp_center)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }

        self.queueButton.snp_makeConstraints { (maker) -> () in
            maker.center.equalTo(self.startButton.snp_center)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }

        self.scheduleButton.snp_makeConstraints { (maker) -> () in
            maker.center.equalTo(self.startButton.snp_center)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }

        var startButtonFrame = self.startButton.frame
        startButtonFrame.origin = self.startingPoint
        self.startButton.frame = startButtonFrame
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.showingOptions = true
    }

    func updateWithPoint(point: CGPoint) {
        if let view = self.view.hitTest(point, withEvent: nil) {
            if let button = view as? UIButton {
                if button != self.startButton {
                    self.selectedButton = button
                }
            }
        }
    }

    func reblogAction() -> QuickReblogAction? {
        if let selectedButton = self.selectedButton {
            if selectedButton == self.reblogButton {
                return QuickReblogAction.Reblog(ReblogType.Reblog)
            } else if selectedButton == self.queueButton {
                return QuickReblogAction.Reblog(ReblogType.Queue)
            } else if selectedButton == self.scheduleButton {
                return QuickReblogAction.Share
            }
        }

        return nil
    }
}

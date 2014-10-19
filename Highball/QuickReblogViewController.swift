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

    private let radius: CGFloat = 70

    private var backgroundButton: UIButton!

    private var startButton: UIButton!

    private var reblogButton: UIButton!
    private var queueButton: UIButton!
    private var shareButton: UIButton!

    private var selectedButton: UIButton? {
        didSet {
            for button in [ self.reblogButton, self.queueButton, self.shareButton ] {
                if button == self.selectedButton {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1.2, height: 1.2))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")
                    button.tintColor = UIColor.pastelGreenColor()
                    button.backgroundColor = UIColor.black75PercentColor()
                } else {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1, height: 1))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")
                    button.tintColor = UIColor.whiteColor()
                    button.backgroundColor = UIColor.blackColor()
                }
            }
        }
    }
    
    var showingOptions: Bool = false {
        didSet {
            self.startButton.layer.pop_removeAllAnimations()
            self.reblogButton.layer.pop_removeAllAnimations()
            self.queueButton.layer.pop_removeAllAnimations()
            self.shareButton.layer.pop_removeAllAnimations()
            
            if self.showingOptions {
                for button in [ self.reblogButton, self.queueButton, self.shareButton ] {
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
                
                for (index, button) in enumerate([ self.reblogButton, self.queueButton, self.shareButton ]) {
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
                for button in [ self.reblogButton, self.queueButton, self.shareButton ] {
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
        self.reblogButton.setTitle("Reblog", forState: UIControlState.Normal)
        self.reblogButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.reblogButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        self.reblogButton.tintColor = UIColor.whiteColor()
        self.reblogButton.backgroundColor = UIColor.blackColor()
        self.reblogButton.layer.cornerRadius = 5
        self.reblogButton.layer.opacity = 0
        self.reblogButton.addTarget(self, action: Selector("reblog:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.reblogButton.sizeToFit()

        self.queueButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.queueButton.setTitle("Queue", forState: UIControlState.Normal)
        self.queueButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.queueButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        self.queueButton.tintColor = UIColor.whiteColor()
        self.queueButton.backgroundColor = UIColor.blackColor()
        self.queueButton.layer.cornerRadius = 5
        self.queueButton.layer.opacity = 0
        self.queueButton.addTarget(self, action: Selector("queue:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.queueButton.sizeToFit()

        self.shareButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.shareButton.setTitle("Share", forState: UIControlState.Normal)
        self.shareButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.shareButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        self.shareButton.tintColor = UIColor.whiteColor()
        self.shareButton.backgroundColor = UIColor.blackColor()
        self.shareButton.layer.cornerRadius = 5
        self.shareButton.layer.opacity = 0
        self.shareButton.addTarget(self, action: Selector("schedule:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.shareButton.sizeToFit()

        self.view.addSubview(self.backgroundButton)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.reblogButton)
        self.view.addSubview(self.queueButton)
        self.view.addSubview(self.shareButton)

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
            maker.height.equalTo(60)
            maker.width.equalTo(120)
        }

        self.queueButton.snp_makeConstraints { (maker) -> () in
            maker.center.equalTo(self.startButton.snp_center)
            maker.height.equalTo(60)
            maker.width.equalTo(120)
        }

        self.shareButton.snp_makeConstraints { (maker) -> () in
            maker.center.equalTo(self.startButton.snp_center)
            maker.height.equalTo(60)
            maker.width.equalTo(120)
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
                if button != self.selectedButton {
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
            } else if selectedButton == self.shareButton {
                return QuickReblogAction.Share
            }
        }

        return nil
    }
}

//
//  QuickReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

enum QuickReblogAction {
    case Reblog(ReblogType)
    case Share
    case Like
}

class QuickReblogViewController: UIViewController {
    var startingPoint: CGPoint!
    var post: Post!

    private let radius: CGFloat = 70

    private var backgroundButton: UIButton!

    private var startButton: UIButton!

    private var reblogButton: UIButton!
    private var queueButton: UIButton!
    private var shareButton: UIButton!
    private var likeButton: UIButton!

    private var selectedButton: UIButton? {
        didSet {
            for button in [ self.reblogButton, self.queueButton, self.shareButton, self.likeButton ] {
                if button == self.selectedButton {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1.5, height: 1.5))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")
                    let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
                    backgroundColorAnimation.toValue = self.backgroundColorForButton(button).CGColor
                    button.pop_removeAnimationForKey("selectedBackgroundColor")
                    button.pop_addAnimation(backgroundColorAnimation, forKey: "selectedBackgroundColor")
                } else {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1, height: 1))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")
                    let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
                    backgroundColorAnimation.toValue = self.backgroundColorForButton(button)
                    button.pop_removeAnimationForKey("selectedBackgroundColor")
                    button.pop_addAnimation(backgroundColorAnimation, forKey: "selectedBackgroundColor")
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
            self.likeButton.layer.pop_removeAllAnimations()

            if self.showingOptions {
                for button in [ self.reblogButton, self.queueButton, self.shareButton, self.likeButton ] {
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
                let initialAngle = startAngle + (endAngle - startAngle) / 8
                let angleInterval = (endAngle - startAngle) / 4
                
                for (index, button) in enumerate([ self.reblogButton, self.queueButton, self.shareButton, self.likeButton ]) {
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
                for button in [ self.reblogButton, self.queueButton, self.shareButton, self.likeButton ] {
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

        self.backgroundButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.backgroundButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.startButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.startButton.setImage(UIImage(named: "Reblog"), forState: UIControlState.Normal)
        self.startButton.tintColor = UIColor.grayColor()
        self.startButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.startButton.sizeToFit()

        self.reblogButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.reblogButton.setImage(FAKIonIcons.iosLoopStrongIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: UIControlState.Normal)
        self.reblogButton.addTarget(self, action: Selector("reblog:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.queueButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.queueButton.setImage(FAKIonIcons.iosListOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: UIControlState.Normal)
        self.queueButton.addTarget(self, action: Selector("queue:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.shareButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.shareButton.setImage(FAKIonIcons.iosUploadOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: UIControlState.Normal)
        self.shareButton.addTarget(self, action: Selector("schedule:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.likeButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        self.likeButton.setImage(FAKIonIcons.iosHeartOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: UIControlState.Normal)
        self.likeButton.addTarget(self, action: Selector("like:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.view.addSubview(self.backgroundButton)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.reblogButton)
        self.view.addSubview(self.queueButton)
        self.view.addSubview(self.shareButton)
        self.view.addSubview(self.likeButton)

        layout(self.backgroundButton, self.view) { backgroundButton, view in
            backgroundButton.edges == view.edges; return
        }

        layout(self.startButton, self.view) { startButton, view in
            startButton.centerX == view.left + Float(self.startingPoint.x)
            startButton.centerY == view.top + Float(self.startingPoint.y)
            startButton.height == 40
            startButton.width == 40
        }

        for button in [ self.reblogButton, self.queueButton, self.shareButton, self.likeButton ] {
            button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
            button.tintColor = UIColor.whiteColor()
            button.backgroundColor = backgroundColorForButton(button)
            button.layer.cornerRadius = 30
            button.layer.opacity = 0
            button.sizeToFit()
            layout(button, self.startButton) { button, startButton in
                button.center == startButton.center
                button.height == 60
                button.width == 60
            }
        }

        var startButtonFrame = self.startButton.frame
        startButtonFrame.origin = self.startingPoint
        self.startButton.frame = startButtonFrame
    }

     override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        dispatch_async(dispatch_get_main_queue()) { _ in self.showingOptions = true; return }
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
            switch selectedButton {
            case self.reblogButton:
                return QuickReblogAction.Reblog(ReblogType.Reblog)
            case self.queueButton:
                return QuickReblogAction.Reblog(ReblogType.Queue)
            case self.shareButton:
                return QuickReblogAction.Share
            case self.likeButton:
                return QuickReblogAction.Like
            default:
                return nil
            }
        }
        return nil
    }

    func backgroundColorForButton(button: UIButton) -> (UIColor) {
        var backgroundColor: UIColor!
        switch button {
        case self.reblogButton:
            backgroundColor = UIColor.flatBlackColor()
        case self.queueButton:
            backgroundColor = UIColor.flatBlackColor()
        case self.shareButton:
            backgroundColor = UIColor.flatBlackColor()
        case self.likeButton:
            if self.post.liked.boolValue {
                backgroundColor = UIColor.flatRedColor()
            } else {
                backgroundColor = UIColor.flatBlackColor()
            }
        default:
            backgroundColor = UIColor.flatBlackColor()
        }

        if button == self.selectedButton {
            return backgroundColor
        }

        return backgroundColor.colorWithAlphaComponent(0.75)
    }
}

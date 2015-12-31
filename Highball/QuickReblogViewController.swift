//
//  QuickReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import ChameleonFramework
import FontAwesomeKit
import pop
import UIKit

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
            for button in [ reblogButton, queueButton, shareButton, likeButton ] {
                if button == selectedButton {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1.5, height: 1.5))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")

                    let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
                    backgroundColorAnimation.toValue = backgroundColorForButton(button).CGColor
                    button.pop_removeAnimationForKey("selectedBackgroundColor")
                    button.pop_addAnimation(backgroundColorAnimation, forKey: "selectedBackgroundColor")
                } else {
                    let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
                    scaleAnimation.toValue = NSValue(CGSize: CGSize(width: 1, height: 1))
                    scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                    button.pop_removeAnimationForKey("selectedScale")
                    button.pop_addAnimation(scaleAnimation, forKey: "selectedScale")

                    let backgroundColorAnimation = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
                    backgroundColorAnimation.toValue = backgroundColorForButton(button)
                    button.pop_removeAnimationForKey("selectedBackgroundColor")
                    button.pop_addAnimation(backgroundColorAnimation, forKey: "selectedBackgroundColor")
                }
            }
        }
    }

    var showingOptions: Bool = false {
        didSet {
            startButton.layer.pop_removeAllAnimations()
            reblogButton.layer.pop_removeAllAnimations()
            queueButton.layer.pop_removeAllAnimations()
            shareButton.layer.pop_removeAllAnimations()
            likeButton.layer.pop_removeAllAnimations()

            if showingOptions {
                for button in [ reblogButton, queueButton, shareButton, likeButton ] {
                    let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"

                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }

                let onLeft = startButton.center.x < CGRectGetMidX(view.bounds)
                let center = view.convertPoint(startButton.center, toView: nil)
                let distanceFromTop = center.y + 50
                let distanceFromBottom = UIScreen.mainScreen().bounds.height - center.y - 50
                var angleFromTop: CGFloat = CGFloat(-M_PI_2) / 3
                var angleFromBottom: CGFloat = CGFloat(-M_PI_2) / 3

                if distanceFromTop < radius {
                    angleFromTop = acos(distanceFromTop / radius)
                }

                if distanceFromBottom < radius {
                    angleFromBottom = acos(distanceFromBottom / radius)
                }

                let startAngle = CGFloat(M_PI_2) + angleFromTop
                let endAngle = CGFloat(M_PI + M_PI_2) - angleFromBottom
                let initialAngle = startAngle + (endAngle - startAngle) / 8
                let angleInterval = (endAngle - startAngle) / 4

                for (index, button) in [ reblogButton, queueButton, shareButton, likeButton ].enumerate() {
                    let center = startButton.center
                    let angleOffset = angleInterval * CGFloat(index)
                    let angle = initialAngle + angleOffset
                    let y = center.y - radius * sin(angle)
                    var x: CGFloat!
                    if onLeft {
                        x = center.x - radius * cos(angle)
                    } else {
                        x = center.x + radius * cos(angle)
                    }
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)

                    positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: x, y: y))
                    positionAnimation.springBounciness = 20
                    positionAnimation.name = "move"
                    positionAnimation.beginTime = CACurrentMediaTime() + 0.01

                    button.layer.position = startButton.center
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            } else {
                for button in [ reblogButton, queueButton, shareButton, likeButton ] {
                    let opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 0
                    opacityAnimation.name = "opacity"

                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)

                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
                    positionAnimation.toValue = NSValue(CGPoint: startButton.center)
                    positionAnimation.name = "moveReblog"

                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.opaque = false
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)

        backgroundButton = UIButton(type: .System)
        backgroundButton.addTarget(self, action: Selector("exit:"), forControlEvents: .TouchUpInside)

        startButton = UIButton(type: .System)
        startButton.setImage(UIImage(named: "Reblog"), forState: .Normal)
        startButton.tintColor = UIColor.grayColor()
        startButton.addTarget(self, action: Selector("exit:"), forControlEvents: .TouchUpInside)
        startButton.sizeToFit()

        reblogButton = UIButton(type: .System)
        reblogButton.setImage(FAKIonIcons.iosLoopStrongIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: .Normal)
        reblogButton.addTarget(self, action: Selector("reblog:"), forControlEvents: .TouchUpInside)

        queueButton = UIButton(type: .System)
        queueButton.setImage(FAKIonIcons.iosListOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: .Normal)
        queueButton.addTarget(self, action: Selector("queue:"), forControlEvents: .TouchUpInside)

        shareButton = UIButton(type: .System)
        shareButton.setImage(FAKIonIcons.iosUploadOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: .Normal)
        shareButton.addTarget(self, action: Selector("schedule:"), forControlEvents: .TouchUpInside)

        likeButton = UIButton(type: .System)
        likeButton.setImage(FAKIonIcons.iosHeartOutlineIconWithSize(25).imageWithSize(CGSize(width: 25, height: 25)), forState: .Normal)
        likeButton.addTarget(self, action: Selector("like:"), forControlEvents: .TouchUpInside)

        view.addSubview(backgroundButton)
        view.addSubview(startButton)
        view.addSubview(reblogButton)
        view.addSubview(queueButton)
        view.addSubview(shareButton)
        view.addSubview(likeButton)

        constrain(backgroundButton, view) { backgroundButton, view in
            backgroundButton.edges == view.edges
        }

        constrain(startButton, view) { startButton, view in
            startButton.centerX == view.left + self.startingPoint.x
            startButton.centerY == view.top + self.startingPoint.y
            startButton.height == 40
            startButton.width == 40
        }

        for button in [ reblogButton, queueButton, shareButton, likeButton ] {
            button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
            button.tintColor = UIColor.whiteColor()
            button.backgroundColor = backgroundColorForButton(button)
            button.layer.cornerRadius = 30
            button.layer.opacity = 0
            button.sizeToFit()
            constrain(button, startButton) { button, startButton in
                button.center == startButton.center
                button.height == 60
                button.width == 60
            }
        }

        var startButtonFrame = startButton.frame
        startButtonFrame.origin = startingPoint
        startButton.frame = startButtonFrame
    }

     override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        dispatch_async(dispatch_get_main_queue()) { self.showingOptions = true }
    }
}

extension QuickReblogViewController {
    func updateWithPoint(point: CGPoint) {
        guard
            let view = view.hitTest(point, withEvent: nil),
            let button = view as? UIButton
        else {
            return
        }

        if button != selectedButton {
            selectedButton = button
        }
    }

    func reblogAction() -> QuickReblogAction? {
        guard let selectedButton = selectedButton else {
            return nil
        }

        switch selectedButton {
        case self.reblogButton:
            return .Reblog(.Reblog)
        case self.queueButton:
            return .Reblog(.Queue)
        case self.shareButton:
            return .Share
        case self.likeButton:
            return .Like
        default:
            return nil
        }
    }

    func backgroundColorForButton(button: UIButton) -> (UIColor) {
        var backgroundColor: UIColor!
        switch button {
        case reblogButton:
            backgroundColor = UIColor.flatBlackColor()
        case queueButton:
            backgroundColor = UIColor.flatBlackColor()
        case shareButton:
            backgroundColor = UIColor.flatBlackColor()
        case likeButton:
            if post.liked.boolValue {
                backgroundColor = UIColor.flatRedColor()
            } else {
                backgroundColor = UIColor.flatBlackColor()
            }
        default:
            backgroundColor = UIColor.flatBlackColor()
        }

        if button == selectedButton {
            return backgroundColor
        }

        return backgroundColor.colorWithAlphaComponent(0.75)
    }
}

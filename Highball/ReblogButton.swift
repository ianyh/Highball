//
//  ReblogButton.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/4/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

public enum ReblogType {
    case Reblog
    case Queue
    case Schedule
}

class ReblogButton: UIView {
    var reblogHandler: ((ReblogType) -> ())?

    private let radius: CGFloat = 45

    private var backgroundView: UIView!
    private var startButton: UIButton!

    private var reblogButton: UIButton!
    private var queueButton: UIButton!
    private var scheduleButton: UIButton!

    var showingOptions: Bool = false {
        didSet {
            let referenceOrigin = self.startButton.frame.origin

            self.startButton.layer.pop_removeAllAnimations()
            self.reblogButton.layer.pop_removeAllAnimations()
            self.queueButton.layer.pop_removeAllAnimations()
            self.scheduleButton.layer.pop_removeAllAnimations()

            if self.showingOptions {
                var outerGlowAnimation = POPSpringAnimation(propertyNamed: kPOPLayerSize)
                outerGlowAnimation.toValue = NSValue(CGSize: CGSize(width: 130, height: 130))
                outerGlowAnimation.springBounciness = 10
                outerGlowAnimation.name = "showOuterGlow"

                self.backgroundView.layer.pop_addAnimation(outerGlowAnimation, forKey: outerGlowAnimation.name)

                var outerGlowPositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerCornerRadius)
                outerGlowPositionAnimation.toValue = 65
                outerGlowPositionAnimation.springBounciness = 10
                outerGlowPositionAnimation.name = "outerGlowPositionAnimation"

                self.backgroundView.layer.pop_addAnimation(outerGlowPositionAnimation, forKey: outerGlowPositionAnimation.name)

                for button in [ self.reblogButton, self.queueButton, self.scheduleButton ] {
                    var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"

                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }

                let center = self.convertPoint(self.startButton.center, toView: nil)
                let distanceFromTop = center.y - 60
                let distanceFromBottom = UIScreen.mainScreen().bounds.size.height - center.y
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
                    let x = center.x + self.radius * cos(angle)
                    let y = center.y - self.radius * sin(angle)
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)

                    positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: x, y: y))
                    positionAnimation.springBounciness = 20
                    positionAnimation.name = "move"
                    positionAnimation.beginTime = CACurrentMediaTime() + 0.01

                    button.layer.position = self.startButton.center
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            } else {
                var outerGlowAnimation = POPSpringAnimation(propertyNamed: kPOPLayerSize)
                outerGlowAnimation.toValue = NSValue(CGSize: CGSizeZero)
                outerGlowAnimation.springBounciness = 10
                outerGlowAnimation.name = "showOuterGlow"

                self.backgroundView.layer.pop_addAnimation(outerGlowAnimation, forKey: outerGlowAnimation.name)

                var outerGlowPositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerCornerRadius)
                outerGlowPositionAnimation.toValue = 0
                outerGlowPositionAnimation.springBounciness = 10
                outerGlowPositionAnimation.name = "outerGlowPositionAnimation"

                self.backgroundView.layer.pop_addAnimation(outerGlowPositionAnimation, forKey: outerGlowPositionAnimation.name)

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpButton()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpButton()
    }

    private func setUpButton() {
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        self.backgroundView.layer.cornerRadius = 0
        self.backgroundView.clipsToBounds = true

        self.startButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.startButton.setImage(UIImage(named: "Start"), forState: UIControlState.Normal)
        self.startButton.tintColor = UIColor.whiteColor()
        self.startButton.addTarget(self, action: Selector("toggleOptions:"), forControlEvents: UIControlEvents.TouchUpInside)
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

        self.addSubview(self.backgroundView)
        self.addSubview(self.startButton)
        self.addSubview(self.reblogButton)
        self.addSubview(self.queueButton)
        self.addSubview(self.scheduleButton)

        layout2(self.startButton, self) { button, view in
            button.right == view.right
            button.centerY == view.centerY
            button.height == 40
            button.width == 40
        }

        layout2(self.backgroundView, self.startButton) { background, button in
            background.center == button.center
            background.width == 0
            background.height == 0
        }

        layout2(self.reblogButton, self.startButton) { button, view in
            button.center == view.center
            button.height == 40
            button.width == 40
        }

        layout2(self.queueButton, self.startButton) { button, view in
            button.center == view.center
            button.height == 40
            button.width == 40
        }

        layout2(self.scheduleButton, self.startButton) { button, view in
            button.center == view.center
            button.height == 40
            button.width == 40
        }
    }

    func toggleOptions(sender: UIButton) {
        self.showingOptions = !showingOptions
    }

    func reblog(sender: UIButton) {
        if self.showingOptions {
            self.showingOptions = false
        }

        if let handler = self.reblogHandler {
            handler(ReblogType.Reblog)
        }
    }

    func queue(sender: UIButton) {
        if self.showingOptions {
            self.showingOptions = false
        }

        if let handler = self.reblogHandler {
            handler(ReblogType.Reblog)
        }
    }

    func schedule(sender: UIButton) {
        if self.showingOptions {
            self.showingOptions = false
        }

        if let handler = self.reblogHandler {
            handler(ReblogType.Reblog)
        }
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 40 + self.radius, height: 40 + self.radius * 2)
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if self.showingOptions {
            return super.pointInside(point, withEvent: event)
        }

        let convertedPoint = self.convertPoint(point, toView: self.startButton)
        return self.startButton.pointInside(convertedPoint, withEvent: event)
    }
}

//
//  BookmarksViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 11/9/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

enum BookmarksOption {
    case Bookmark
    case Goto
    case Top
}

class BookmarksViewController: UIViewController {
    var startingPoint: CGPoint!
    var completion: ((BookmarksOption?) -> ())?
    var navigationOption: BookmarksOption?

    private let radius: CGFloat = 70

    private var backgroundButton: UIButton!

    private var startButton: UIButton!

    private var gotoButton: UIButton!
    private var topButton: UIButton!

    var showingOptions: Bool = false {
        didSet {
            self.startButton.layer.pop_removeAllAnimations()
            self.gotoButton.layer.pop_removeAllAnimations()
            self.topButton.layer.pop_removeAllAnimations()

            if self.showingOptions {
                for button in [ self.gotoButton, self.topButton ] {
                    var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"

                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }

                let center = self.view.convertPoint(self.startButton.center, toView: nil)
                let distanceFromTop = center.y
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
                let initialAngle = startAngle + (endAngle - startAngle) / 4
                let angleInterval = (endAngle - startAngle) / 2

                for (index, button) in enumerate([ self.gotoButton, self.topButton ]) {
                    let center = self.startButton.center
                    let angleOffset = angleInterval * CGFloat(index)
                    let angle = initialAngle + angleOffset
                    let y = center.y - self.radius * sin(angle)
                    var x = center.x + self.radius * cos(angle)
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)

                    positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: x, y: y))
                    positionAnimation.springBounciness = 20
                    positionAnimation.name = "move"
                    positionAnimation.beginTime = CACurrentMediaTime() + 0.01

                    button.layer.position = self.startButton.center
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            } else {
                for button in [ self.gotoButton, self.topButton ] {
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
        self.startButton.hidden = true

        self.gotoButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.gotoButton.setTitle("G", forState: UIControlState.Normal)
        self.gotoButton.addTarget(self, action: Selector("goto:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.topButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.topButton.setTitle("T", forState: UIControlState.Normal)
        self.topButton.addTarget(self, action: Selector("top:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.view.addSubview(self.backgroundButton)
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.gotoButton)
        self.view.addSubview(self.topButton)

        layout(self.backgroundButton, self.view) { backgroundButton, view in
            backgroundButton.edges == view.edges; return
        }

        layout(self.startButton, self.view) { startButton, view in
            startButton.centerX == view.left + Float(self.startingPoint.x)
            startButton.centerY == view.top + Float(self.startingPoint.y)
            startButton.height == 40
            startButton.width == 40
        }

        for button in [ self.gotoButton, self.topButton ] {
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

    func save(sender: UIButton) {
        self.finishWithOption(BookmarksOption.Bookmark)
    }

    func goto(sender: UIButton) {
        self.finishWithOption(BookmarksOption.Goto)
    }

    func top(sender: UIButton) {
        self.finishWithOption(BookmarksOption.Top)
    }

    private func finishWithOption(option: BookmarksOption?) {
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

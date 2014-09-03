//
//  PostFooterView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostFooterView: UITableViewHeaderFooterView {

    var startButton: UIButton!
    var reblogButton: UIButton!

    var showingOptions: Bool?
    var post: Post? {
        didSet {
            if let post = self.post {

            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpCell()
    }

    override init(reuseIdentifier: String!) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    func setUpCell() {
        self.showingOptions = false

        self.contentView.backgroundColor = UIColor.blackColor()

        self.startButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.reblogButton = UIButton.buttonWithType(UIButtonType.System) as UIButton

        self.startButton.setTitle("Reblog", forState: UIControlState.Normal)
        self.startButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.startButton.addTarget(self, action: Selector("showOptions:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.startButton.sizeToFit()

        self.reblogButton.setTitle("Reblog", forState: UIControlState.Normal)
        self.reblogButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        self.reblogButton.backgroundColor = UIColor.blackColor()
        self.reblogButton.layer.opacity = 0
        self.reblogButton.sizeToFit()

        self.contentView.addSubview(self.startButton)
        self.contentView.addSubview(self.reblogButton)

        layout2(self.startButton, self.contentView) { button, view in
            button.right == view.right - 4
            button.centerY == view.centerY
            button.height == 44
        }

        layout2(self.reblogButton, self.startButton) { button, view in
            button.right == view.left - 10
            button.bottom == view.top - 10
            button.height == 44
        }
    }

    func showOptions(sender: UIButton?) {
        let referenceFrame = self.startButton.frame

        self.reblogButton.layer.pop_removeAllAnimations()

        if self.showingOptions! {
            self.showingOptions = false
            var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
            opacityAnimation.toValue = 0
            opacityAnimation.name = "showReblog"

            self.reblogButton.layer.pop_addAnimation(opacityAnimation, forKey: "reblogOpacity")

            var positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
            positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: referenceFrame.origin.x - referenceFrame.size.width - 10, y: referenceFrame.origin.y - referenceFrame.size.height - 10))
            positionAnimation.name = "moveReblog"

            self.reblogButton.layer.pop_addAnimation(positionAnimation, forKey: "reblogPosition")
        } else {
            self.showingOptions = true
            var opacityAnimation = POPSpringAnimation(propertyNamed: kPOPLayerOpacity)
            opacityAnimation.toValue = 1
            opacityAnimation.name = "showReblog"

            self.reblogButton.layer.pop_addAnimation(opacityAnimation, forKey: "reblogOpacity")

            let referenceOrigin = self.startButton.frame.origin
            var positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
            positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: referenceFrame.origin.x - referenceFrame.size.width + 14, y: referenceFrame.origin.y - referenceFrame.size.height + 14))
            positionAnimation.springBounciness = 20
            positionAnimation.name = "moveReblog"

            self.reblogButton.layer.pop_addAnimation(positionAnimation, forKey: "reblogPosition")
        }
    }

}

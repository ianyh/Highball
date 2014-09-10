//
//  ReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/9/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ReblogViewController: UIViewController {
    private let radius: CGFloat = 30
    private let insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 70)

    private var keyboardFrame: CGRect! {
        didSet {
            if let keyboardFrame = self.keyboardFrame {
                var finalFrame = self.view.bounds
                finalFrame.size.height -= keyboardFrame.size.height

                var startingFrame = CGRectInset(finalFrame, 40, 40)
                startingFrame.origin.y += 100

                self.reblogView.pop_removeAllAnimations()
                self.reblogButton.layer.pop_removeAllAnimations()
                self.queueButton.layer.pop_removeAllAnimations()
                self.scheduleButton.layer.pop_removeAllAnimations()

                let frameAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
                frameAnimation.fromValue = NSValue(CGRect: startingFrame)
                frameAnimation.toValue = NSValue(CGRect: finalFrame)
                frameAnimation.springBounciness = 10
                frameAnimation.name = "frame"
                self.reblogView.pop_addAnimation(frameAnimation, forKey: frameAnimation.name)

                let alphaAnimation = POPSpringAnimation(propertyNamed: kPOPViewAlpha)
                alphaAnimation.fromValue = 0
                alphaAnimation.toValue = 1
                alphaAnimation.name = "alpha"
                self.reblogView.pop_addAnimation(alphaAnimation, forKey: alphaAnimation.name)
                
                for button in [ self.reblogButton, self.queueButton, self.scheduleButton ] {
                    var opacityAnimation = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)
                    opacityAnimation.fromValue = 0
                    opacityAnimation.toValue = 1
                    opacityAnimation.name = "opacity"
                    opacityAnimation.beginTime = CACurrentMediaTime() + 0.4
                    
                    button.layer.pop_addAnimation(opacityAnimation, forKey: opacityAnimation.name)
                }

                let center = CGPoint(x: CGRectGetMaxX(finalFrame) - 10, y: self.insets.top + self.radius + 15)
                let distanceFromTop = center.y
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
                    let angleOffset = angleInterval * CGFloat(index)
                    let angle = initialAngle + angleOffset
                    let x = center.x + self.radius * cos(angle)
                    let y = center.y - self.radius * sin(angle)
                    let positionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)

                    positionAnimation.fromValue = NSValue(CGPoint: center)
                    positionAnimation.toValue = NSValue(CGPoint: CGPoint(x: x, y: y))
                    positionAnimation.springBounciness = 20
                    positionAnimation.name = "move"
                    positionAnimation.beginTime = CACurrentMediaTime() + 0.1

                    button.layer.position = center
                    button.layer.pop_addAnimation(positionAnimation, forKey: positionAnimation.name)
                }
            }
        }
    }

    private var reblogView: UIView!
    private var backgroundView: UIView!
    private var textView: UITextView!
    private var cancelButton: VBFPopFlatButton!
    private var reblogButton: UIButton!
    private var queueButton: UIButton!
    private var scheduleButton: UIButton!

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        self.view.opaque = false
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)

        self.reblogView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        self.reblogView.backgroundColor = UIColor.clearColor()

        self.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        self.backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        self.backgroundView.layer.cornerRadius = 5
        self.backgroundView.clipsToBounds = true

        self.textView = UITextView()
        self.textView.backgroundColor = UIColor.clearColor()
        self.textView.textColor = UIColor.whiteColor()
        self.textView.font = UIFont.systemFontOfSize(18)

        self.cancelButton = VBFPopFlatButton(
            frame: CGRect(origin: CGPointZero, size: CGSize(width: 20, height: 20)),
            buttonType: FlatButtonType.buttonCloseType,
            buttonStyle: FlatButtonStyle.buttonPlainStyle
        )
        self.cancelButton.lineThickness = 2
        self.cancelButton.tintColor = UIColor.whiteColor()
        self.cancelButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.cancelButton.sizeToFit()

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

        self.reblogView.addSubview(self.backgroundView)
        self.reblogView.addSubview(self.textView)
        self.reblogView.addSubview(self.cancelButton)
        self.reblogView.addSubview(self.reblogButton)
        self.reblogView.addSubview(self.queueButton)
        self.reblogView.addSubview(self.scheduleButton)

        self.view.addSubview(self.reblogView)

        self.backgroundView.snp_makeConstraints { make in
            let insets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
            make.edges.equalTo(self.reblogView).insets(self.insets)
        }

        self.textView.snp_makeConstraints { maker in
            let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            maker.edges.equalTo(self.backgroundView).insets(insets)
        }

        self.cancelButton.snp_makeConstraints { make in
            make.centerX.equalTo(self.backgroundView.snp_left)
            make.centerY.equalTo(self.backgroundView.snp_top)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        let topInset = Float(self.insets.top + self.radius)
        self.reblogButton.snp_makeConstraints { (maker) -> () in
            maker.centerX.equalTo(self.view.snp_right).offset(-30)
            maker.centerY.equalTo(self.view.snp_top).offset(topInset)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }
        
        self.queueButton.snp_makeConstraints { (maker) -> () in
            maker.centerX.equalTo(self.view.snp_right).offset(-30)
            maker.centerY.equalTo(self.view.snp_top).offset(topInset)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }
        
        self.scheduleButton.snp_makeConstraints { (maker) -> () in
            maker.centerX.equalTo(self.view.snp_right).offset(-30)
            maker.centerY.equalTo(self.view.snp_top).offset(topInset)
            maker.height.equalTo(40)
            maker.width.equalTo(40)
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.textView.becomeFirstResponder()
    }

    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue

            self.keyboardFrame = keyboardFrameValue.CGRectValue()
        }
    }

    func exit(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

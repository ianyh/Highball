//
//  ReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/9/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class ReblogViewController: UIViewController {
    var reblogType: ReblogType!
    var post: Post!
    var blog: Blog!

    private let radius: CGFloat = 30
    private let insets = UIEdgeInsets(top: 40, left: 20, bottom: 20, right: 20)

    private var keyboardFrame: CGRect! {
        didSet {
            if let keyboardFrame = self.keyboardFrame {
                var finalFrame = self.view.bounds
                finalFrame.size.height -= keyboardFrame.size.height

                var startingFrame = CGRectInset(finalFrame, 40, 40)
                startingFrame.origin.y += 100

                self.reblogView.pop_removeAllAnimations()

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
            }
        }
    }

    private var reblogView: UIView!
    private var backgroundView: UIView!
    private var textView: UITextView!
    private var cancelButton: VBFPopFlatButton!
    private var finishButton: VBFPopFlatButton!
    private var finishLabel: UILabel!

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
            buttonStyle: FlatButtonStyle.buttonRoundedStyle
        )
        self.cancelButton.lineThickness = 2
        self.cancelButton.tintColor = UIColor.whiteColor()
        self.cancelButton.roundBackgroundColor = UIColor.blackColor()
        self.cancelButton.addTarget(self, action: Selector("exit:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.cancelButton.sizeToFit()

        self.finishButton = VBFPopFlatButton(
            frame: CGRect(origin: CGPointZero, size: CGSize(width: 20, height: 20)),
            buttonType: FlatButtonType.buttonAddType,
            buttonStyle: FlatButtonStyle.buttonRoundedStyle
        )
        self.finishButton.lineThickness = 2
        self.finishButton.tintColor = UIColor.whiteColor()
        self.finishButton.roundBackgroundColor = UIColor.blackColor()
        self.finishButton.addTarget(self, action: Selector("finish:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.finishButton.sizeToFit()

        self.finishLabel = UILabel()
        self.finishLabel.textColor = UIColor.whiteColor()
        self.finishLabel.font = UIFont.systemFontOfSize(14)
        if let reblogType = self.reblogType {
            switch reblogType {
            case .Reblog:
                self.finishLabel.text = "reblog"
            case .Queue:
                self.finishLabel.text = "queue"
            }
        }

        self.reblogView.addSubview(self.backgroundView)
        self.reblogView.addSubview(self.textView)
        self.reblogView.addSubview(self.cancelButton)
        self.reblogView.addSubview(self.finishButton)
        self.reblogView.addSubview(self.finishLabel)

        self.view.addSubview(self.reblogView)

        self.backgroundView.snp_makeConstraints { make in
            let insets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
            make.edges.equalTo(self.reblogView).insets(self.insets)
        }

        self.textView.snp_makeConstraints { maker in
            let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            maker.edges.equalTo(self.backgroundView).insets(insets)
        }

        self.cancelButton.snp_makeConstraints { make in
            make.centerX.equalTo(self.backgroundView.snp_left)
            make.centerY.equalTo(self.backgroundView.snp_top)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        self.finishButton.snp_makeConstraints { make in
            make.centerX.equalTo(self.backgroundView.snp_right)
            make.centerY.equalTo(self.backgroundView.snp_top)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        self.finishLabel.snp_makeConstraints { make in
            make.right.equalTo(self.finishButton.snp_left).with.offset(-10)
            make.bottom.equalTo(self.backgroundView.snp_top)
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

    func finish(sender: UIButton) {
        var parameters = [ "id" : "\(self.post.id)", "reblog_key" : self.post.reblogKey ]

        switch self.reblogType as ReblogType {
        case .Reblog:
            parameters["state"] = "published"
        case .Queue:
            parameters["state"] = "queue"
        }

        TMAPIClient.sharedInstance().reblogPost(self.blog.name, parameters: parameters) { response, error in
            if let e = error {
                println(e)
            } else {
                println("reblog success")
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

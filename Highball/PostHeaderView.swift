//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import TMCache
import TMTumblrSDK

class PostHeaderView: UICollectionReusableView {
    var tapHandler: ((Post, UIView) -> ())?

    private let avatarLoadQueue = dispatch_queue_create("avatarLoadQueue", nil)
    private var avatarImageView: UIImageView!
    private var usernameLabel: UILabel!
    private var topUsernameLabel: UILabel!
    private var bottomUsernameLabel: UILabel!
    private var timeLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let blogName = post.blogName

                avatarImageView.image = UIImage(named: "Placeholder")

                if let data = TMCache.sharedCache().objectForKey("avatar:\(blogName)") as? NSData {
                    dispatch_async(self.avatarLoadQueue, {
                        let image = UIImage(data: data)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.avatarImageView.image = image
                        })
                    })
                } else {
                    TMAPIClient.sharedInstance().avatar(blogName, size: 80) { (response: AnyObject!, error: NSError!) in
                        if let e = error {
                            println(e)
                        } else {
                            let data = response as! NSData!
                            TMCache.sharedCache().setObject(data, forKey: "avatar:\(blogName)")
                            dispatch_async(self.avatarLoadQueue, {
                                let image = UIImage(data: data)
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.avatarImageView.image = image
                                })
                            })
                        }
                    }
                }

                if let rebloggedBlogName = post.rebloggedBlogName {
                    usernameLabel.text = nil
                    topUsernameLabel.text = blogName
                    bottomUsernameLabel.text = rebloggedBlogName
                } else {
                    usernameLabel.text = blogName
                    topUsernameLabel.text = nil
                    bottomUsernameLabel.text = nil
                }

                timeLabel.text = NSDate(timeIntervalSince1970: NSTimeInterval(post.timestamp)).stringWithRelativeFormat()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpCell()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }

    private func setUpCell() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        layout(blurView, self) { blurView, view in
            blurView.edges == view.edges; return
        }

        avatarImageView = UIImageView()
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true

        usernameLabel = UILabel()
        usernameLabel.font = UIFont.boldSystemFontOfSize(16)
        usernameLabel.textColor = UIColor.whiteColor()

        topUsernameLabel = UILabel()
        topUsernameLabel.font = UIFont.boldSystemFontOfSize(16)
        topUsernameLabel.textColor = UIColor.whiteColor()

        bottomUsernameLabel = UILabel()
        bottomUsernameLabel.font = UIFont.systemFontOfSize(12)
        bottomUsernameLabel.textColor = UIColor.whiteColor()

        timeLabel = UILabel()
        timeLabel.font = UIFont.systemFontOfSize(14)
        timeLabel.textColor = UIColor.whiteColor()

        let button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.addTarget(self, action: Selector("tap:"), forControlEvents: UIControlEvents.TouchUpInside)

        addSubview(avatarImageView)
        addSubview(usernameLabel)
        addSubview(topUsernameLabel)
        addSubview(bottomUsernameLabel)
        addSubview(timeLabel)
        addSubview(button)

        constrain(avatarImageView, self) { avatarImageView, contentView in
            avatarImageView.centerY == contentView.centerY
            avatarImageView.left == contentView.left + 4
            avatarImageView.width == 40
            avatarImageView.height == 40
        }

        constrain(usernameLabel, avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 30
        }

        constrain(topUsernameLabel, avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY - 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }

        constrain(bottomUsernameLabel, avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY + 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }

        constrain(timeLabel, usernameLabel, self) { timeLabel, usernameLabel, contentView in
            timeLabel.centerY == contentView.centerY
            timeLabel.right == contentView.right - 8.0
            timeLabel.height == 30
        }

        constrain(button, self) { button, contentView in
            button.edges == contentView.edges; return
        }
    }

    func tap(sender: UIButton) {
        if let tapHandler = tapHandler {
            if let post = post {
                tapHandler(post, self)
            }
        }
    }
}

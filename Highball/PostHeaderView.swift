//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostHeaderView: UITableViewHeaderFooterView {
    var tapHandler: ((Post) -> ())?

    private let avatarLoadQueue = dispatch_queue_create("avatarLoadQueue", nil)
    private var avatarImageView: UIImageView!
    private var usernameLabel: UILabel!
    private var topUsernameLabel: UILabel!
    private var bottomUsernameLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let blogName = post.blogName

                self.avatarImageView.image = UIImage(named: "Placeholder")

                if let data = TMCache.sharedCache().objectForKey("avatar:\(blogName)") as? NSData {
                    dispatch_async(self.avatarLoadQueue, {
                        let image = UIImage(data: data)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.avatarImageView.image = image
                        })
                    })
                } else {
                    TMAPIClient.sharedInstance().avatar(blogName, size: 40) { (response: AnyObject!, error: NSError!) in
                        if let e = error {
                            println(e)
                        } else {
                            let data = response as NSData!
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
                    self.usernameLabel.text = nil
                    self.topUsernameLabel.text = blogName
                    self.bottomUsernameLabel.text = rebloggedBlogName
                } else {
                    self.usernameLabel.text = blogName
                    self.topUsernameLabel.text = nil
                    self.bottomUsernameLabel.text = nil
                }
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
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        self.backgroundView = blurView

        self.avatarImageView = UIImageView()
        self.avatarImageView.layer.cornerRadius = 20
        self.avatarImageView.clipsToBounds = true

        self.usernameLabel = UILabel()
        self.usernameLabel.font = UIFont.boldSystemFontOfSize(16)
        self.usernameLabel.textColor = UIColor.whiteColor()

        self.topUsernameLabel = UILabel()
        self.topUsernameLabel.font = UIFont.boldSystemFontOfSize(16)
        self.topUsernameLabel.textColor = UIColor.whiteColor()

        self.bottomUsernameLabel = UILabel()
        self.bottomUsernameLabel.font = UIFont.systemFontOfSize(12)
        self.bottomUsernameLabel.textColor = UIColor.whiteColor()

        let button = UIButton.buttonWithType(UIButtonType.System) as UIButton
        button.addTarget(self, action: Selector("tap:"), forControlEvents: UIControlEvents.TouchUpInside)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.topUsernameLabel)
        self.contentView.addSubview(self.bottomUsernameLabel)
        self.contentView.addSubview(button)

        layout(self.avatarImageView, self.contentView) { avatarImageView, contentView in
            avatarImageView.centerY == contentView.centerY
            avatarImageView.left == contentView.left + 4
            avatarImageView.width == 40
            avatarImageView.height == 40
        }

        layout(self.usernameLabel, self.avatarImageView, self.contentView) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 30
        }

        layout(self.topUsernameLabel, self.avatarImageView, self.contentView) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY - 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }

        layout(self.bottomUsernameLabel, self.avatarImageView, self.contentView) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY + 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }

        layout(button, self.contentView) { button, contentView in
            button.edges == contentView.edges; return
        }
    }

    func tap(sender: UIButton) {
        if let tapHandler = self.tapHandler {
            if let post = self.post {
                tapHandler(post)
            }
        }
    }
}

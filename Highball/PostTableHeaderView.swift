//
//  PostTableHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 3/7/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography
import PINCache
import TMTumblrSDK

class PostTableHeaderView: UITableViewHeaderFooterView {
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
                
                if let data = PINCache.sharedCache().objectForKey("avatar:\(blogName)") as? NSData {
                    dispatch_async(self.avatarLoadQueue, {
                        let image = UIImage(data: data)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.avatarImageView.image = image
                        })
                    })
                } else {
                    TMAPIClient.sharedInstance().avatar(blogName, size: 80) { (response: AnyObject!, error: NSError!) in
                        if let e = error {
                            print(e)
                        } else {
                            let data = response as! NSData!
                            PINCache.sharedCache().setObject(data, forKey: "avatar:\(blogName)")
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
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpCell()
    }
    
    func setUpCell() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        self.addSubview(blurView)
        constrain(blurView, self) { blurView, view in
            blurView.edges == view.edges; return
        }
        
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

        self.addSubview(self.avatarImageView)
        self.addSubview(self.usernameLabel)
        self.addSubview(self.topUsernameLabel)
        self.addSubview(self.bottomUsernameLabel)
        
        constrain(self.avatarImageView, self) { avatarImageView, contentView in
            avatarImageView.centerY == contentView.centerY
            avatarImageView.left == contentView.left + 4
            avatarImageView.width == 40
            avatarImageView.height == 40
        }
        
        constrain(self.usernameLabel, self.avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 30
        }
        
        constrain(self.topUsernameLabel, self.avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY - 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }
        
        constrain(self.bottomUsernameLabel, self.avatarImageView, self) { usernameLabel, avatarImageView, contentView in
            usernameLabel.centerY == contentView.centerY + 8
            usernameLabel.left == avatarImageView.right + 4
            usernameLabel.height == 20
        }
    }
}

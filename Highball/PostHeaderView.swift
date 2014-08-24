//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography

class PostHeaderView: UITableViewHeaderFooterView {

    var avatarImageView: UIImageView!
    var usernameLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let blogName = post.blogName
                TMAPIClient.sharedInstance().avatar(blogName, size: 30) { (response: AnyObject!, error: NSError!) -> Void in
                    if let e = error {
                        println(e)
                    } else {
                        let data = response as NSData!
                        self.avatarImageView.image = UIImage(data: data)
                    }
                }
                
                self.usernameLabel.text = blogName
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
        self.avatarImageView = UIImageView()
        self.usernameLabel = UILabel()

        self.avatarImageView.layer.cornerRadius = 15
        self.avatarImageView.clipsToBounds = true

        self.usernameLabel.font = UIFont.systemFontOfSize(14)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)

        layout(self.avatarImageView, self.usernameLabel, self.contentView) { (imageView, label, view) -> () in
            imageView.centerY == view.centerY
            imageView.left == view.left + 4
            imageView.width == 30
            imageView.height == 30

            label.centerY == view.centerY
            label.left == imageView.right + 4
            label.height == 30
        }
    }
}

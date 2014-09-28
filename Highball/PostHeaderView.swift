//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostHeaderView: UITableViewHeaderFooterView {
    private var avatarImageView: UIImageView!
    private var usernameLabel: UILabel!

    var post: Post? {
        didSet {
            if let post = self.post {
                let blogName = post.blogName

                self.avatarImageView.image = UIImage(named: "Placeholder")

                TMAPIClient.sharedInstance().avatar(blogName, size: 40) { (response: AnyObject!, error: NSError!) in
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
        self.contentView.backgroundColor = UIColor.blackColor()

        self.avatarImageView = UIImageView()
        self.avatarImageView.layer.cornerRadius = 20
        self.avatarImageView.clipsToBounds = true

        self.usernameLabel = UILabel()
        self.usernameLabel.font = UIFont.boldSystemFontOfSize(16)
        self.usernameLabel.textColor = UIColor.whiteColor()

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)

        self.avatarImageView.snp_makeConstraints { (maker) -> () in
            maker.centerY.equalTo(self.contentView.snp_centerY)
            maker.left.equalTo(self.contentView.snp_left).offset(4)
            maker.width.equalTo(40)
            maker.height.equalTo(40)
        }

        self.usernameLabel.snp_makeConstraints { (maker) -> () in
            maker.centerY.equalTo(self.contentView.snp_centerY)
            maker.left.equalTo(self.avatarImageView.snp_right).offset(4)
            maker.height.equalTo(30)
        }
    }
}

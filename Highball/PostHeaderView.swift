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

    var reblogHandler: ((Post?, ReblogType) -> ())?

    private var avatarImageView: UIImageView!
    private var usernameLabel: UILabel!

    var reblogButton: ReblogButton!

    var post: Post? {
        didSet {
            if let post = self.post {
                let blogName = post.blogName

                self.avatarImageView.image = UIImage(named: "Placeholder")

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
        self.contentView.backgroundColor = UIColor.blackColor()

        self.avatarImageView = UIImageView()
        self.usernameLabel = UILabel()

        self.avatarImageView.layer.cornerRadius = 15
        self.avatarImageView.clipsToBounds = true

        self.usernameLabel.font = UIFont.systemFontOfSize(14)
        self.usernameLabel.textColor = UIColor.whiteColor()

        self.reblogButton = ReblogButton(frame: CGRectZero)

        weak var weakSelf = self
        self.reblogButton.reblogHandler = { type in
            if let strongSelf = weakSelf {
                if let reblogHandler = strongSelf.reblogHandler {
                    reblogHandler(self.post, type)
                }
            }
        }

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.reblogButton)

        layout2(self.avatarImageView, self.contentView) { imageView, view in
            imageView.centerY == view.centerY
            imageView.left == view.left + 4
            imageView.width == 40
            imageView.height == 40
        }

        layout3(self.avatarImageView, self.usernameLabel, self.contentView) { imageView, label, view in
            label.top == view.top + 6
            label.left == imageView.right + 4
            label.height == 30
        }

        layout2(self.reblogButton, self.contentView) { button, view in
            button.right == view.right - 4
            button.centerY == view.centerY
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.reblogButton.showingOptions = false
    }

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let superHitTest = super.hitTest(point, withEvent: event)
        if let view = superHitTest {
            let convertedPoint = self.convertPoint(point, toView: self.reblogButton)
            return self.reblogButton.hitTest(convertedPoint, withEvent: event)
        }

        return superHitTest
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let superPointInside = super.pointInside(point, withEvent: event)
        if !superPointInside {
            let convertedPoint = self.convertPoint(point, toView: self.reblogButton)
            return self.reblogButton.pointInside(convertedPoint, withEvent: event)
        }

        return superPointInside
    }

}

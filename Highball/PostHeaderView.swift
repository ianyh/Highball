//
//  PostHeaderView.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/29/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class PostHeaderView: UITableViewHeaderFooterView {
//    var reblogHandler: ((Post?, ReblogType) -> ())?
    var startHandler: ((CGPoint) -> ())?

    private var avatarImageView: UIImageView!
    private var usernameLabel: UILabel!

//    var reblogButton: ReblogButton!
    var reblogButton: UIButton!

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
        self.usernameLabel = UILabel()

        self.avatarImageView.layer.cornerRadius = 20
        self.avatarImageView.clipsToBounds = true

        self.usernameLabel.font = UIFont.systemFontOfSize(14)
        self.usernameLabel.textColor = UIColor.whiteColor()

//        self.reblogButton = ReblogButton(frame: CGRectZero)
        self.reblogButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.reblogButton.setImage(UIImage(named: "Start"), forState: UIControlState.Normal)

//        weak var weakSelf = self
//        self.reblogButton.reblogHandler = { type in
//            if let strongSelf = weakSelf {
//                if let reblogHandler = strongSelf.reblogHandler {
//                    reblogHandler(self.post, type)
//                }
//            }
//        }

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.reblogButton)

        self.avatarImageView.snp_makeConstraints { (maker) -> () in
            maker.centerY.equalTo(self.contentView.snp_centerY)
            maker.left.equalTo(self.contentView.snp_left).offset(4)
            maker.width.equalTo(40)
            maker.height.equalTo(40)
        }

        self.usernameLabel.snp_makeConstraints { (maker) -> () in
            maker.top.equalTo(self.contentView.snp_top).offset(6)
            maker.left.equalTo(self.avatarImageView.snp_right).offset(4)
            maker.height.equalTo(30)
        }

        self.reblogButton.snp_makeConstraints { (maker) -> () in
            maker.right.equalTo(self.contentView.snp_right).offset(-4)
            maker.centerY.equalTo(self.contentView.snp_centerY)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

//        self.reblogButton.showingOptions = false
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

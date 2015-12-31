//
//  PostTableViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/27/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography
import WCFastCell

class PostTableViewCell: WCFastCell {
    private var postViewController: PostViewController!
    var bodyHeight: CGFloat? = 0.0
    var secondaryBodyHeight: CGFloat? = 0.0
    var post: Post? {
        didSet {
            guard let post = post else {
                return
            }

            postViewController.post = post
            postViewController.bodyHeight = bodyHeight
            postViewController.secondaryBodyHeight = secondaryBodyHeight
        }
    }

    var bodyTapHandler: ((Post, UIView) -> ())?
    var tagTapHandler: ((Post, String) -> ())?
    var linkTapHandler: ((Post, NSURL) -> ())?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        postViewController = PostViewController()
        postViewController.bodyTapHandler = { self.bodyTapHandler?($0, $1) }
        postViewController.tagTapHandler = { self.tagTapHandler?($0, $1) }
        postViewController.linkTapHandler = { self.linkTapHandler?($0, $1) }

        contentView.addSubview(postViewController.view)

        constrain(postViewController.view, contentView) { singlePostView, contentView in
            singlePostView.edges == contentView.edges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func imageAtPoint(point: CGPoint) -> UIImage? {
        return postViewController.imageAtPoint(convertPoint(point, toView: postViewController.view))
    }

    func endDisplay() {
        postViewController.endDisplay()
    }
}

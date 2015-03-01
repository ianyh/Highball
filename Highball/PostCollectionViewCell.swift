//
//  PostCollectionViewCell.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/22/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit

class PostCollectionViewCell: UICollectionViewCell {
    private var postViewController: PostViewController!
    var bodyHeight: CGFloat? = 0.0
    var secondaryBodyHeight: CGFloat? = 0.0
    var post: Post? {
        didSet {
            if let post = self.post {
                self.postViewController.post = post
                self.postViewController.bodyHeight = self.bodyHeight
                self.postViewController.secondaryBodyHeight = self.secondaryBodyHeight
            }
        }
    }

    var headerTapHandler: ((Post, UIView) -> ())?
    var bodyTapHandler: ((Post, UIView) -> ())?

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.postViewController = PostViewController()
        self.postViewController.headerTapHandler = { post, view in
            if let headerTapHandler = self.headerTapHandler {
                headerTapHandler(post, view)
            }
        }
        self.postViewController.bodyTapHandler = { post, view in
            if let bodyTapHandler = self.bodyTapHandler {
                bodyTapHandler(post, view)
            }
        }

        self.contentView.addSubview(self.postViewController.view)
        
        layout(self.postViewController.view, self.contentView) { singlePostView, contentView in
            singlePostView.edges == contentView.edges; return
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func endDisplay() {
        
    }
}

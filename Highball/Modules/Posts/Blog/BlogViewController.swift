//
//  BlogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import FontAwesomeKit

public class BlogViewController: PostsViewController {
	internal var blogPresenter: BlogPresenter?

	public override weak var presenter: PostsPresenter? {
		get {
			return blogPresenter as? PostsPresenter
		}
		set {
			guard let presenter = newValue as? BlogPresenter else {
				fatalError()
			}

			blogPresenter = presenter
		}
	}

	public init(blogName: String, postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		let followIcon = FAKIonIcons.iosPersonaddOutlineIconWithSize(30)
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			image: followIcon.imageWithSize(CGSize(width: 30, height: 30)),
			style: UIBarButtonItemStyle.Plain,
			target: self,
			action: #selector(follow(_:))
		)
		navigationItem.title = blogName
	}

	public override init(postHeightCache: PostHeightCache) {
		fatalError("init() has not been implemented")
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func follow(sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

		alertController.addAction(UIAlertAction(title: "Follow", style: .Default) { [weak self] action in
			self?.blogPresenter?.follow()
		})

		alertController.addAction(UIAlertAction(title: "Unfollow", style: .Destructive) { [weak self] action in
			self?.blogPresenter?.unfollow()
		})

		alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

		presentViewController(alertController, animated: true, completion: nil)
	}
}

//
//  BlogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import FontAwesomeKit

open class BlogViewController: PostsViewController {
	internal var blogPresenter: BlogPresenter?

	open override var presenter: PostsPresenter? {
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

		let followIcon = FAKIonIcons.iosPersonaddOutlineIcon(withSize: 30)
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			image: followIcon?.image(with: CGSize(width: 30, height: 30)),
			style: UIBarButtonItemStyle.plain,
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

	open func follow(_ sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		alertController.addAction(UIAlertAction(title: "Follow", style: .default) { [weak self] _ in
			self?.blogPresenter?.follow()
		})

		alertController.addAction(UIAlertAction(title: "Unfollow", style: .destructive) { [weak self] _ in
			self?.blogPresenter?.unfollow()
		})

		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

		present(alertController, animated: true, completion: nil)
	}
}

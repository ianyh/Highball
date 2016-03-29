//
//  BlogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/21/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import SwiftyJSON
import FontAwesomeKit
import TMTumblrSDK

class BlogViewController: PostsViewController {
	private let blogName: String!

	required init(blogName: String) {
		self.blogName = blogName

		super.init()

		let followIcon = FAKIonIcons.iosPersonaddOutlineIconWithSize(30)
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			image: followIcon.imageWithSize(CGSize(width: 30, height: 30)),
			style: UIBarButtonItemStyle.Plain,
			target: self,
			action: #selector(BlogViewController.follow(_:))
		)
		navigationItem.title = blogName
	}

	required override init() {
		fatalError("init() has not been implemented")
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func postsFromJSON(json: JSON) -> Array<Post> {
		guard let postsJSON = json["posts"].array else {
			return []
		}

		return postsJSON.map { (post) -> (Post) in
			return Post(json: post)
		}
	}

	override func requestPosts(postCount: Int, parameters: Dictionary<String, AnyObject>, callback: TMAPICallback) {
		TMAPIClient.sharedInstance().posts(self.blogName, type: "", parameters: parameters, callback: callback)
	}

	func follow(sender: UIBarButtonItem) {
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

		alertController.addAction(UIAlertAction(title: "Follow", style: .Default) { action in
			TMAPIClient.sharedInstance().follow(self.blogName) { result, error in
				let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)

				if let _ = error {
					alertController.title = "Follow Failed"
					alertController.message = "Tried to follow \(self.blogName), but failed."
				} else {
					alertController.title = "Followed"
					alertController.message = "Successfully followed \(self.blogName)!"
				}

				alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

				self.presentViewController(alertController, animated: true, completion: nil)
			}
		})

		alertController.addAction(UIAlertAction(title: "Unfollow", style: .Destructive) { action in
			TMAPIClient.sharedInstance().unfollow(self.blogName) { result, error in
				let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)

				if let _ = error {
					alertController.title = "Unfollow Failed"
					alertController.message = "Tried to unfollow \(self.blogName), but failed."
				} else {
					alertController.title = "Unfollowed"
					alertController.message = "Successfully unfollowed \(self.blogName)!"
				}

				alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

				self.presentViewController(alertController, animated: true, completion: nil)
			}
		})

		alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

		presentViewController(alertController, animated: true, completion: nil)
	}
}

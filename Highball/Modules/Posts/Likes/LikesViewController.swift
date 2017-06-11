//
//  LikesViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import SwiftyJSON
import TMTumblrSDK
import UIKit

final class LikesViewController: PostsViewController {
	override init(postHeightCache: PostHeightCache) {
		super.init(postHeightCache: postHeightCache)

		navigationItem.title = "Likes"
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func filter() {
		let filtersViewController = LikesFiltersViewController { [weak self] type, date in
			guard let strongSelf = self else {
				return
			}

			switch type {
			case "video", "photo":
				strongSelf.presenter?.dataManager?.type = type
			default:
				strongSelf.presenter?.dataManager?.type = nil
			}

			strongSelf.presenter?.dataManager?.date = date
			strongSelf.tableViewAdapter?.resetCache()
			strongSelf.presenter?.viewDidRefresh()
			strongSelf.dismiss(animated: true, completion: nil)
		}
		let navigationController = UINavigationController(rootViewController: filtersViewController)
		present(navigationController, animated: true, completion: nil)
	}
}

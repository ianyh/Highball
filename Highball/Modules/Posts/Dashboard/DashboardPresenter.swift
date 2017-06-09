//
//  DashboardPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

open class DashboardPresenter: PostsPresenter {
	open weak var view: PostsView?
	open var dataManager: PostsDataManager?
	open var loadingCompletion: (() -> Void)?

	open func viewDidDisappear() {

	}

	open func isViewingBookmark() -> Bool {
		return dataManager?.topID != nil
	}

	open func bookmarkPostAtIndex(_ index: Int) {
		guard let dataManager = dataManager, let accountName = AccountsService.account?.name else {
			return
		}

		let userDefaults = UserDefaults.standard
		let bookmarksKey = "HIBookmarks:\(accountName)"
		let post = dataManager.posts[index]
		var bookmarks = userDefaults.array(forKey: bookmarksKey) as? [[String: AnyObject]] ?? []

		bookmarks.insert(["date": Date() as AnyObject, "id": post.id as AnyObject], at: 0)

		if bookmarks.count > 20 {
			bookmarks = [[String: AnyObject]](bookmarks.prefix(20))
		}

		userDefaults.set(bookmarks, forKey: bookmarksKey)
	}

	open func goToBookmarkedPostWithID(_ id: Int) {
		guard let view = view, let dataManager = dataManager else {
			return
		}

		dataManager.topID = id
		dataManager.cursor = id
		dataManager.posts = []
		dataManager.loadMore(view.currentWidth())
	}

	public func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: @escaping TMAPICallback) {
		TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String? {
		return "posts"
	}
}

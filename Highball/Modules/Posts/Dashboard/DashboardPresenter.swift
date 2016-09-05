//
//  DashboardPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

public class DashboardPresenter: PostsPresenter {
	public weak var view: PostsView?
	public var dataManager: PostsDataManager?
	public var loadingCompletion: (() -> ())?

	public func viewDidDisappear() {

	}

	public func isViewingBookmark() -> Bool {
		return dataManager?.topID != nil
	}

	public func bookmarkPostAtIndex(index: Int) {
		guard let dataManager = dataManager else {
			return
		}

		let userDefaults = NSUserDefaults.standardUserDefaults()
		let bookmarksKey = "HIBookmarks:\(AccountsService.account.primaryBlog.url)"
		let post = dataManager.posts[index]
		var bookmarks = userDefaults.arrayForKey(bookmarksKey) as? [[String: AnyObject]] ?? []

		bookmarks.insert(["date": NSDate(), "id": post.id], atIndex: 0)

		if bookmarks.count > 20 {
			bookmarks = [[String: AnyObject]](bookmarks.prefix(20))
		}

		userDefaults.setObject(bookmarks, forKey: bookmarksKey)
	}

	public func goToBookmarkedPostWithID(id: Int) {
		guard let view = view, dataManager = dataManager else {
			return
		}

		dataManager.topID = id
		dataManager.cursor = id
		dataManager.posts = []
		dataManager.loadMore(view.currentWidth())
	}
}

public extension DashboardPresenter {
	public func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: TMAPICallback) {
		TMAPIClient.sharedInstance().dashboard(parameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(dataManager: PostsDataManager) -> String? {
		return "posts"
	}
}

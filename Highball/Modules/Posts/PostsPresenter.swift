//
//  PostsPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

public protocol PostsPresenter: class, PostsDataManagerDelegate {
	var view: PostsView? { get }
	var dataManager: PostsDataManager? { get }
	var loadingCompletion: (() -> ())? { get set }
}

public extension PostsPresenter {
	public func viewDidAppear() {
		guard let dataManager = dataManager where !dataManager.hasPosts else {
			return
		}

		refreshPosts()
	}

	public func viewDidRefresh() {
		refreshPosts()
	}

	private func refreshPosts() {
		guard let view = view, dataManager = dataManager else {
			return
		}

		dataManager.loadTop(view.currentWidth())
	}

	public func reloadTable() {
		guard let dataManager = dataManager else {
			return
		}

		guard !dataManager.computingHeights else {
			return
		}

		if dataManager.loadingTop || dataManager.loadingBottom {
			loadingCompletion?()
		}

		view?.finishRefreshing()

		loadingCompletion = nil
		dataManager.loadingTop = false
		dataManager.loadingBottom = false
	}

	public func resetPosts() {
		guard let view = view, dataManager = dataManager else {
			return
		}

		dataManager.topID = nil
		dataManager.posts = []
		dataManager.loadTop(view.currentWidth())
	}
}

public extension PostsPresenter {
	public func dataManagerDidReload(dataManager: PostsDataManager, indexSet: NSIndexSet?, completion: () -> ()) {
		loadingCompletion = { [weak self] in
			completion()
			self?.view?.reloadWithNewIndices(indexSet)
		}
		reloadTable()
	}

	public func dataManagerDidComputeHeight(dataManager: PostsDataManager) {
		reloadTable()
	}

	public func dataManager(dataManager: PostsDataManager, didEncounterError error: NSError) {
		view?.presentMessage("Error", message: "Hit an error trying to load posts. \(error.localizedDescription)")
	}
}

public extension PostsPresenter {
	public func numberOfPosts() -> Int {
		return dataManager?.posts?.count ?? 0
	}

	public func postAtIndex(index: Int) -> Post {
		return dataManager!.posts[index]
	}

	public func toggleLikeForPostAtIndex(index: Int) {
		dataManager?.toggleLikeForPostAtIndex(index)
	}

	public func didEncounterLoadMoreBoundary() {
		guard let dataManager = dataManager, view = view else {
			return
		}

		dataManager.loadMore(view.currentWidth())
	}
}

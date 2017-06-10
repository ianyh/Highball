//
//  PostsPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

protocol PostsPresenter: class, PostsDataManagerDelegate {
	var view: PostsView? { get }
	var dataManager: PostsDataManager? { get }
	var loadingCompletion: (() -> Void)? { get set }
}

extension PostsPresenter {
	func viewDidAppear() {
		guard let dataManager = dataManager, !dataManager.hasPosts else {
			return
		}

		refreshPosts()
	}

	func viewDidRefresh() {
		refreshPosts()
	}

	fileprivate func refreshPosts() {
		guard let view = view, let dataManager = dataManager else {
			return
		}

		dataManager.loadTop(view.currentWidth())
	}

	func reloadTable() {
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

	func resetPosts() {
		guard let view = view, let dataManager = dataManager else {
			return
		}

		dataManager.topID = nil
		dataManager.posts = []
		dataManager.loadTop(view.currentWidth())
	}
}

extension PostsPresenter {
	func dataManagerDidReload(_ dataManager: PostsDataManager, indexSet: IndexSet?, completion: @escaping () -> Void) {
		loadingCompletion = { [weak self] in
			completion()
			self?.view?.reloadWithNewIndices(indexSet)
		}
		reloadTable()
	}

	func dataManagerDidComputeHeight(_ dataManager: PostsDataManager) {
		reloadTable()
	}

	func dataManager(_ dataManager: PostsDataManager, didEncounterError error: NSError) {
		view?.presentMessage("Error", message: "Hit an error trying to load posts. \(error.localizedDescription)")
	}
}

extension PostsPresenter {
	func numberOfPosts() -> Int {
		return dataManager?.posts?.count ?? 0
	}

	func postAtIndex(_ index: Int) -> Post {
		return dataManager!.posts[index]
	}

	func toggleLikeForPostAtIndex(_ index: Int) {
		dataManager?.toggleLikeForPostAtIndex(index)
	}

	func didEncounterLoadMoreBoundary() {
		guard let dataManager = dataManager, let view = view else {
			return
		}

		dataManager.loadMore(view.currentWidth())
	}
}

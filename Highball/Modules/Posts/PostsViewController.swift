//
//  PostsViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/26/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Cartography
import FontAwesomeKit
import SafariServices
import UIKit

protocol PostsView: class {
	var tableView: UITableView! { get }
	var refreshControl: UIRefreshControl? { get }

	var tableViewAdapter: PostsTableViewAdapter? { get }

	func presentViewController(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

extension PostsView {
	func currentWidth() -> CGFloat {
		return tableView.frame.width
	}

	func finishRefreshing() {
		refreshControl?.endRefreshing()
	}

	func reloadWithNewIndices(_ indexSet: IndexSet?) {
		guard let indexSet = indexSet else {
			tableView.reloadData()
			return
		}

		tableViewAdapter?.resetCache()

		// Gross
		UIView.setAnimationsEnabled(false)
		tableView.insertSections(indexSet, with: UITableViewRowAnimation.none)
		UIView.setAnimationsEnabled(true)

		guard indexSet.first == 0 else {
			return
		}

		guard let originalCellIndexPath = tableView.indexPathsForVisibleRows?.first else {
			return
		}

		let originalRow = (originalCellIndexPath as NSIndexPath).row
		let newSection = (originalCellIndexPath as NSIndexPath).section + indexSet.count
		let newIndexPath = IndexPath(row: originalRow, section: newSection)
		tableView.scrollToRow(at: newIndexPath, at: .top, animated: false)

		let newOffset = tableView.contentOffset.y - (refreshControl?.frame.height ?? 0)
		tableView.contentOffset = CGPoint(x: 0, y: newOffset)
	}

	func presentMessage(_ title: String, message: String) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)

		alertController.addAction(action)

		presentViewController(alertController, animated: true, completion: nil)
	}
}

extension PostsViewController: PostsView {}

class PostsViewController: UITableViewController {
	var presenter: PostsPresenter?

	fileprivate let requiredRefreshDistance: CGFloat = 60

	let postHeightCache: PostHeightCache

	fileprivate(set) var tableViewAdapter: PostsTableViewAdapter?

	init(postHeightCache: PostHeightCache) {
		self.postHeightCache = postHeightCache
		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableViewAdapter = PostsTableViewAdapter(
			tableView: tableView,
			postHeightCache: postHeightCache,
			delegate: self
		)

		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		presenter?.viewDidAppear()
	}

	func refresh(_ sender: UIRefreshControl) {
		presenter?.viewDidRefresh()
	}
}

// MARK: UIGestureRecognizerDelegate
extension PostsViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// MARK: UIViewControllerTransitioningDelegate
extension PostsViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return ReblogTransitionAnimator()
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		let animator = ReblogTransitionAnimator()

		animator.presenting = false

		return animator
	}
}

// MARK: TagsTableViewCellDelegate
extension PostsViewController: TagsTableViewCellDelegate {
	func tagsTableViewCell(_ cell: TagsTableViewCell, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}
}

extension PostsViewController: PostsTableViewAdapterDelegate {
	func numberOfPostsForAdapter(_ adapter: PostsTableViewAdapter) -> Int {
		return presenter?.numberOfPosts() ?? 0
	}

	func postAdapter(_ adapter: PostsTableViewAdapter, sectionAdapterAtIndex index: Int) -> PostSectionAdapter {
		let post = presenter!.postAtIndex(index)

		return PostSectionAdapter(
			post: post,
			shareHandler: { photo, _ in
				let activityViewController = UIActivityViewController(
					activityItems: [DataActivityItemSource(url: photo.urlWithWidth(.greatestFiniteMagnitude))],
					applicationActivities: nil
				)
				self.present(activityViewController, animated: true, completion: nil)
			},
			videoShareHandler: { _, videoURL in
				let activityViewController = UIActivityViewController(
					activityItems: [DataActivityItemSource(url: videoURL)],
					applicationActivities: nil
				)
				self.present(activityViewController, animated: true, completion: nil)
			},
			likeHandler: { _, completion in
				self.presenter?.toggleLikeForPostAtIndex(index) { liked in
					completion(liked)
				}
			}
		)
	}

	func adapter(_ adapter: PostsTableViewAdapter, didSelectImageForPostAtIndex index: Int) {
		let viewController = ImagesViewController()
		let post = presenter!.postAtIndex(index)

		viewController.post = post

		present(viewController, animated: true, completion: nil)
	}

	func adapter(_ adapter: PostsTableViewAdapter, didSelectURLForPostAtIndex index: Int) {
		let post = presenter!.postAtIndex(index)
		navigationController?.pushViewController(SFSafariViewController(url: post.url), animated: true)
	}

	func adapter(_ adapter: PostsTableViewAdapter, didSelectBlogName blogName: String) {
		let blogModule = BlogModule(blogName: blogName, postHeightCache: postHeightCache)
		blogModule.installInNavigationController(navigationController!)
	}

	func adapter(_ adapter: PostsTableViewAdapter, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}

	func adapter(_ adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool) {
		if presented {
			present(viewController, animated: true, completion: nil)
		} else {
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

	func adapterDidEncounterLoadMoreBoundary(_ adapter: PostsTableViewAdapter) {
		presenter?.didEncounterLoadMoreBoundary()
	}
}

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
import SwiftyJSON
import TMTumblrSDK
import UIKit
import XExtensionItem

class PostsViewController: UITableViewController {
	private let requiredRefreshDistance: CGFloat = 60

	private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	private var panGestureRecognizer: UIPanGestureRecognizer!
	private var reblogViewController: QuickReblogViewController?

	var postHeightCache = PostHeightCache()

	var tableViewAdapter: PostsTableViewAdapter?
	var dataManager: PostsDataManager!

	private var loadingCompletion: (() -> ())?

	init() {
		super.init(style: .Plain)
		self.dataManager = PostsDataManager(
			postHeightCache: postHeightCache,
			delegate: self
		)
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

		longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(PostsViewController.didLongPress(_:)))
		longPressGestureRecognizer.delegate = self
		longPressGestureRecognizer.minimumPressDuration = 0.3

		if let gestureRecognizers = view.gestureRecognizers {
			for gestureRecognizer in gestureRecognizers {
				guard let gestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer else {
					continue
				}

				gestureRecognizer.requireGestureRecognizerToFail(longPressGestureRecognizer)
			}
		}

		view.addGestureRecognizer(longPressGestureRecognizer)

		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PostsViewController.didPan(_:)))
		panGestureRecognizer.delegate = self
		view.addGestureRecognizer(panGestureRecognizer)

		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(PostsViewController.refresh(_:)), forControlEvents: .ValueChanged)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard !dataManager.hasPosts else {
			return
		}

		dataManager.loadTop(tableView.frame.width)
	}

	func refresh(sender: UIRefreshControl) {
		dataManager.loadTop(tableView.frame.width)
	}

	func postsFromJSON(json: JSON) -> [Post] { return [] }
	func requestPosts(postCount: Int, parameters: [String: AnyObject], callback: TMAPICallback) { NSException().raise() }

	func presentError(error: NSError) {
		let alertController = UIAlertController(title: "Error", message: "Hit an error trying to load posts. \(error.localizedDescription)", preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)

		alertController.addAction(action)

		presentViewController(alertController, animated: true, completion: nil)

		print(error)
	}

	func reloadTable() {
		guard !dataManager.computingHeights else {
			return
		}

		if dataManager.loadingTop || dataManager.loadingBottom {
			loadingCompletion?()
		}

		refreshControl?.endRefreshing()

		loadingCompletion = nil
		dataManager.loadingTop = false
		dataManager.loadingBottom = false
	}
}

// MARK: Quick Reblog
extension PostsViewController {
	func didLongPress(sender: UILongPressGestureRecognizer) {
		if sender.state == UIGestureRecognizerState.Began {
			longPressDidBegin(sender)
		} else if sender.state == UIGestureRecognizerState.Ended {
			longPressDidEnd(sender)
		}
	}

	func longPressDidBegin(gestureRecognizer: UILongPressGestureRecognizer) {
		tableView.scrollEnabled = false
		let point = gestureRecognizer.locationInView(navigationController!.tabBarController!.view)
		let collectionViewPoint = gestureRecognizer.locationInView(tableView)
		if let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint) {
			if let _ = tableView.cellForRowAtIndexPath(indexPath) {
				let post = dataManager.posts[indexPath.section]
				let viewController = QuickReblogViewController()

				viewController.startingPoint = point
				viewController.post = post
				viewController.transitioningDelegate = self
				viewController.modalPresentationStyle = UIModalPresentationStyle.Custom

				viewController.view.bounds = navigationController!.tabBarController!.view.bounds

				navigationController!.tabBarController!.view.addSubview(viewController.view)

				viewController.view.layoutIfNeeded()
				viewController.viewDidAppear(false)

				reblogViewController = viewController
			}
		}
	}

	func longPressDidEnd(gestureRecognizer: UILongPressGestureRecognizer) {
		tableView.scrollEnabled = true

		defer {
			reblogViewController = nil
		}

		guard let viewController = reblogViewController else {
			return
		}

		let point = viewController.startingPoint
		let collectionViewPoint = tableView.convertPoint(point, fromView: navigationController!.tabBarController!.view)

		defer {
			viewController.view.removeFromSuperview()
		}

		guard
			let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint),
			let cell = tableView.cellForRowAtIndexPath(indexPath),
			let quickReblogAction = viewController.reblogAction()
			else {
				return
		}
		var post = dataManager.posts[indexPath.section]

		switch quickReblogAction {
		case .Reblog(let reblogType):
			let reblogViewController = TextReblogViewController(
				post: post,
				reblogType: reblogType,
				blogName: AccountsService.account.blog.name,
				postHeightCache: postHeightCache
			)
			let sourceRect = view.convertRect(cell.bounds, fromView: cell)
			let presentationViewController = reblogViewController.controllerToPresent(fromView: view, rect: sourceRect)

			self.presentViewController(presentationViewController, animated: true, completion: nil)
		case .Share:
			let extensionItemSource = XExtensionItemSource(URL: NSURL(string: post.urlString)!)
			var additionalAttachments: [AnyObject] = post.photos.map { $0.urlWithWidth(CGFloat.max) }

			if let photosetCell = cell as? PhotosetRowTableViewCell, let image = photosetCell.imageAtPoint(view.convertPoint(point, toView: cell)) {
				additionalAttachments.append(image)
			}

			extensionItemSource.additionalAttachments = additionalAttachments

			let activityViewController = UIActivityViewController(activityItems: [extensionItemSource], applicationActivities: nil)
			activityViewController.popoverPresentationController?.sourceView = cell
			activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: cell.center, size: CGSize(width: 1, height: 1))

			presentViewController(activityViewController, animated: true, completion: nil)
		case .Like:
			if post.liked.boolValue {
				TMAPIClient.sharedInstance().unlike("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
					if let error = error {
						self.presentError(error)
					} else {
						post.liked = false
					}
				}
			} else {
				TMAPIClient.sharedInstance().like("\(post.id)", reblogKey: post.reblogKey) { (response, error) in
					if let error = error {
						self.presentError(error)
					} else {
						post.liked = true
					}
				}
			}
		}
	}

	func didPan(sender: UIPanGestureRecognizer) {
		guard let viewController = reblogViewController else {
			return
		}

		viewController.updateWithPoint(sender.locationInView(viewController.view))
	}
}

// MARK: UIGestureRecognizerDelegate
extension PostsViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// MARK: UIViewControllerTransitioningDelegate
extension PostsViewController: UIViewControllerTransitioningDelegate {
	func animationControllerForPresentedController(
		presented: UIViewController,
		presentingController presenting: UIViewController,
		sourceController source: UIViewController
		) -> UIViewControllerAnimatedTransitioning? {
		return ReblogTransitionAnimator()
	}

	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		let animator = ReblogTransitionAnimator()

		animator.presenting = false

		return animator
	}
}

// MARK: TagsTableViewCellDelegate
extension PostsViewController: TagsTableViewCellDelegate {
	func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
		navigationController?.pushViewController(TagViewController(tag: tag), animated: true)
	}
}

// MARK: PostsDataManagerDelegate
extension PostsViewController: PostsDataManagerDelegate {
	func dataManager(dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: TMAPICallback) {
		requestPosts(postCount, parameters: parameters, callback: callback)
	}

	func dataManager(dataManager: PostsDataManager, postsFromJSON json: JSON) -> [Post] {
		return postsFromJSON(json)
	}

	func dataManager(dataManager: PostsDataManager, didEncounterError error: NSError) {
		presentError(error)
	}

	func dataManagerDidReload(dataManager: PostsDataManager, indexSet: NSIndexSet?, completion: () -> ()) {
		loadingCompletion = {
			completion()
			if let indexSet = indexSet {
				self.tableViewAdapter?.resetCache()
				let originalCellIndexPath = self.tableView.indexPathsForVisibleRows?.first

				// Gross
				UIView.setAnimationsEnabled(false)
				self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
				UIView.setAnimationsEnabled(true)

				guard indexSet.firstIndex == 0 else {
					return
				}

				if let originalCellIndexPath = originalCellIndexPath {
					let originalRow = originalCellIndexPath.row
					let newSection = originalCellIndexPath.section + indexSet.count
					let newIndexPath = NSIndexPath(forRow: originalRow, inSection: newSection)
					self.tableView.scrollToRowAtIndexPath(newIndexPath, atScrollPosition: .Top, animated: false)

					let newOffset = self.tableView.contentOffset.y - (self.refreshControl?.frame.height ?? 0)
					self.tableView.contentOffset = CGPoint(x: 0, y: newOffset)
				}
			} else {
				self.tableView.reloadData()
			}
		}
		reloadTable()
	}

	func dataManagerDidComputeHeight(dataManager: PostsDataManager) {
		reloadTable()
	}
}

extension PostsViewController: PostsTableViewAdapterDelegate {
	func postsForAdapter(adapter: PostsTableViewAdapter) -> [Post] {
		return dataManager.posts ?? []
	}

	func adapter(adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool) {
		if presented {
			presentViewController(viewController, animated: true, completion: nil)
		} else {
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

	func adapterDidEncounterLoadMoreBoundary(adapter: PostsTableViewAdapter) {
		dataManager.loadMore(tableView.frame.width)
	}
}

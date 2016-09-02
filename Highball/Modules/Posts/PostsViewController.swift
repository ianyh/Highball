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
import XExtensionItem

public protocol PostsView: class {
	var tableView: UITableView! { get }
	var refreshControl: UIRefreshControl? { get }

	var tableViewAdapter: PostsTableViewAdapter? { get }

	func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

public extension PostsView {
	public func currentWidth() -> CGFloat {
		return tableView.frame.width
	}

	public func finishRefreshing() {
		refreshControl?.endRefreshing()
	}

	public func reloadWithNewIndices(indexSet: NSIndexSet?) {
		guard let indexSet = indexSet else {
			tableView.reloadData()
			return
		}

		tableViewAdapter?.resetCache()

		// Gross
		UIView.setAnimationsEnabled(false)
		tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
		UIView.setAnimationsEnabled(true)

		guard indexSet.firstIndex == 0 else {
			return
		}

		guard let originalCellIndexPath = tableView.indexPathsForVisibleRows?.first else {
			return
		}

		let originalRow = originalCellIndexPath.row
		let newSection = originalCellIndexPath.section + indexSet.count
		let newIndexPath = NSIndexPath(forRow: originalRow, inSection: newSection)
		tableView.scrollToRowAtIndexPath(newIndexPath, atScrollPosition: .Top, animated: false)

		let newOffset = tableView.contentOffset.y - (refreshControl?.frame.height ?? 0)
		tableView.contentOffset = CGPoint(x: 0, y: newOffset)
	}

	public func presentMessage(title: String, message: String) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)

		alertController.addAction(action)

		presentViewController(alertController, animated: true, completion: nil)
	}
}

extension PostsViewController: PostsView {}

public class PostsViewController: UITableViewController {
	public weak var presenter: PostsPresenter?

	private let requiredRefreshDistance: CGFloat = 60

	private var longPressGestureRecognizer: UILongPressGestureRecognizer!
	private var panGestureRecognizer: UIPanGestureRecognizer!
	private var reblogViewController: QuickReblogViewController?

	public let postHeightCache: PostHeightCache

	public private(set) var tableViewAdapter: PostsTableViewAdapter?

	public init(postHeightCache: PostHeightCache) {
		self.postHeightCache = postHeightCache
		super.init(style: .Plain)
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	public override func viewDidLoad() {
		super.viewDidLoad()

		tableViewAdapter = PostsTableViewAdapter(
			tableView: tableView,
			postHeightCache: postHeightCache,
			delegate: self
		)

		longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
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

		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
		panGestureRecognizer.delegate = self
		view.addGestureRecognizer(panGestureRecognizer)

		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh(_:)), forControlEvents: .ValueChanged)
	}

	public override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		presenter?.viewDidAppear()
	}

	public func refresh(sender: UIRefreshControl) {
		presenter?.viewDidRefresh()
	}
}

// MARK: Quick Reblog
public extension PostsViewController {
	public func didLongPress(sender: UILongPressGestureRecognizer) {
		if sender.state == UIGestureRecognizerState.Began {
			longPressDidBegin(sender)
		} else if sender.state == UIGestureRecognizerState.Ended {
			longPressDidEnd(sender)
		}
	}

	public func longPressDidBegin(gestureRecognizer: UILongPressGestureRecognizer) {
		tableView.scrollEnabled = false

		let point = gestureRecognizer.locationInView(navigationController!.tabBarController!.view)
		let collectionViewPoint = gestureRecognizer.locationInView(tableView)

		guard let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint) where tableView.cellForRowAtIndexPath(indexPath) != nil else {
			return
		}

		guard let post = presenter?.postAtIndex(indexPath.section) else {
			return
		}

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

	public func longPressDidEnd(gestureRecognizer: UILongPressGestureRecognizer) {
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

		guard let indexPath = tableView.indexPathForRowAtPoint(collectionViewPoint), cell = tableView.cellForRowAtIndexPath(indexPath) else {
			return
		}

		guard let post = presenter?.postAtIndex(indexPath.section), quickReblogAction = viewController.reblogAction() else {
			return
		}

		switch quickReblogAction {
		case .Reblog(let reblogType):
			let reblogViewController = TextReblogViewController(
				post: post,
				reblogType: reblogType,
				blogName: AccountsService.account.primaryBlog.name,
				postHeightCache: postHeightCache
			)
			let sourceRect = view.convertRect(cell.bounds, fromView: cell)
			let presentationViewController = reblogViewController.controllerToPresent(fromView: view, rect: sourceRect)

			presentViewController(presentationViewController, animated: true, completion: nil)
		case .Share:
			let extensionItemSource = XExtensionItemSource(URL: post.url)
			var additionalAttachments: [AnyObject] = post.photos.map { $0.urlWithWidth(CGFloat.max) }

			if let photosetCell = cell as? PhotosetRowTableViewCell, image = photosetCell.imageAtPoint(view.convertPoint(point, toView: cell)) {
				additionalAttachments.append(image)
			}

			extensionItemSource.additionalAttachments = additionalAttachments

			let activityViewController = UIActivityViewController(activityItems: [extensionItemSource], applicationActivities: nil)
			activityViewController.popoverPresentationController?.sourceView = cell
			activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: cell.center, size: CGSize(width: 1, height: 1))

			presentViewController(activityViewController, animated: true, completion: nil)
		case .Like:
			presenter?.toggleLikeForPostAtIndex(indexPath.section)
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
	public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// MARK: UIViewControllerTransitioningDelegate
extension PostsViewController: UIViewControllerTransitioningDelegate {
	public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return ReblogTransitionAnimator()
	}

	public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		let animator = ReblogTransitionAnimator()

		animator.presenting = false

		return animator
	}
}

// MARK: TagsTableViewCellDelegate
extension PostsViewController: TagsTableViewCellDelegate {
	public func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}
}

extension PostsViewController: PostsTableViewAdapterDelegate {
	public func numberOfPostsForAdapter(adapter: PostsTableViewAdapter) -> Int {
		return presenter?.numberOfPosts() ?? 0
	}

	public func postAdapter(adapter: PostsTableViewAdapter, sectionAdapterAtIndex index: Int) -> PostSectionAdapter {
		let post = presenter!.postAtIndex(index)
		return PostSectionAdapter(post: post)
	}

	public func adapter(adapter: PostsTableViewAdapter, didSelectImageForPostAtIndex index: Int) {
		let viewController = ImagesViewController()
		let post = presenter!.postAtIndex(index)

		viewController.post = post

		presentViewController(viewController, animated: true, completion: nil)
	}

	public func adapter(adapter: PostsTableViewAdapter, didSelectURLForPostAtIndex index: Int) {
		let post = presenter!.postAtIndex(index)
		navigationController?.pushViewController(SFSafariViewController(URL: post.url), animated: true)
	}

	public func adapter(adapter: PostsTableViewAdapter, didSelectBlogName blogName: String) {
		let blogModule = BlogModule(blogName: blogName, postHeightCache: postHeightCache)
		blogModule.installInNavigationController(navigationController!)
	}

	public func adapter(adapter: PostsTableViewAdapter, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}

	public func adapter(adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool) {
		if presented {
			presentViewController(viewController, animated: true, completion: nil)
		} else {
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

	public func adapterDidEncounterLoadMoreBoundary(adapter: PostsTableViewAdapter) {
		presenter?.didEncounterLoadMoreBoundary()
	}
}

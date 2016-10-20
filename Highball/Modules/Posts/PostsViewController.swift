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

	func presentViewController(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

public extension PostsView {
	public func currentWidth() -> CGFloat {
		return tableView.frame.width
	}

	public func finishRefreshing() {
		refreshControl?.endRefreshing()
	}

	public func reloadWithNewIndices(_ indexSet: IndexSet?) {
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

	public func presentMessage(_ title: String, message: String) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)

		alertController.addAction(action)

		presentViewController(alertController, animated: true, completion: nil)
	}
}

extension PostsViewController: PostsView {}

open class PostsViewController: UITableViewController {
	open var presenter: PostsPresenter?

	fileprivate let requiredRefreshDistance: CGFloat = 60

	fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer!
	fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
	fileprivate var reblogViewController: QuickReblogViewController?

	open let postHeightCache: PostHeightCache

	open fileprivate(set) var tableViewAdapter: PostsTableViewAdapter?

	public init(postHeightCache: PostHeightCache) {
		self.postHeightCache = postHeightCache
		super.init(style: .plain)
	}

	public required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	open override func viewDidLoad() {
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

				gestureRecognizer.require(toFail: longPressGestureRecognizer)
			}
		}

		view.addGestureRecognizer(longPressGestureRecognizer)

		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
		panGestureRecognizer.delegate = self
		view.addGestureRecognizer(panGestureRecognizer)

		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		presenter?.viewDidAppear()
	}

	open func refresh(_ sender: UIRefreshControl) {
		presenter?.viewDidRefresh()
	}
}

// MARK: Quick Reblog
public extension PostsViewController {
	public func didLongPress(_ sender: UILongPressGestureRecognizer) {
		if sender.state == UIGestureRecognizerState.began {
			longPressDidBegin(sender)
		} else if sender.state == UIGestureRecognizerState.ended {
			longPressDidEnd(sender)
		}
	}

	public func longPressDidBegin(_ gestureRecognizer: UILongPressGestureRecognizer) {
		tableView.isScrollEnabled = false

		let point = gestureRecognizer.location(in: navigationController!.tabBarController!.view)
		let collectionViewPoint = gestureRecognizer.location(in: tableView)

		guard let indexPath = tableView.indexPathForRow(at: collectionViewPoint), tableView.cellForRow(at: indexPath) != nil else {
			return
		}

		guard let post = presenter?.postAtIndex(indexPath.section) else {
			return
		}

		let viewController = QuickReblogViewController()

		viewController.startingPoint = point
		viewController.post = post
		viewController.transitioningDelegate = self
		viewController.modalPresentationStyle = UIModalPresentationStyle.custom

		viewController.view.bounds = navigationController!.tabBarController!.view.bounds

		navigationController!.tabBarController!.view.addSubview(viewController.view)

		viewController.view.layoutIfNeeded()
		viewController.viewDidAppear(false)

		reblogViewController = viewController
	}

	public func longPressDidEnd(_ gestureRecognizer: UILongPressGestureRecognizer) {
		tableView.isScrollEnabled = true

		defer {
			reblogViewController = nil
		}

		guard let viewController = reblogViewController else {
			return
		}

		let point = viewController.startingPoint
		let collectionViewPoint = tableView.convert(point!, from: navigationController!.tabBarController!.view)

		defer {
			viewController.view.removeFromSuperview()
		}

		guard let indexPath = tableView.indexPathForRow(at: collectionViewPoint), let cell = tableView.cellForRow(at: indexPath) else {
			return
		}

		guard let post = presenter?.postAtIndex((indexPath as NSIndexPath).section), let quickReblogAction = viewController.reblogAction() else {
			return
		}

		switch quickReblogAction {
		case .reblog(let reblogType):
			break
//			let reblogViewController = TextReblogViewController(
//				post: post,
//				reblogType: reblogType,
//				blogName: AccountsService.account.primaryBlog.name,
//				postHeightCache: postHeightCache
//			)
//			let sourceRect = view.convert(cell.bounds, from: cell)
//			let presentationViewController = reblogViewController.controllerToPresent(fromView: view, rect: sourceRect)
//
//			present(presentationViewController, animated: true, completion: nil)
		case .share:
			break
//			let extensionItemSource = XExtensionItemSource(url: post.url)
//			var additionalAttachments: [AnyObject] = post.photos.map { $0.urlWithWidth(CGFloat.max) }
//
//			if let photosetCell = cell as? PhotosetRowTableViewCell, let image = photosetCell.imageAtPoint(view.convert(point, to: cell)) {
//				additionalAttachments.append(image)
//			}
//
//			extensionItemSource.additionalAttachments = additionalAttachments
//
//			let activityViewController = UIActivityViewController(activityItems: [extensionItemSource], applicationActivities: nil)
//			activityViewController.popoverPresentationController?.sourceView = cell
//			activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: cell.center, size: CGSize(width: 1, height: 1))
//
//			present(activityViewController, animated: true, completion: nil)
		case .like:
			presenter?.toggleLikeForPostAtIndex((indexPath as NSIndexPath).section)
		}
	}

	func didPan(_ sender: UIPanGestureRecognizer) {
		guard let viewController = reblogViewController else {
			return
		}

		viewController.updateWithPoint(sender.location(in: viewController.view))
	}
}

// MARK: UIGestureRecognizerDelegate
extension PostsViewController: UIGestureRecognizerDelegate {
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// MARK: UIViewControllerTransitioningDelegate
extension PostsViewController: UIViewControllerTransitioningDelegate {
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return ReblogTransitionAnimator()
	}

	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		let animator = ReblogTransitionAnimator()

		animator.presenting = false

		return animator
	}
}

// MARK: TagsTableViewCellDelegate
extension PostsViewController: TagsTableViewCellDelegate {
	public func tagsTableViewCell(_ cell: TagsTableViewCell, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}
}

extension PostsViewController: PostsTableViewAdapterDelegate {
	public func numberOfPostsForAdapter(_ adapter: PostsTableViewAdapter) -> Int {
		return presenter?.numberOfPosts() ?? 0
	}

	public func postAdapter(_ adapter: PostsTableViewAdapter, sectionAdapterAtIndex index: Int) -> PostSectionAdapter {
		let post = presenter!.postAtIndex(index)
		return PostSectionAdapter(post: post)
	}

	public func adapter(_ adapter: PostsTableViewAdapter, didSelectImageForPostAtIndex index: Int) {
		let viewController = ImagesViewController()
		let post = presenter!.postAtIndex(index)

		viewController.post = post

		present(viewController, animated: true, completion: nil)
	}

	public func adapter(_ adapter: PostsTableViewAdapter, didSelectURLForPostAtIndex index: Int) {
		let post = presenter!.postAtIndex(index)
		navigationController?.pushViewController(SFSafariViewController(url: post.url), animated: true)
	}

	public func adapter(_ adapter: PostsTableViewAdapter, didSelectBlogName blogName: String) {
		let blogModule = BlogModule(blogName: blogName, postHeightCache: postHeightCache)
		blogModule.installInNavigationController(navigationController!)
	}

	public func adapter(_ adapter: PostsTableViewAdapter, didSelectTag tag: String) {
		let tagModule = TagModule(tag: tag, postHeightCache: postHeightCache)
		tagModule.installInNavigationController(navigationController!)
	}

	public func adapter(_ adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool) {
		if presented {
			present(viewController, animated: true, completion: nil)
		} else {
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

	public func adapterDidEncounterLoadMoreBoundary(_ adapter: PostsTableViewAdapter) {
		presenter?.didEncounterLoadMoreBoundary()
	}
}

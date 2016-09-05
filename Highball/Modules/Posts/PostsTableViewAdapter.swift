//
//  PostsTableViewAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import FLAnimatedImage
import SafariServices
import UIKit

public protocol PostsTableViewAdapterDelegate: class {
	func numberOfPostsForAdapter(adapter: PostsTableViewAdapter) -> Int
	func postAdapter(adapter: PostsTableViewAdapter, sectionAdapterAtIndex index: Int) -> PostSectionAdapter
	func adapterDidEncounterLoadMoreBoundary(adapter: PostsTableViewAdapter)

	func adapter(adapter: PostsTableViewAdapter, didSelectImageForPostAtIndex index: Int)
	func adapter(adapter: PostsTableViewAdapter, didSelectURLForPostAtIndex index: Int)
	func adapter(adapter: PostsTableViewAdapter, didSelectBlogName blogName: String)
	func adapter(adapter: PostsTableViewAdapter, didSelectTag tag: String)
	func adapter(adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool)
}

public class PostsTableViewAdapter: NSObject {
	private let tableView: UITableView
	private let postHeightCache: PostHeightCache
	private weak var delegate: PostsTableViewAdapterDelegate!

	private var heightCache: [NSIndexPath: CGFloat] = [:]
	private var urlWidthCache: [String: CGFloat] = [:]
	private var urlImageViewCache: [String: FLAnimatedImageView] = [:]

	public init(tableView: UITableView, postHeightCache: PostHeightCache, delegate: PostsTableViewAdapterDelegate) {
		self.tableView = tableView
		self.postHeightCache = postHeightCache
		self.delegate = delegate

		super.init()

		let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
		let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

		loadingView.addSubview(activityIndicatorView)

		activityIndicatorView.startAnimating()
		activityIndicatorView.center = loadingView.center

		tableView.dataSource = self
		tableView.delegate = self
		tableView.sectionHeaderHeight = 50
		tableView.separatorStyle = .None
		tableView.showsHorizontalScrollIndicator = false
		tableView.showsVerticalScrollIndicator = false
		tableView.tableFooterView = loadingView

		tableView.registerClass(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.cellIdentifier)
		tableView.registerClass(PhotosetRowTableViewCell.self, forCellReuseIdentifier: PhotosetRowTableViewCell.cellIdentifier)
		tableView.registerClass(ContentTableViewCell.self, forCellReuseIdentifier: ContentTableViewCell.cellIdentifier)
		tableView.registerClass(PostQuestionTableViewCell.self, forCellReuseIdentifier: PostQuestionTableViewCell.cellIdentifier)
		tableView.registerClass(PostLinkTableViewCell.self, forCellReuseIdentifier: PostLinkTableViewCell.cellIdentifier)
		tableView.registerClass(PostDialogueEntryTableViewCell.self, forCellReuseIdentifier: PostDialogueEntryTableViewCell.cellIdentifier)
		tableView.registerClass(TagsTableViewCell.self, forCellReuseIdentifier: TagsTableViewCell.cellIdentifier)
		tableView.registerClass(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.cellIdentifier)
		tableView.registerClass(YoutubeTableViewCell.self, forCellReuseIdentifier: YoutubeTableViewCell.cellIdentifier)
		tableView.registerClass(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: PostHeaderView.viewIdentifier)
	}

	public func resetCache() {
		heightCache.removeAll()
		urlImageViewCache.removeAll()
	}
}

extension PostsTableViewAdapter: UITableViewDataSource {
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return delegate.numberOfPostsForAdapter(self)
	}

	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: section)

		return sectionAdapter.numbersOfRows()
	}

	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: indexPath.section)
		let cell = sectionAdapter.tableView(tableView, cellForRow: indexPath.row)
		let linkTapHandler = { [weak self] (url: NSURL) in
			guard let host = url.host, strongSelf = self else {
				return
			}

			let username = host.characters.split { $0 == "." }
			if username.count == 3 && String(username[1]) == "tumblr" {
				strongSelf.delegate.adapter(strongSelf, didSelectBlogName: String(username[0]))
				return
			}

			strongSelf.delegate.adapter(strongSelf, didEmitViewController: SFSafariViewController(URL: url), forPresentation: false)
		}

		cell.selectionStyle = .None

		if let cell = cell as? TagsTableViewCell {
			cell.delegate = self
		} else if let cell = cell as? ContentTableViewCell {
			cell.widthForURL = { [weak self] url in
				return self?.urlWidthCache[url]
			}
			cell.imageViewForURL = { [weak self] url in
				return self?.urlImageViewCache[url]
			}
			cell.widthDidChange = { [weak self] url, width, height, imageView in
				guard let strongSelf = self else {
					return
				}

				strongSelf.urlWidthCache[url] = width
				strongSelf.urlImageViewCache[url] = imageView
				let set = sectionAdapter.setBodyComponentHeight(height, forIndexPath: indexPath, withKey: url, inHeightCache: strongSelf.postHeightCache)

				guard set else {
					return
				}

				dispatch_async(dispatch_get_main_queue()) {
					strongSelf.heightCache[indexPath] = nil
					strongSelf.tableView.beginUpdates()
					strongSelf.tableView.endUpdates()
				}
			}
			cell.linkHandler = linkTapHandler
			cell.usernameTapHandler = { [weak self] username in
				guard let strongSelf = self else {
					return
				}

				strongSelf.delegate.adapter(strongSelf, didSelectBlogName: username)
			}
		}

		return cell
	}
}

extension PostsTableViewAdapter: UITableViewDelegate {
	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if let height = heightCache[indexPath] {
			return height
		}

		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: indexPath.section)
		let height = sectionAdapter.tableView(tableView, heightForCellAtRow: indexPath.row, postHeightCache: postHeightCache)

		heightCache[indexPath] = height

		return height
	}

	public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: section)
		let view = sectionAdapter.tableViewHeaderView(tableView) as! PostHeaderView

		view.tapHandler = { [weak self] post, view in
			guard let strongSelf = self else {
				return
			}

			if let rebloggedBlogName = post.rebloggedBlogName {
				let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				alertController.popoverPresentationController?.sourceView = strongSelf.tableView
				alertController.popoverPresentationController?.sourceRect = strongSelf.tableView.convertRect(view.bounds, fromView: view)
				alertController.addAction(UIAlertAction(title: post.blogName, style: .Default) { _ in
					strongSelf.delegate.adapter(strongSelf, didSelectBlogName: post.blogName)
				})
				alertController.addAction(UIAlertAction(title: rebloggedBlogName, style: .Default) { _ in
					strongSelf.delegate.adapter(strongSelf, didSelectBlogName: rebloggedBlogName)
				})
				alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
				strongSelf.delegate.adapter(strongSelf, didEmitViewController: alertController, forPresentation: true)
			} else {
				strongSelf.delegate.adapter(strongSelf, didSelectBlogName: post.blogName)
			}
		}
		return view
	}

	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
			return
		}

		if let _ = cell as? PhotosetRowTableViewCell {
			delegate.adapter(self, didSelectImageForPostAtIndex: indexPath.section)
		} else if let videoCell = cell as? VideoPlaybackCell {
			if videoCell.isPlaying() {
				videoCell.stop()
			} else {
				let viewController = VideoPlayController(completion: { play in
					if play {
						videoCell.play()
					}
				})
				viewController.modalPresentationStyle = .OverCurrentContext
				viewController.modalTransitionStyle = .CrossDissolve
				delegate.adapter(self, didEmitViewController: viewController, forPresentation: true)
			}
		} else if let _ = cell as? PostLinkTableViewCell {
			delegate.adapter(self, didSelectURLForPostAtIndex: indexPath.section)
		}
	}

	public func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if let cell = cell as? PhotosetRowTableViewCell {
			cell.cancelDownloads()
		} else if let cell = cell as? ContentTableViewCell {
			cell.trailData = nil
			cell.widthForURL = nil
			cell.widthDidChange = nil
			cell.linkHandler = nil
		}
	}

	public func scrollViewDidScroll(scrollView: UIScrollView) {
		let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

		guard distanceFromBottom < 2000 else {
			return
		}

		delegate.adapterDidEncounterLoadMoreBoundary(self)
	}
}

extension PostsTableViewAdapter: TagsTableViewCellDelegate {
	public func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
		delegate.adapter(self, didSelectTag: tag)
	}
}

//
//  PostsTableViewAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import SafariServices
import UIKit

protocol PostsTableViewAdapterDelegate {
	func postsForAdapter(adapter: PostsTableViewAdapter) -> [Post]
	func adapterDidEncounterLoadMoreBoundary(adapter: PostsTableViewAdapter)
	func adapter(adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool)
}

class PostsTableViewAdapter: NSObject {
	private let tableView: UITableView
	private let postHeightCache: PostHeightCache
	private let delegate: PostsTableViewAdapterDelegate

	private var heightCache: [NSIndexPath: CGFloat] = [:]
	private var urlWidthCache: [String: CGFloat] = [:]

	init(tableView: UITableView, postHeightCache: PostHeightCache, delegate: PostsTableViewAdapterDelegate) {
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

	func resetCache() {
		heightCache.removeAll()
		urlWidthCache.removeAll()
	}

	private func posts() -> [Post] {
		return delegate.postsForAdapter(self)
	}
}

extension PostsTableViewAdapter: UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return posts().count ?? 0
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let post = posts()[section]
		let sectionAdapter = PostSectionAdapter(post: post)

		return sectionAdapter.numbersOfRows()
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let post = posts()[indexPath.section]
		let sectionAdapter = PostSectionAdapter(post: post)
		let cell = sectionAdapter.tableView(tableView, cellForRow: indexPath.row)
		let linkTapHandler = { (url: NSURL) in
			guard let host = url.host else {
				return
			}

			let username = host.characters.split { $0 == "." }
			if username.count == 3 && String(username[1]) == "tumblr" {
				let blogViewController = BlogViewController(blogName: String(username[0]))
				self.delegate.adapter(self, didEmitViewController: blogViewController, forPresentation: false)
				return
			}

			self.delegate.adapter(self, didEmitViewController: SFSafariViewController(URL: url), forPresentation: false)
		}

		cell.selectionStyle = .None

		if let cell = cell as? TagsTableViewCell {
			cell.delegate = self
		} else if let cell = cell as? ContentTableViewCell {
			cell.widthForURL = { [weak self] url in
				return self?.urlWidthCache[url]
			}
			cell.widthDidChange = { [weak self] url, width, height in
				if self?.urlWidthCache[url] == nil {
					self?.heightCache[indexPath] = nil
					self?.urlWidthCache[url] = width
				}
				if height != self?.postHeightCache.bodyComponentHeightForPost(post, atIndex: indexPath.row - 1, withKey: url) {
					self?.postHeightCache.setBodyComponentHeight(height, forPost: post, atIndex: indexPath.row - 1, withKey: url)
					self?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
				}

			}
			cell.linkHandler = linkTapHandler
		}

		return cell
	}
}

extension PostsTableViewAdapter: UITableViewDelegate {
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if let height = heightCache[indexPath] {
			return height
		}

		let post = posts()[indexPath.section]
		let sectionAdapter = PostSectionAdapter(post: post)
		let height = sectionAdapter.tableView(tableView, heightForCellAtRow: indexPath.row, postHeightCache: postHeightCache)

		heightCache[indexPath] = height

		return height
	}

	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let post = posts()[section] as Post
		let sectionAdapter = PostSectionAdapter(post: post)
		let view = sectionAdapter.tableViewHeaderView(tableView) as! PostHeaderView

		view.tapHandler = { post, view in
			if let rebloggedBlogName = post.rebloggedBlogName {
				let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				alertController.popoverPresentationController?.sourceView = self.tableView
				alertController.popoverPresentationController?.sourceRect = self.tableView.convertRect(view.bounds, fromView: view)
				alertController.addAction(UIAlertAction(title: post.blogName, style: .Default) { _ in
					let blogViewController = BlogViewController(blogName: post.blogName)
					self.delegate.adapter(self, didEmitViewController: blogViewController, forPresentation: false)
				})
				alertController.addAction(UIAlertAction(title: rebloggedBlogName, style: .Default) { _ in
					let blogViewController = BlogViewController(blogName: rebloggedBlogName)
					self.delegate.adapter(self, didEmitViewController: blogViewController, forPresentation: false)
				})
				alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
				self.delegate.adapter(self, didEmitViewController: alertController, forPresentation: true)
			} else {
				let blogViewController = BlogViewController(blogName: post.blogName)
				self.delegate.adapter(self, didEmitViewController: blogViewController, forPresentation: false)
			}
		}
		return view
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
			return
		}
		let post = posts()[indexPath.section]

		if let _ = cell as? PhotosetRowTableViewCell {
			let viewController = ImagesViewController()
			viewController.post = post

			self.delegate.adapter(self, didEmitViewController: viewController, forPresentation: true)
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
				self.delegate.adapter(self, didEmitViewController: viewController, forPresentation: true)
			}
		} else if let _ = cell as? PostLinkTableViewCell {
			guard let url = NSURL(string: post.urlString) else {
				return
			}

			self.delegate.adapter(self, didEmitViewController: SFSafariViewController(URL: url), forPresentation: false)
		}
	}

	func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if let cell = cell as? PhotosetRowTableViewCell {
			cell.cancelDownloads()
		} else if let cell = cell as? ContentTableViewCell {
			cell.username = nil
			cell.content = nil
			cell.widthForURL = nil
			cell.widthDidChange = nil
		}
	}

	func scrollViewDidScroll(scrollView: UIScrollView) {
		let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

		if distanceFromBottom < 2000 {
			self.delegate.adapterDidEncounterLoadMoreBoundary(self)
		}
	}
}

extension PostsTableViewAdapter: TagsTableViewCellDelegate {
	func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
		self.delegate.adapter(self, didEmitViewController: TagViewController(tag: tag), forPresentation: false)
	}
}

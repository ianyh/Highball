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
	func numberOfPostsForAdapter(_ adapter: PostsTableViewAdapter) -> Int
	func postAdapter(_ adapter: PostsTableViewAdapter, sectionAdapterAtIndex index: Int) -> PostSectionAdapter
	func adapterDidEncounterLoadMoreBoundary(_ adapter: PostsTableViewAdapter)

	func adapter(_ adapter: PostsTableViewAdapter, didSelectImageForPostAtIndex index: Int)
	func adapter(_ adapter: PostsTableViewAdapter, didSelectURLForPostAtIndex index: Int)
	func adapter(_ adapter: PostsTableViewAdapter, didSelectBlogName blogName: String)
	func adapter(_ adapter: PostsTableViewAdapter, didSelectTag tag: String)
	func adapter(_ adapter: PostsTableViewAdapter, didEmitViewController viewController: UIViewController, forPresentation presented: Bool)
}

open class PostsTableViewAdapter: NSObject {
	fileprivate let tableView: UITableView
	fileprivate let postHeightCache: PostHeightCache
	fileprivate weak var delegate: PostsTableViewAdapterDelegate!

	fileprivate var heightCache: [IndexPath: CGFloat] = [:]
	fileprivate var urlWidthCache: [String: CGFloat] = [:]
	fileprivate var urlImageViewCache: [String: FLAnimatedImageView] = [:]

	public init(tableView: UITableView, postHeightCache: PostHeightCache, delegate: PostsTableViewAdapterDelegate) {
		self.tableView = tableView
		self.postHeightCache = postHeightCache
		self.delegate = delegate

		super.init()

		let loadingView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
		let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

		loadingView.addSubview(activityIndicatorView)

		activityIndicatorView.startAnimating()
		activityIndicatorView.center = loadingView.center

		tableView.dataSource = self
		tableView.delegate = self
		tableView.sectionHeaderHeight = 50
		tableView.separatorStyle = .none
		tableView.showsHorizontalScrollIndicator = false
		tableView.showsVerticalScrollIndicator = false
		tableView.tableFooterView = loadingView

		tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.cellIdentifier)
		tableView.register(PhotosetRowTableViewCell.self, forCellReuseIdentifier: PhotosetRowTableViewCell.cellIdentifier)
		tableView.register(ContentTableViewCell.self, forCellReuseIdentifier: ContentTableViewCell.cellIdentifier)
		tableView.register(PostQuestionTableViewCell.self, forCellReuseIdentifier: PostQuestionTableViewCell.cellIdentifier)
		tableView.register(PostLinkTableViewCell.self, forCellReuseIdentifier: PostLinkTableViewCell.cellIdentifier)
		tableView.register(PostDialogueEntryTableViewCell.self, forCellReuseIdentifier: PostDialogueEntryTableViewCell.cellIdentifier)
		tableView.register(TagsTableViewCell.self, forCellReuseIdentifier: TagsTableViewCell.cellIdentifier)
		tableView.register(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.cellIdentifier)
		tableView.register(YoutubeTableViewCell.self, forCellReuseIdentifier: YoutubeTableViewCell.cellIdentifier)
		tableView.register(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: PostHeaderView.viewIdentifier)
	}

	open func resetCache() {
		heightCache.removeAll()
		urlImageViewCache.removeAll()
	}
}

extension PostsTableViewAdapter: UITableViewDataSource {
	public func numberOfSections(in tableView: UITableView) -> Int {
		return delegate.numberOfPostsForAdapter(self)
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: section)

		return sectionAdapter.numbersOfRows()
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: (indexPath as NSIndexPath).section)
		let cell = sectionAdapter.tableView(tableView, cellForRow: (indexPath as NSIndexPath).row)
		let linkTapHandler = { [weak self] (url: URL) in
			guard let host = url.host, let strongSelf = self else {
				return
			}

			let username = host.characters.split { $0 == "." }
			if username.count == 3 && String(username[1]) == "tumblr" {
				strongSelf.delegate.adapter(strongSelf, didSelectBlogName: String(username[0]))
				return
			}

			strongSelf.delegate.adapter(strongSelf, didEmitViewController: SFSafariViewController(url: url), forPresentation: false)
		}

		cell.selectionStyle = .none

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

				DispatchQueue.main.async {
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
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if let height = heightCache[indexPath] {
			return height
		}

		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: (indexPath as NSIndexPath).section)
		let height = sectionAdapter.tableView(tableView, heightForCellAtRow: (indexPath as NSIndexPath).row, postHeightCache: postHeightCache)

		heightCache[indexPath] = height

		return height
	}

	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionAdapter = delegate.postAdapter(self, sectionAdapterAtIndex: section)
		let view = sectionAdapter.tableViewHeaderView(tableView) as! PostHeaderView

		view.tapHandler = { [weak self] post, view in
			guard let strongSelf = self else {
				return
			}

			if let rebloggedBlogName = post.rebloggedBlogName {
				let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
				alertController.popoverPresentationController?.sourceView = strongSelf.tableView
				alertController.popoverPresentationController?.sourceRect = strongSelf.tableView.convert(view.bounds, from: view)
				alertController.addAction(UIAlertAction(title: post.blogName, style: .default) { _ in
					strongSelf.delegate.adapter(strongSelf, didSelectBlogName: post.blogName)
				})
				alertController.addAction(UIAlertAction(title: rebloggedBlogName, style: .default) { _ in
					strongSelf.delegate.adapter(strongSelf, didSelectBlogName: rebloggedBlogName)
				})
				alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
				strongSelf.delegate.adapter(strongSelf, didEmitViewController: alertController, forPresentation: true)
			} else {
				strongSelf.delegate.adapter(strongSelf, didSelectBlogName: post.blogName)
			}
		}
		return view
	}

	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else {
			return
		}

		if let _ = cell as? PhotosetRowTableViewCell {
			delegate.adapter(self, didSelectImageForPostAtIndex: (indexPath as NSIndexPath).section)
		} else if let videoCell = cell as? VideoPlaybackCell {
			if videoCell.isPlaying() {
				videoCell.stop()
			} else {
				let viewController = VideoPlayController(completion: { play in
					if play {
						videoCell.play()
					}
				})
				viewController.modalPresentationStyle = .overCurrentContext
				viewController.modalTransitionStyle = .crossDissolve
				delegate.adapter(self, didEmitViewController: viewController, forPresentation: true)
			}
		} else if let _ = cell as? PostLinkTableViewCell {
			delegate.adapter(self, didSelectURLForPostAtIndex: (indexPath as NSIndexPath).section)
		}
	}

	public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let cell = cell as? PhotosetRowTableViewCell {
			cell.cancelDownloads()
		} else if let cell = cell as? ContentTableViewCell {
			cell.trailData = nil
			cell.widthForURL = nil
			cell.widthDidChange = nil
			cell.linkHandler = nil
		}
	}

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

		guard distanceFromBottom < 2000 else {
			return
		}

		delegate.adapterDidEncounterLoadMoreBoundary(self)
	}
}

extension PostsTableViewAdapter: TagsTableViewCellDelegate {
	public func tagsTableViewCell(_ cell: TagsTableViewCell, didSelectTag tag: String) {
		delegate.adapter(self, didSelectTag: tag)
	}
}

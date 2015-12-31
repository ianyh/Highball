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

        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderHeight = 50
        tableView.separatorStyle = .None
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = loadingView

        tableView.registerClass(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.cellIdentifier)
        tableView.registerClass(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: PostHeaderView.viewIdentifier)
    }

    func resetCache() {
        heightCache.removeAll()
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
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let post = posts()[indexPath.section]
        let cell = tableView.dequeueReusableCellWithIdentifier(PostTableViewCell.cellIdentifier, forIndexPath: indexPath) as! PostTableViewCell

        cell.bodyHeight = postHeightCache.bodyHeightForPost(post)
        cell.secondaryBodyHeight = postHeightCache.secondaryBodyHeightForPost(post)
        cell.post = post

        cell.bodyTapHandler = { post, view in
            if let _ = view as? PhotosetRowTableViewCell {
                let viewController = ImagesViewController()
                viewController.post = post

                self.delegate.adapter(self, didEmitViewController: viewController, forPresentation: true)
            } else if let videoCell = view as? VideoPlaybackCell {
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
            } else if let _ = view as? PostLinkTableViewCell {
                guard let url = NSURL(string: post.urlString) else {
                    return
                }

                self.delegate.adapter(self, didEmitViewController: SFSafariViewController(URL: url), forPresentation: false)
            }
        }

        cell.tagTapHandler = { post, tag in
            self.delegate.adapter(self, didEmitViewController: TagViewController(tag: tag), forPresentation: false)
        }

        cell.linkTapHandler = { post, url in
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

        return cell
    }
}

extension PostsTableViewAdapter: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts()[indexPath.section]

        if let height = heightCache[indexPath] {
            return height
        }

        var height: CGFloat = 0.0

        switch post.type {
        case "photo":
            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }

            let postPhotos = post.photos
            var images: Array<PostPhoto>!
            var photosIndexStart = 0
            for layoutRow in post.layoutRows.layoutRows {
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + layoutRow)])

                let imageWidth = tableView.frame.width / CGFloat(images.count)
                let minHeight = floor(images.map { (image: PostPhoto) -> CGFloat in
                    let scale = image.height / image.width
                    return imageWidth * scale
                    }.reduce(CGFloat.max, combine: { min($0, $1) }))

                height += minHeight

                photosIndexStart += layoutRow
            }
        case "text":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
            }
            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }
        case "answer":
            height += PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.width)
            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }
        case "quote":
            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }
            if let secondaryBodyHeight = postHeightCache.secondaryBodyHeightForPost(post) {
                height += secondaryBodyHeight
            }
        case "link":
            height += PostLinkTableViewCell.heightForPost(post, width: tableView.frame.width)
            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }
        case "chat":
            if let title = post.title {
                height += TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
            }
            for dialogueEntry in post.dialogueEntries {
                height += PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.width)
            }
        case "video":
            if let playerHeight = post.videoHeightWidthWidth(tableView.frame.width) {
                height += playerHeight
            } else {
                height += 320
            }

            if let bodyHeight = postHeightCache.bodyHeightForPost(post) {
                height += bodyHeight
            }
        default:
            height = 0
        }

        if post.tags.count > 0 {
            height += 30
        }

        heightCache[indexPath] = height

        return height
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(PostHeaderView.viewIdentifier) as! PostHeaderView
        let post = posts()[section] as Post
        view.post = post
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

    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? PostTableViewCell else {
            return
        }

        cell.endDisplay()
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y

        if distanceFromBottom < 2000 {
            self.delegate.adapterDidEncounterLoadMoreBoundary(self)
        }
    }
}

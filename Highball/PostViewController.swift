//
//  SinglePostViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/22/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography

struct PostViewSections {
    enum TextRow: Int {
        case Title
        case Body
    }

    enum AnswerRow: Int {
        case Question
        case Answer
    }

    enum QuoteRow: Int {
        case Quote
        case Source
    }

    enum LinkRow: Int {
        case Link
        case Description
    }

    enum VideoRow: Int {
        case Player
        case Caption
    }

    enum AudioRow: Int {
        case Player
        case Caption
    }
}

class PostViewController: UIViewController {

    private var tableView: UITableView!
    var post: Post! {
        didSet {
            heightCache.removeAll()
            tableView?.reloadData()
        }
    }
    var heightCache = Dictionary<NSIndexPath, CGFloat>()
    var bodyHeight: CGFloat?
    var secondaryBodyHeight: CGFloat?

    var bodyTapHandler: ((Post, UIView) -> ())?
    var tagTapHandler: ((Post, String) -> ())?
    var linkTapHandler: ((Post, NSURL) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView()
        tableView.allowsSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.scrollEnabled = false
        tableView.sectionHeaderHeight = 50
        tableView.sectionFooterHeight = 50
        tableView.separatorStyle = .None
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.registerClass(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.cellIdentifier)
        tableView.registerClass(PhotosetRowTableViewCell.self, forCellReuseIdentifier: PhotosetRowTableViewCell.cellIdentifier)
        tableView.registerClass(ContentTableViewCell.self, forCellReuseIdentifier: ContentTableViewCell.cellIdentifier)
        tableView.registerClass(PostQuestionTableViewCell.self, forCellReuseIdentifier: PostQuestionTableViewCell.cellIdentifier)
        tableView.registerClass(PostLinkTableViewCell.self, forCellReuseIdentifier: PostLinkTableViewCell.cellIdentifier)
        tableView.registerClass(PostDialogueEntryTableViewCell.self, forCellReuseIdentifier: PostDialogueEntryTableViewCell.cellIdentifier)
        tableView.registerClass(TagsTableViewCell.self, forCellReuseIdentifier: TagsTableViewCell.cellIdentifier)
        tableView.registerClass(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.cellIdentifier)
        tableView.registerClass(YoutubeTableViewCell.self, forCellReuseIdentifier: YoutubeTableViewCell.cellIdentifier)

        view.addSubview(tableView)

        constrain(tableView, view) { tableView, view in
            tableView.edges == view.edges
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        heightCache.removeAll()
        tableView.reloadData()
    }

    func endDisplay() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else {
            return
        }

        for indexPath in indexPaths {
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
                continue
            }

            if let cell = cell as? PhotosetRowTableViewCell {
                cell.cancelDownloads()
            } else if let cell = cell as? ContentTableViewCell {
                cell.content = nil
            }
        }
    }

    func imageAtPoint(point: CGPoint) -> UIImage? {
        guard
            let indexPath = tableView.indexPathForRowAtPoint(view.convertPoint(point, toView: tableView)),
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? PhotosetRowTableViewCell
        else {
            return nil
        }

        return cell.imageAtPoint(point)
    }
}

extension PostViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return post == nil ? 0 : 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0

        switch post.type {
        case "photo":
            let postPhotos = post.photos
            if postPhotos.count == 1 {
                rowCount = 2
            }
            rowCount = post.layoutRows.layoutRows.count + 1
        case "text":
            rowCount = 2
        case "answer":
            rowCount = 2
        case "quote":
            rowCount = 2
        case "link":
            rowCount = 2
        case "chat":
            rowCount = 1 + post.dialogueEntries.count
        case "video":
            rowCount = 2
        case "audio":
            rowCount = 2
        default:
            rowCount = 0
        }

        return rowCount + 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView(tableView, postCellForRowAtIndexPath: indexPath)
        cell.selectionStyle = .None
        return cell
    }

    func tableView(tableView: UITableView, postCellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(TagsTableViewCell.cellIdentifier) as! TagsTableViewCell!
            cell.delegate = self
            cell.tags = post.tags
            return cell
        }

        switch post.type {
        case "photo":
            if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { url in
                    self.linkTapHandler?(self.post, url)
                }
                return cell
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(PhotosetRowTableViewCell.cellIdentifier) as! PhotosetRowTableViewCell!
            let postPhotos = post.photos

            cell.contentWidth = tableView.frame.size.width

            if postPhotos.count == 1 {
                cell.images = postPhotos
            } else {
                let photosetLayoutRows = post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows.layoutRows[0..<indexPath.row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows.layoutRows[indexPath.row]

                cell.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }

            return cell
        case "text":
            switch PostViewSections.TextRow(rawValue: indexPath.row)! {
            case .Title:
                let cell = tableView.dequeueReusableCellWithIdentifier(TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
                cell.titleLabel.text = post.title
                return cell
            case .Body:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "answer":
            switch PostViewSections.AnswerRow(rawValue: indexPath.row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(PostQuestionTableViewCell.cellIdentifier) as! PostQuestionTableViewCell!
                cell.post = post
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "quote":
            switch PostViewSections.QuoteRow(rawValue: indexPath.row)! {
            case .Quote:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            case .Source:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "link":
            switch PostViewSections.LinkRow(rawValue: indexPath.row)! {
            case .Link:
                let cell = tableView.dequeueReusableCellWithIdentifier(PostLinkTableViewCell.cellIdentifier) as! PostLinkTableViewCell!
                cell.post = post
                return cell
            case .Description:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "chat":
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
                cell.titleLabel.text = post.title
                return cell
            }
            let dialogueEntry = post.dialogueEntries[indexPath.row - 1]
            let cell = tableView.dequeueReusableCellWithIdentifier(PostDialogueEntryTableViewCell.cellIdentifier) as! PostDialogueEntryTableViewCell!
            cell.dialogueEntry = dialogueEntry
            return cell
        case "video":
            switch PostViewSections.VideoRow(rawValue: indexPath.row)! {
            case .Player:
                switch post.videoType! {
                case "youtube":
                    let cell = tableView.dequeueReusableCellWithIdentifier(YoutubeTableViewCell.cellIdentifier) as! YoutubeTableViewCell!
                    cell.post = post
                    return cell
                default:
                    let cell = tableView.dequeueReusableCellWithIdentifier(VideoTableViewCell.cellIdentifier) as! VideoTableViewCell!
                    cell.post = post
                    return cell
                }
            case .Caption:
                let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "audio":
            let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
            switch PostViewSections.AudioRow(rawValue: indexPath.row)! {
            case .Player:
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
            return cell
        default:
            return tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier)!
        }
    }
}

extension PostViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = heightCache[indexPath] {
            return height
        }

        let sectionRowCount = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        let heightCalculator = PostViewHeightCalculator(width: tableView.frame.width, bodyHeight: bodyHeight, secondaryBodyHeight: secondaryBodyHeight)
        let height = heightCalculator.heightForPost(post, atIndexPath: indexPath, sectionRowCount: sectionRowCount)

        heightCache[indexPath] = height

        return height
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }

        bodyTapHandler?(post, cell)
    }
}

extension PostViewController: TagsTableViewCellDelegate {
    func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
        tagTapHandler?(post, tag)
    }
}

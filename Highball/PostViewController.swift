//
//  SinglePostViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/22/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit
import Cartography

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
        
        tableView.registerClass(TitleTableViewCell.self, forCellReuseIdentifier: titleTableViewCellIdentifier)
        tableView.registerClass(PhotosetRowTableViewCell.self, forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        tableView.registerClass(ContentTableViewCell.self, forCellReuseIdentifier: contentTableViewCellIdentifier)
        tableView.registerClass(PostQuestionTableViewCell.self, forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        tableView.registerClass(PostLinkTableViewCell.self, forCellReuseIdentifier: postLinkTableViewCellIdentifier)
        tableView.registerClass(PostDialogueEntryTableViewCell.self, forCellReuseIdentifier: postDialogueEntryTableViewCellIdentifier)
        tableView.registerClass(TagsTableViewCell.self, forCellReuseIdentifier: postTagsTableViewCellIdentifier)
        tableView.registerClass(VideoTableViewCell.self, forCellReuseIdentifier: videoTableViewCellIdentifier)
        tableView.registerClass(YoutubeTableViewCell.self, forCellReuseIdentifier: youtubeTableViewCellIdentifier)
        
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
            rowCount = post.layoutRows.count + 1
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
            let cell = tableView.dequeueReusableCellWithIdentifier(postTagsTableViewCellIdentifier) as! TagsTableViewCell!
            cell.delegate = self
            cell.tags = post.tags
            return cell
        }
        
        switch post.type {
        case "photo":
            if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { url in
                    self.linkTapHandler?(self.post, url)
                }
                return cell
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(photosetRowTableViewCellIdentifier) as! PhotosetRowTableViewCell!
            let postPhotos = post.photos
            
            cell.contentWidth = tableView.frame.size.width
            
            if postPhotos.count == 1 {
                cell.images = postPhotos
            } else {
                let photosetLayoutRows = post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows[0..<indexPath.row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows[indexPath.row]
                
                cell.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }
            
            return cell
        case "text":
            switch TextRow(rawValue: indexPath.row)! {
            case .Title:
                let cell = tableView.dequeueReusableCellWithIdentifier(titleTableViewCellIdentifier) as! TitleTableViewCell!
                cell.titleLabel.text = post.title
                return cell
            case .Body:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "answer":
            switch AnswerRow(rawValue: indexPath.row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(postQuestionTableViewCellIdentifier) as! PostQuestionTableViewCell!
                cell.post = post
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "quote":
            switch QuoteRow(rawValue: indexPath.row)! {
            case .Quote:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            case .Source:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "link":
            switch LinkRow(rawValue: indexPath.row)! {
            case .Link:
                let cell = tableView.dequeueReusableCellWithIdentifier(postLinkTableViewCellIdentifier) as! PostLinkTableViewCell!
                cell.post = post
                return cell
            case .Description:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "chat":
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(titleTableViewCellIdentifier) as! TitleTableViewCell!
                cell.titleLabel.text = post.title
                return cell;
            }
            let dialogueEntry = post.dialogueEntries[indexPath.row - 1]
            let cell = tableView.dequeueReusableCellWithIdentifier(postDialogueEntryTableViewCellIdentifier) as! PostDialogueEntryTableViewCell!
            cell.dialogueEntry = dialogueEntry
            return cell
        case "video":
            switch VideoRow(rawValue: indexPath.row)! {
            case .Player:
                switch post.videoType! {
                case "youtube":
                    let cell = tableView.dequeueReusableCellWithIdentifier(youtubeTableViewCellIdentifier) as! YoutubeTableViewCell!
                    cell.post = post
                    return cell
                default:
                    let cell = tableView.dequeueReusableCellWithIdentifier(videoTableViewCellIdentifier) as! VideoTableViewCell!
                    cell.post = post
                    return cell
                }
            case .Caption:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
                return cell
            }
        case "audio":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as! ContentTableViewCell!
            switch AudioRow(rawValue: indexPath.row)! {
            case .Player:
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            cell.linkHandler = { self.linkTapHandler?(self.post, $0) }
            return cell
        default:
            return tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier)!
        }
    }
}

extension PostViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            if post.tags.count > 0 {
                return 30
            }
            return 0
        }
        
        switch post.type {
        case "photo":
            if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 2 {
                return bodyHeight ?? 0
            }
            
            if let height = heightCache[indexPath] {
                return height
            }
            
            let postPhotos = post.photos
            var images: Array<PostPhoto>!
            
            if postPhotos.count == 1 {
                images = postPhotos
            } else {
                let photosetLayoutRows = post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows[0..<indexPath.row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows[indexPath.row]
                
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }
            
            let imageWidth = tableView.frame.width / CGFloat(images.count)
            let minHeight = floor(images
                .map { (image: PostPhoto) -> CGFloat in
                    let scale = image.height / image.width
                    return imageWidth * scale
                }
                .reduce(CGFloat.max) { min($0, $1) }
            )
            
            heightCache[indexPath] = minHeight
            return minHeight
        case "text":
            switch TextRow(rawValue: indexPath.row)! {
            case .Title:
                if let title = post.title {
                    if let height = heightCache[indexPath] {
                        return height
                    }

                    let height = TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
                    heightCache[indexPath] = height
                    return height
                }
                return 0
            case .Body:
                return bodyHeight ?? 0
            }
        case "answer":
            switch AnswerRow(rawValue: indexPath.row)! {
            case .Question:
                if let height = heightCache[indexPath] {
                    return height
                }
                
                let height = PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.width)
                heightCache[indexPath] = height
                return height
            case .Answer:
                return bodyHeight ?? 0
            }
        case "quote":
            switch QuoteRow(rawValue: indexPath.row)! {
            case .Quote:
                return bodyHeight ?? 0
            case .Source:
                return secondaryBodyHeight ?? 0
            }
        case "link":
            switch LinkRow(rawValue: indexPath.row)! {
            case .Link:
                if let height = heightCache[indexPath] {
                    return height
                }
                
                let height = PostLinkTableViewCell.heightForPost(post, width: tableView.frame.width)
                heightCache[indexPath] = height
                return height
            case .Description:
                return bodyHeight ?? 0
            }
        case "chat":
            if indexPath.row == 0 {
                guard let title = post.title else {
                    return 0
                }

                if let height = heightCache[indexPath] {
                    return height
                }
                
                let height = TitleTableViewCell.heightForTitle(title, width: tableView.frame.width)
                heightCache[indexPath] = height
                return height
            }

            let dialogueEntry = post.dialogueEntries[indexPath.row - 1]
            if let height = heightCache[indexPath] {
                return height
            }
            
            let height = PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.width)
            heightCache[indexPath] = height
            return height
        case "video":
            switch VideoRow(rawValue: indexPath.row)! {
            case .Player:
                if let height = heightCache[indexPath] {
                    return height
                }
                if let height = post.videoHeightWidthWidth(tableView.frame.width) {
                    heightCache[indexPath] = height
                    return height
                }
                heightCache[indexPath] = 320
                return 320
            case .Caption:
                return bodyHeight ?? 0
            }
        case "video":
            switch AudioRow(rawValue: indexPath.row)! {
            case .Player:
                return secondaryBodyHeight ?? 0
            case .Caption:
                return bodyHeight ?? 0
            }
        default:
            return 0
        }
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

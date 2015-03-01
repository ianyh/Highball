//
//  SinglePostViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 2/22/15.
//  Copyright (c) 2015 ianynda. All rights reserved.
//

import UIKit

class PostViewController: UIViewController, TagsTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate {
    private var tableView: UITableView!
    var post: Post! {
        didSet {
            self.heightCache.removeAll()
            self.tableView.reloadData()
        }
    }
    var heightCache: Dictionary<NSIndexPath, CGFloat>!
    var bodyHeight: CGFloat?
    var secondaryBodyHeight: CGFloat?

    var headerTapHandler: ((Post, UIView) -> ())?
    var bodyTapHandler: ((Post, UIView) -> ())?

    required override init() {
        super.init()
    }

    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.heightCache = Dictionary<NSIndexPath, CGFloat>()

        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.allowsSelection = true
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.sectionHeaderHeight = 50
        self.tableView.sectionFooterHeight = 50
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.scrollEnabled = false
        
        self.tableView.registerClass(TitleTableViewCell.classForCoder(), forCellReuseIdentifier: titleTableViewCellIdentifier)
        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostQuestionTableViewCell.classForCoder(), forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        self.tableView.registerClass(PostLinkTableViewCell.classForCoder(), forCellReuseIdentifier: postLinkTableViewCellIdentifier)
        self.tableView.registerClass(PostDialogueEntryTableViewCell.classForCoder(), forCellReuseIdentifier: postDialogueEntryTableViewCellIdentifier)
        self.tableView.registerClass(TagsTableViewCell.classForCoder(), forCellReuseIdentifier: postTagsTableViewCellIdentifier)
        self.tableView.registerClass(VideoTableViewCell.classForCoder(), forCellReuseIdentifier: videoTableViewCellIdentifier)
        self.tableView.registerClass(YoutubeTableViewCell.classForCoder(), forCellReuseIdentifier: youtubeTableViewCellIdentifier)
        self.tableView.registerClass(PostHeaderView.classForCoder(), forHeaderFooterViewReuseIdentifier: postHeaderViewIdentifier)
        
        self.view.addSubview(self.tableView)

        layout(self.tableView, self.view) { tableView, view in
            tableView.edges == view.edges; return
        }
    }

    func endDisplay() {
        if let indexPaths = self.tableView.indexPathsForVisibleRows() {
            for indexPath in indexPaths {
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath as NSIndexPath) {
                    if let cell = cell as? PhotosetRowTableViewCell {
                        cell.cancelDownloads()
                    } else if let cell = cell as? ContentTableViewCell {
                        cell.content = nil
                    }
                }
            }
        }
    }

    func imageAtPoint(point: CGPoint) -> UIImage? {
        if let indexPath = self.tableView.indexPathForRowAtPoint(self.view.convertPoint(point, toView: self.tableView)) {
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PhotosetRowTableViewCell {
                return cell.imageAtPoint(point)
            }
        }
        return nil
    }

    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let post = self.post {
            return 1
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        switch self.post.type {
        case "photo":
            let postPhotos = self.post.photos
            if postPhotos.count == 1 {
                rowCount = 2
            }
            rowCount = self.post.layoutRows.count + 1
        case "text":
            rowCount = 2
        case "answer":
            rowCount = 2
        case "quote":
            rowCount = 2
        case "link":
            rowCount = 2
        case "chat":
            rowCount = 1 + self.post.dialogueEntries.count
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
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(postTagsTableViewCellIdentifier) as TagsTableViewCell!
            cell.delegate = self
            cell.tags = self.post.tags
            return cell
        }
        
        switch self.post.type {
        case "photo":
            if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
            let cell = tableView.dequeueReusableCellWithIdentifier(photosetRowTableViewCellIdentifier) as PhotosetRowTableViewCell!
            let postPhotos = self.post.photos
            
            cell.contentWidth = tableView.frame.size.width
            
            if postPhotos.count == 1 {
                cell.images = postPhotos
            } else {
                let photosetLayoutRows = self.post.layoutRows
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
                let cell = tableView.dequeueReusableCellWithIdentifier(titleTableViewCellIdentifier) as TitleTableViewCell!
                cell.titleLabel.text = self.post.title
                return cell
            case .Body:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "answer":
            switch AnswerRow(rawValue: indexPath.row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(postQuestionTableViewCellIdentifier) as PostQuestionTableViewCell!
                cell.post = self.post
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "quote":
            switch QuoteRow(rawValue: indexPath.row)! {
            case .Quote:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            case .Source:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "link":
            switch LinkRow(rawValue: indexPath.row)! {
            case .Link:
                let cell = tableView.dequeueReusableCellWithIdentifier(postLinkTableViewCellIdentifier) as PostLinkTableViewCell!
                cell.post = self.post
                return cell
            case .Description:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "chat":
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(titleTableViewCellIdentifier) as TitleTableViewCell!
                cell.titleLabel.text = self.post.title
                return cell;
            }
            let dialogueEntry = self.post.dialogueEntries[indexPath.row - 1]
            let cell = tableView.dequeueReusableCellWithIdentifier(postDialogueEntryTableViewCellIdentifier) as PostDialogueEntryTableViewCell!
            cell.dialogueEntry = dialogueEntry
            return cell
        case "video":
            switch VideoRow(rawValue: indexPath.row)! {
            case .Player:
                switch self.post.videoType! {
                case "youtube":
                    let cell = tableView.dequeueReusableCellWithIdentifier(youtubeTableViewCellIdentifier) as YoutubeTableViewCell!
                    cell.post = self.post
                    return cell
                default:
                    let cell = tableView.dequeueReusableCellWithIdentifier(videoTableViewCellIdentifier) as VideoTableViewCell!
                    cell.post = self.post
                    return cell
                }
            case .Caption:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
                return cell
            }
        case "audio":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            switch AudioRow(rawValue: indexPath.row)! {
            case .Player:
                cell.content = self.post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = self.post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            return cell
        default:
            return tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as UITableViewCell!
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(postHeaderViewIdentifier) as PostHeaderView
        
        view.tapHandler = { post, view in
            if let headerTapHandler = self.headerTapHandler {
                headerTapHandler(post, view)
            }
        }
        view.post = self.post
        
        return view
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            if self.post.tags.count > 0 {
                return 30
            }
            return 0
        }
        
        switch self.post.type {
        case "photo":
            if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 2 {
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
            
            if let height = self.heightCache[indexPath] {
                return height
            }
            
            let postPhotos = self.post.photos
            var images: Array<PostPhoto>!
            
            if postPhotos.count == 1 {
                images = postPhotos
            } else {
                let photosetLayoutRows = self.post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows[0..<indexPath.row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows[indexPath.row]
                
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }
            
            let imageCount = images.count
            let imageWidth = tableView.frame.size.width / CGFloat(images.count)
            let minHeight = floor(images.map { (image: PostPhoto) -> CGFloat in
                let scale = image.height / image.width
                return imageWidth * scale
                }.reduce(CGFloat.max, combine: { min($0, $1) }))
            
            self.heightCache[indexPath] = minHeight
            return minHeight
        case "text":
            switch TextRow(rawValue: indexPath.row)! {
            case .Title:
                if let title = self.post.title {
                    if let height = self.heightCache[indexPath] {
                        return height
                    }

                    let height = TitleTableViewCell.heightForTitle(title, width: tableView.frame.size.width)
                    self.heightCache[indexPath] = height
                    return height
                }
                return 0
            case .Body:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
        case "answer":
            switch AnswerRow(rawValue: indexPath.row)! {
            case .Question:
                if let height = self.heightCache[indexPath] {
                    return height
                }
                
                let height = PostQuestionTableViewCell.heightForPost(self.post, width: tableView.frame.size.width)
                self.heightCache[indexPath] = height
                return height
            case .Answer:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
        case "quote":
            switch QuoteRow(rawValue: indexPath.row)! {
            case .Quote:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            case .Source:
                if let height = self.secondaryBodyHeight {
                    return height
                }
                return 0
            }
        case "link":
            switch LinkRow(rawValue: indexPath.row)! {
            case .Link:
                if let height = self.heightCache[indexPath] {
                    return height
                }
                
                let height = PostLinkTableViewCell.heightForPost(self.post, width: tableView.frame.size.width)
                self.heightCache[indexPath] = height
                return height
            case .Description:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
        case "chat":
            if indexPath.row == 0 {
                if let title = self.post.title {
                    if let height = self.heightCache[indexPath] {
                        return height
                    }
                    
                    let height = TitleTableViewCell.heightForTitle(title, width: tableView.frame.size.width)
                    self.heightCache[indexPath] = height
                    return height
                }
                return 0
            }
            let dialogueEntry = self.post.dialogueEntries[indexPath.row - 1]
            if let height = self.heightCache[indexPath] {
                return height
            }
            
            let height = PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.size.width)
            self.heightCache[indexPath] = height
            return height
        case "video":
            switch VideoRow(rawValue: indexPath.row)! {
            case .Player:
                if let height = self.heightCache[indexPath] {
                    return height
                }
                if let height = self.post.videoHeightWidthWidth(tableView.frame.size.width) {
                    self.heightCache[indexPath] = height
                    return height
                }
                self.heightCache[indexPath] = 320
                return 320
            case .Caption:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
        case "video":
            switch AudioRow(rawValue: indexPath.row)! {
            case .Player:
                if let height = self.secondaryBodyHeight {
                    return height
                }
                return 0
            case .Caption:
                if let height = self.bodyHeight {
                    return height
                }
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if let bodyTapHandler = self.bodyTapHandler {
                bodyTapHandler(self.post, cell)
            }
        }
    }

    // MARK: TagsTableViewCellDelegate
    
    func tagsTableViewCell(cell: TagsTableViewCell, didSelectTag tag: String) {
        if let navigationController = self.navigationController {
            navigationController.pushViewController(TagViewController(tag: tag), animated: true)
        }
    }
}

//
//  TextReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/17/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit

class TextReblogViewController: SLKTextViewController {
    var reblogType: ReblogType!
    var post: Post!
    var blogName: String!
    var bodyHeightCache: Dictionary<Int, CGFloat>!
    var secondaryBodyHeightCache: Dictionary<Int, CGFloat>!

    private var reblogging = false

    private let postHeaderViewIdentifier = "postHeaderViewIdentifier"
    private let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
    private let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
    private let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"
    private let postLinkTableViewCellIdentifier = "postLinkTableViewCellIdentifier"
    private let postDialogueEntryTableViewCellIdentifier = "postDialogueEntryTableViewCellIdentifier"

    override init() {
        super.init(tableViewStyle: UITableViewStyle.Plain)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clearColor()

        var reblogTitle: String
        switch self.reblogType! {
        case .Reblog:
            reblogTitle = "Reblog"
        case .Queue:
            reblogTitle = "Queue"
        }

        self.textInputbar.leftButton.setImage(FAKIonIcons.androidCloseIconWithSize(30).imageWithSize(CGSize(width: 30, height: 30)), forState: UIControlState.Normal)
        self.textInputbar.rightButton.setTitle(reblogTitle, forState: UIControlState.Normal)
        self.textInputbar.autoHideRightButton = false

        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.sectionHeaderHeight = 50
        self.tableView.sectionFooterHeight = 50
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.backgroundColor = UIColor.clearColor()
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0)

        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostQuestionTableViewCell.classForCoder(), forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        self.tableView.registerClass(PostLinkTableViewCell.classForCoder(), forCellReuseIdentifier: postLinkTableViewCellIdentifier)
        self.tableView.registerClass(PostDialogueEntryTableViewCell.classForCoder(), forCellReuseIdentifier: postDialogueEntryTableViewCellIdentifier)
        self.tableView.registerClass(PostHeaderView.classForCoder(), forHeaderFooterViewReuseIdentifier: postHeaderViewIdentifier)

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        self.view.insertSubview(vibrancyView, atIndex: 0)
        self.view.insertSubview(blurView, atIndex: 0)
        
        layout(blurView, self.view) { blurView, view in
            blurView.edges == view.edges; return
        }
        layout(vibrancyView, self.view) { vibrancyView, view in
            vibrancyView.edges == view.edges; return
        }

        let lightBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let lightBlurView = UIVisualEffectView(effect: lightBlurEffect)
        self.view.addSubview(lightBlurView)

        layout(lightBlurView, self.view) { lightBlurView, view in
            lightBlurView.top == view.top
            lightBlurView.left == view.left
            lightBlurView.right == view.right
            lightBlurView.height == 20
        }
    }

    override func canPressRightButton() -> Bool {
        return !self.reblogging
    }

    override func didPressRightButton(sender: AnyObject!) {
        var parameters = [ "id" : "\(self.post.id)", "reblog_key" : self.post.reblogKey ]
        
        switch self.reblogType as ReblogType {
        case .Reblog:
            parameters["state"] = "published"
        case .Queue:
            parameters["state"] = "queue"
        }

        let text = self.textView.text
        if countElements(text) > 0 {
            parameters["comment"] = text
        }

        self.reblogging = true

        TMAPIClient.sharedInstance().reblogPost(self.blogName, parameters: parameters) { response, error in
            if let e = error {
                println(e)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        }

        super.didPressRightButton(sender)
    }

    override func didPressLeftButton(sender: AnyObject!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let post = self.post {
            switch self.post.type {
            case "photo":
                let postPhotos = post.photos
                if postPhotos.count == 1 {
                    return 2
                }
                
                return post.layoutRows.count + 1
            case "text":
                return 1
            case "answer":
                return 2
            case "quote":
                return 2
            case "link":
                return 2
            case "chat":
                return post.dialogueEntries.count
            case "video":
                return 2
            case "audio":
                return 2
            default:
                return 0
            }
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowCount = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        let row = rowCount - indexPath.row - 1

        switch self.post.type {
        case "photo":
            if row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.transform = self.tableView.transform
                return cell
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(photosetRowTableViewCellIdentifier) as PhotosetRowTableViewCell!
            cell.transform = self.tableView.transform

            let postPhotos = post.photos
            if postPhotos.count == 1 {
                cell.images = postPhotos
            } else {
                let photosetLayoutRows = post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows[0..<row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows[row]
                
                cell.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }
            cell.contentWidth = tableView.frame.size.width
            
            return cell
        case "text":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            cell.transform = self.tableView.transform
            return cell
        case "answer":
            switch AnswerRow(rawValue: row)! {
            case .Question:
                let cell = tableView.dequeueReusableCellWithIdentifier(postQuestionTableViewCellIdentifier) as PostQuestionTableViewCell!
                cell.post = post
                cell.transform = self.tableView.transform
                return cell
            case .Answer:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.transform = self.tableView.transform
                return cell
            }
        case "quote":
            switch QuoteRow(rawValue: row)! {
            case .Quote:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.transform = self.tableView.transform
                return cell
            case .Source:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
                cell.transform = self.tableView.transform
                return cell
            }
        case "link":
            switch LinkRow(rawValue: row)! {
            case .Link:
                let cell = tableView.dequeueReusableCellWithIdentifier(postLinkTableViewCellIdentifier) as PostLinkTableViewCell!
                cell.post = post
                cell.transform = self.tableView.transform
                return cell
            case .Description:
                let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
                cell.transform = self.tableView.transform
                return cell
            }
        case "chat":
            let dialogueEntry = post.dialogueEntries[row]
            let cell = tableView.dequeueReusableCellWithIdentifier(postDialogueEntryTableViewCellIdentifier) as PostDialogueEntryTableViewCell!
            cell.dialogueEntry = dialogueEntry
            cell.transform = self.tableView.transform
            return cell
        case "video":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            switch VideoRow(rawValue: row)! {
            case .Player:
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            cell.transform = self.tableView.transform
            return cell
        case "audio":
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as ContentTableViewCell!
            switch AudioRow(rawValue: row)! {
            case .Player:
                cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
            case .Caption:
                cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
            }
            cell.transform = self.tableView.transform
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier(contentTableViewCellIdentifier) as UITableViewCell!
            cell.transform = self.tableView.transform
            return cell
        }
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(postHeaderViewIdentifier) as PostHeaderView
        
        view.post = self.post
        view.transform = self.tableView.transform
        
        return view
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let rowCount = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        let row = rowCount - indexPath.row - 1

        switch self.post.type {
        case "photo":
            if row == rowCount - 1 {
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
            
            let postPhotos = post.photos
            var images: Array<PostPhoto>!
            
            if postPhotos.count == 1 {
                images = postPhotos
            } else {
                let photosetLayoutRows = post.layoutRows
                var photosIndexStart = 0
                for photosetLayoutRow in photosetLayoutRows[0..<row] {
                    photosIndexStart += photosetLayoutRow
                }
                let photosetLayoutRow = photosetLayoutRows[row]
                
                images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
            }
            
            let imageCount = images.count
            let imageWidth = tableView.frame.size.width / CGFloat(images.count)
            let minHeight = images.map { (image: PostPhoto) -> CGFloat in
                let scale = image.height / image.width
                return imageWidth * scale
                }.reduce(CGFloat.max, combine: { min($0, $1) })
            
            return minHeight
        case "text":
            if let height = self.bodyHeightCache[post.id] {
                return height
            }
            return 0
        case "answer":
            switch AnswerRow(rawValue: row)! {
            case .Question:
                return PostQuestionTableViewCell.heightForPost(post, width: tableView.frame.size.width)
            case .Answer:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "quote":
            switch QuoteRow(rawValue: row)! {
            case .Quote:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            case .Source:
                if let height = self.secondaryBodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "link":
            switch LinkRow(rawValue: row)! {
            case .Link:
                return PostLinkTableViewCell.heightForPost(post, width: tableView.frame.size.width)
            case .Description:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "chat":
            let dialogueEntry = post.dialogueEntries[row]
            return PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: tableView.frame.size.width)
        case "video":
            switch VideoRow(rawValue: row)! {
            case .Player:
                if let height = self.secondaryBodyHeightCache[post.id] {
                    return height
                }
                return 0
            case .Caption:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        case "video":
            switch AudioRow(rawValue: row)! {
            case .Player:
                if let height = self.secondaryBodyHeightCache[post.id] {
                    return height
                }
                return 0
            case .Caption:
                if let height = self.bodyHeightCache[post.id] {
                    return height
                }
                return 0
            }
        default:
            return 0
        }
    }
}

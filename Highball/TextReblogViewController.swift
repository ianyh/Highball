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
    var bodyHeight: CGFloat?
    var secondaryBodyHeight: CGFloat?
    var postViewController: PostViewController!
    var height: CGFloat!

    private var reblogging = false

    private let postHeaderViewIdentifier = "postHeaderViewIdentifier"
    private let photosetRowTableViewCellIdentifier = "photosetRowTableViewCellIdentifier"
    private let contentTableViewCellIdentifier = "contentTableViewCellIdentifier"
    private let postQuestionTableViewCellIdentifier = "postQuestionTableViewCellIdentifier"
    private let postLinkTableViewCellIdentifier = "postLinkTableViewCellIdentifier"
    private let postDialogueEntryTableViewCellIdentifier = "postDialogueEntryTableViewCellIdentifier"

    private let postTableViewCellIdentifier = "postTableViewCellIdentifier"

    override init() {
        super.init(tableViewStyle: UITableViewStyle.Plain)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clearColor()

        self.postViewController = PostViewController()
        self.postViewController.post = self.post
        self.postViewController.bodyHeight = self.bodyHeight
        self.postViewController.secondaryBodyHeight = self.secondaryBodyHeight

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
        self.tableView.backgroundColor = UIColor.clearColor()

        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: postTableViewCellIdentifier)
        self.tableView.registerClass(PhotosetRowTableViewCell.classForCoder(), forCellReuseIdentifier: photosetRowTableViewCellIdentifier)
        self.tableView.registerClass(ContentTableViewCell.classForCoder(), forCellReuseIdentifier: contentTableViewCellIdentifier)
        self.tableView.registerClass(PostQuestionTableViewCell.classForCoder(), forCellReuseIdentifier: postQuestionTableViewCellIdentifier)
        self.tableView.registerClass(PostLinkTableViewCell.classForCoder(), forCellReuseIdentifier: postLinkTableViewCellIdentifier)
        self.tableView.registerClass(PostDialogueEntryTableViewCell.classForCoder(), forCellReuseIdentifier: postDialogueEntryTableViewCellIdentifier)
        self.tableView.registerClass(PostTableHeaderView.classForCoder(), forHeaderFooterViewReuseIdentifier: postHeaderViewIdentifier)

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
                let alertController = UIAlertController(title: "Error", message: e.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { _ in }))
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }

        super.didPressRightButton(sender)
    }

    override func didPressLeftButton(sender: AnyObject!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let post = self.post {
            return 1
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(postTableViewCellIdentifier) as UITableViewCell

        cell.transform = tableView.transform
        cell.backgroundColor = UIColor.whiteColor()

        self.postViewController.view.backgroundColor = UIColor.clearColor()
        cell.contentView.addSubview(self.postViewController.view)

        layout(self.postViewController.view, cell.contentView) { postView, contentView in
            postView.edges == contentView.edges; return
        }

        return cell
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(postHeaderViewIdentifier) as PostTableHeaderView
        
        view.post = self.post
        view.transform = self.tableView.transform
        
        return view
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.height
    }
}

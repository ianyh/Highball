//
//  TextReblogViewController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/17/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import Cartography
import SlackTextViewController
import FontAwesomeKit
import TMTumblrSDK

class TextReblogViewController: SLKTextViewController {
    var reblogType: ReblogType!
    var post: Post!
    var blogName: String!
    var bodyHeight: CGFloat?
    var secondaryBodyHeight: CGFloat?
    var postViewController: PostViewController!
    var height: CGFloat!

    private var reblogging = false
    private var comment: String?
    private var tags: [String] = []

    private enum Section: Int {
        case Comment
        case Post

        static var count: Int {
            return 2
        }
    }

    init() {
        super.init(tableViewStyle: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var reblogTitle: String
        switch reblogType! {
        case .Reblog:
            reblogTitle = "Reblog"
        case .Queue:
            reblogTitle = "Queue"
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: "cancel"
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: reblogTitle,
            style: .Done,
            target: self,
            action: "reblog"
        )

        navigationController?.view.backgroundColor = UIColor.clearColor()
        view.backgroundColor = UIColor.clearColor()

        postViewController = PostViewController()
        postViewController.post = post
        postViewController.bodyHeight = bodyHeight
        postViewController.secondaryBodyHeight = secondaryBodyHeight

        textInputbar.rightButton.setTitle("Add", forState: .Normal)
        textInputbar.autoHideRightButton = false

        tableView.allowsSelection = false
        tableView.backgroundColor = UIColor.clearColor()
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 50
        tableView.sectionFooterHeight = 50
        tableView.separatorStyle = .None
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.cellIdentifier)
        tableView.registerClass(ReblogCommentCell.self, forCellReuseIdentifier: ReblogCommentCell.cellIdentifier)
        tableView.registerClass(PostTableHeaderView.self, forHeaderFooterViewReuseIdentifier: PostTableHeaderView.viewIdentifier)

        let blurEffect = UIBlurEffect(style: .Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        view.insertSubview(vibrancyView, atIndex: 0)
        view.insertSubview(blurView, atIndex: 0)
        
        constrain(blurView, view) { blurView, view in
            blurView.edges == view.edges
        }
        constrain(vibrancyView, view) { vibrancyView, view in
            vibrancyView.edges == view.edges
        }

        let lightBlurEffect = UIBlurEffect(style: .Light)
        let lightBlurView = UIVisualEffectView(effect: lightBlurEffect)
        view.addSubview(lightBlurView)

        constrain(lightBlurView, view) { lightBlurView, view in
            lightBlurView.top == view.top
            lightBlurView.left == view.left
            lightBlurView.right == view.right
            lightBlurView.height == 20
        }
    }

    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func reblog() {
        var parameters = [ "id" : "\(post.id)", "reblog_key" : post.reblogKey ]
        
        switch reblogType as ReblogType {
        case .Reblog:
            parameters["state"] = "published"
        case .Queue:
            parameters["state"] = "queue"
        }
        
        if let comment = comment {
            parameters["comment"] = comment
        }

        if tags.count > 0 {
            parameters["tags"] = tags.joinWithSeparator(",")
        }

        reblogging = true
        
        TMAPIClient.sharedInstance().reblogPost(blogName, parameters: parameters) { response, error in
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }

    override func canPressRightButton() -> Bool {
        return !reblogging && super.canPressRightButton()
    }

    override func didPressRightButton(sender: AnyObject!) {
        defer {
            super.didPressRightButton(sender)
        }

        guard comment != nil else {
            comment = textView.text
            tableView.reloadData()
            return
        }

        tags.append(textView.text)
        tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Post:
            return post == nil ? 0 : 1
        case .Comment:
            return comment == nil ? 0 : 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            let cell = tableView.dequeueReusableCellWithIdentifier(PostTableViewCell.cellIdentifier)!
            
            cell.transform = tableView.transform
            cell.backgroundColor = UIColor.whiteColor()
            
            postViewController.view.backgroundColor = UIColor.clearColor()
            cell.contentView.addSubview(postViewController.view)
            
            constrain(postViewController.view, cell.contentView) { postView, contentView in
                postView.edges == contentView.edges
            }
            
            return cell
        case .Comment:
            let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)

            cell.transform = tableView.transform
            cell.textLabel?.text = comment
            cell.detailTextLabel?.text = tags.map { "#\($0)" }.joinWithSeparator(" ")

            return cell
        }
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch Section(rawValue: section)! {
        case .Post:
            let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(PostTableHeaderView.viewIdentifier) as! PostTableHeaderView
            
            view.post = post
            view.transform = tableView.transform
            
            return view
        case .Comment:
            return nil
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            return height
        case .Comment:
            return 30
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            return height
        case .Comment:
            return UITableViewAutomaticDimension
        }
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch Section(rawValue: section)! {
        case .Post:
            return tableView.sectionFooterHeight
        case .Comment:
            return 0
        }
    }
}

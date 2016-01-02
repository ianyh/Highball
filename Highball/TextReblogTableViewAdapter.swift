//
//  TextReblogTableViewAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/30/15.
//  Copyright © 2015 ianynda. All rights reserved.
//

import Cartography
import UIKit

class TextReblogTableViewAdapter: NSObject {
    var comment: String?
    var tags: [String] = []

    private let tableView: UITableView
    private let post: Post
    private let height: CGFloat

    private enum Section: Int {
        case Comment
        case Post

        static var count: Int {
            return 2
        }
    }

    init(tableView: UITableView, post: Post, height: CGFloat) {
        self.tableView = tableView
        self.post = post
        self.height = height

        super.init()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.allowsSelection = false
        tableView.backgroundColor = UIColor.clearColor()
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension
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
        tableView.registerClass(PostHeaderView.self, forHeaderFooterViewReuseIdentifier: PostHeaderView.viewIdentifier)
        tableView.registerClass(ReblogCommentCell.self, forCellReuseIdentifier: ReblogCommentCell.cellIdentifier)
    }
}

extension TextReblogTableViewAdapter: UITableViewDataSource {
    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }

    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Post:
            return 1
        case .Comment:
            return comment == nil ? 0 : 1
        }
    }

    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            let sectionAdapter = PostSectionAdapter(post: post)
            let adjustedRow = sectionAdapter.numbersOfRows() - indexPath.row - 1
            let cell = sectionAdapter.tableView(tableView, cellForRow: adjustedRow)

            cell.transform = tableView.transform
            cell.backgroundColor = UIColor.whiteColor()

            return cell
        case .Comment:
            let cell = tableView.dequeueReusableCellWithIdentifier(UITableViewCell.cellIdentifier, forIndexPath: indexPath)

            cell.transform = tableView.transform
            cell.textLabel?.text = comment
            cell.detailTextLabel?.text = tags.map { "#\($0)" }.joinWithSeparator(" ")

            return cell
        }
    }
}

extension TextReblogTableViewAdapter: UITableViewDelegate {
    @objc func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch Section(rawValue: section)! {
        case .Post:
            let sectionAdapter = PostSectionAdapter(post: post)
            let view = sectionAdapter.tableViewHeaderView(tableView) as! PostHeaderView

            view.transform = tableView.transform

            return view
        case .Comment:
            return nil
        }
    }

    @objc func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            return height
        case .Comment:
            return 30
        }
    }

    @objc func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .Post:
            return height
        case .Comment:
            return UITableViewAutomaticDimension
        }
    }

    @objc func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch Section(rawValue: section)! {
        case .Post:
            return tableView.sectionFooterHeight
        case .Comment:
            return 0
        }
    }
}

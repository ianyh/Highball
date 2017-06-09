//
//  PostSectionController.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 10/20/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import IGListKit
import UIKit

public class PostSectionController: IGListSectionController, IGListSectionType {
	fileprivate var post: Post!

	public func numberOfItems() -> Int {
		var rowCount = 0

		switch post.type {
		case "photo":
			rowCount = post.layout.rows.count + post.trailData.count
		case "text":
			rowCount = 1 + post.trailData.count
		case "answer":
			rowCount = 1 + post.trailData.count
		case "quote":
			rowCount = 2
		case "link":
			rowCount = 1 + post.trailData.count
		case "chat":
			rowCount = 1 + post.dialogueEntries.count
		case "video":
			rowCount = 1 + post.trailData.count
		case "audio":
			rowCount = 1 + post.trailData.count
		default:
			rowCount = 0
		}

		return rowCount + 1
	}

	public func didUpdate(to object: Any) {
		self.post = object as? Post
	}

	public func cellForItem(at index: Int) -> UICollectionViewCell {
		let row = index

		if row == numberOfItems() - 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: TagsTableViewCell.cellIdentifier) as! TagsTableViewCell
			cell.tags = post.tags
			return cell
		}

		switch post.type {
		case "photo":
			return photoCellWithTableView(tableView, atRow: row)
		case "text":
			return textCellWithTableView(tableView, atRow: row)
		case "answer":
			return answerCellWithTableView(tableView, atRow: row)
		case "quote":
			return quoteCellWithTableView(tableView, atRow: row)
		case "link":
			return linkCellWithTableView(tableView, atRow: row)
		case "chat":
			return chatCellWithTableView(tableView, atRow: row)
		case "video":
			return videoCellWithTableView(tableView, atRow: row)
		case "audio":
			return audioCellWithTableView(tableView, atRow: row)
		default:
			return tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier)!
		}
	}

	fileprivate func photoCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		if row >= numberOfItems() - 1 - post.trailData.count {
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			let trailData = post.trailData[numberOfItems() - 2 - row]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
			return cell!
		}
		let cell = tableView.dequeueReusableCell(withIdentifier: PhotosetRowTableViewCell.cellIdentifier) as! PhotosetRowTableViewCell!
		let postPhotos = post.photos

		cell?.contentWidth = tableView.frame.size.width

		if postPhotos.count == 1 {
			cell?.images = postPhotos
		} else {
			let photosetLayout = post.layout
			var photosIndexStart = 0
			for photosetLayoutRow in photosetLayout.rows[0..<row] {
				photosIndexStart += photosetLayoutRow
			}
			let photosetLayoutRow = photosetLayout.rows[row]

			cell?.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
		}

		return cell!
	}

	fileprivate func textCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.TextRow.textRowFromRow(row) {
		case .title:
			let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
			cell?.titleLabel.text = post.title
			return cell!
		case .body(let index):
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			let trailData = post.trailData[index]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
			return cell!
		}
	}

	fileprivate func answerCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.AnswerRow.answerRowFromRow(row) {
		case .question:
			let cell = tableView.dequeueReusableCell(withIdentifier: PostQuestionTableViewCell.cellIdentifier) as! PostQuestionTableViewCell!
			cell?.post = post
			return cell!
		case .answer(let index):
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			let trailData = post.trailData[index]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
			return cell!
		}
	}

	fileprivate func quoteCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.QuoteRow(rawValue: row)! {
		case .quote:
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell?.width = tableView.bounds.width
			cell?.content = post.htmlBodyWithWidth(tableView.frame.size.width)
			return cell!
		case .source:
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell?.width = tableView.bounds.width
			cell?.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
			return cell!
		}
	}

	fileprivate func linkCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.LinkRow.linkRowFromRow(row) {
		case .link:
			let cell = tableView.dequeueReusableCell(withIdentifier: PostLinkTableViewCell.cellIdentifier) as! PostLinkTableViewCell!
			cell?.post = post
			return cell!
		case .description(let index):
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			let trailData = post.trailData[index]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
			return cell!
		}
	}

	fileprivate func chatCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		if row == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
			cell?.titleLabel.text = post.title
			return cell!
		}
		let dialogueEntry = post.dialogueEntries[row - 1]
		let cell = tableView.dequeueReusableCell(withIdentifier: PostDialogueEntryTableViewCell.cellIdentifier) as! PostDialogueEntryTableViewCell!
		cell?.dialogueEntry = dialogueEntry
		return cell!
	}

	fileprivate func videoCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.VideoRow.videoRowFromRow(row) {
		case .player:
			switch post.video!.type {
			case "youtube":
				let cell = tableView.dequeueReusableCell(withIdentifier: YoutubeTableViewCell.cellIdentifier) as! YoutubeTableViewCell!
				cell?.post = post
				return cell!
			default:
				let cell = tableView.dequeueReusableCell(withIdentifier: VideoTableViewCell.cellIdentifier) as! VideoTableViewCell!
				cell?.post = post
				return cell!
			}
		case .caption(let index):
			let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			let trailData = post.trailData[index]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
			return cell!
		}
	}

	fileprivate func audioCellWithTableView(_ tableView: UITableView, atRow row: Int) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
		switch PostViewSections.AudioRow.audioRowFromRow(row) {
		case .player:
			cell?.width = tableView.bounds.width
			cell?.content = post.htmlSecondaryBodyWithWidth(tableView.frame.width)
		case .caption(let index):
			let trailData = post.trailData[index]
			cell?.width = tableView.bounds.width
			cell?.trailData = trailData
		}
		return cell!
	}

	public func sizeForItem(at index: Int) -> CGSize {
		return CGSize.zero
//		let heightCalculator = PostViewHeightCalculator(width: tableView.bounds.width, postHeightCache: postHeightCache)
//		let height = heightCalculator.heightForPost(post, atRow: row, sectionRowCount: numbersOfRows())
//
//		return height
	}

	public func tableViewHeaderView(_ tableView: UITableView) -> UIView? {
		let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: PostHeaderView.viewIdentifier) as! PostHeaderView

		view.post = post

		return view
	}

	public func setBodyComponentHeight(_ height: CGFloat, forIndexPath indexPath: IndexPath, withKey key: String, inHeightCache postHeightCache: PostHeightCache) -> Bool {
		let row = (indexPath as NSIndexPath).row
		let heightIndex = { () -> Int in
			switch post.type {
			case "photo":
				return numbersOfRows() - 2 - row
			case "text":
				return row - 1
			case "answer":
				return row - 1
			case "quote":
				return 0
			case "link":
				return row - 1
			case "chat":
				return row - 1
			case "video":
				return row - 1
			case "audio":
				return row - 1
			default:
				return 0
			}
		}()

		guard height != postHeightCache.bodyComponentHeightForPost(post, atIndex: heightIndex, withKey: key) else {
			return false
		}

		postHeightCache.setBodyComponentHeight(height, forPost: post, atIndex: heightIndex, withKey: key)

		return true
	}
}

//
//  PostSectionAdapter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import UIKit

struct PostViewSections {
	enum TextRow {
		case Title
		case Body(row: Int)

		static func textRowFromRow(row: Int) -> TextRow {
			if row == 0 {
				return .Title
			} else {
				return .Body(row: row - 1)
			}
		}
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

struct PostSectionAdapter {
	let post: Post

	func numbersOfRows() -> Int {
		var rowCount = 0

		switch post.type {
		case "photo":
			let postPhotos = post.photos
			if postPhotos.count == 1 {
				rowCount = 2
			}
			rowCount = post.layoutRows.layoutRows.count + 1
		case "text":
			rowCount = 1 + post.bodies.count
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

	func tableView(tableView: UITableView, cellForRow row: Int) -> UITableViewCell {
		if row == numbersOfRows() - 1 {
			let cell = tableView.dequeueReusableCellWithIdentifier(TagsTableViewCell.cellIdentifier) as! TagsTableViewCell!
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
			return tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier)!
		}
	}

	private func photoCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		if row == numbersOfRows() - 2 {
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
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
			for photosetLayoutRow in photosetLayoutRows.layoutRows[0..<row] {
				photosIndexStart += photosetLayoutRow
			}
			let photosetLayoutRow = photosetLayoutRows.layoutRows[row]

			cell.images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
		}

		return cell
	}

	private func textCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.TextRow.textRowFromRow(row) {
		case .Title:
			let cell = tableView.dequeueReusableCellWithIdentifier(TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
			cell.titleLabel.text = post.title
			return cell
		case .Body(let index):
			let content = post.bodies[index]
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = content.htmlStringWithTumblrStyle(0) //post.htmlBodyWithWidth(tableView.frame.size.width)
			return cell
		}
	}

	private func answerCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.AnswerRow(rawValue: row)! {
		case .Question:
			let cell = tableView.dequeueReusableCellWithIdentifier(PostQuestionTableViewCell.cellIdentifier) as! PostQuestionTableViewCell!
			cell.post = post
			return cell
		case .Answer:
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
			return cell
		}
	}

	private func quoteCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.QuoteRow(rawValue: row)! {
		case .Quote:
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = post.htmlBodyWithWidth(tableView.frame.size.width)
			return cell
		case .Source:
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.size.width)
			return cell
		}
	}

	private func linkCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.LinkRow(rawValue: row)! {
		case .Link:
			let cell = tableView.dequeueReusableCellWithIdentifier(PostLinkTableViewCell.cellIdentifier) as! PostLinkTableViewCell!
			cell.post = post
			return cell
		case .Description:
			let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
			cell.content = post.htmlBodyWithWidth(tableView.frame.width)
			return cell
		}
	}

	private func chatCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		if row == 0 {
			let cell = tableView.dequeueReusableCellWithIdentifier(TitleTableViewCell.cellIdentifier) as! TitleTableViewCell!
			cell.titleLabel.text = post.title
			return cell
		}
		let dialogueEntry = post.dialogueEntries[row - 1]
		let cell = tableView.dequeueReusableCellWithIdentifier(PostDialogueEntryTableViewCell.cellIdentifier) as! PostDialogueEntryTableViewCell!
		cell.dialogueEntry = dialogueEntry
		return cell
	}

	private func videoCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		switch PostViewSections.VideoRow(rawValue: row)! {
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
			cell.content = post.htmlBodyWithWidth(tableView.frame.width)
			return cell
		}
	}

	private func audioCellWithTableView(tableView: UITableView, atRow row: Int) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(ContentTableViewCell.cellIdentifier) as! ContentTableViewCell!
		switch PostViewSections.AudioRow(rawValue: row)! {
		case .Player:
			cell.content = post.htmlSecondaryBodyWithWidth(tableView.frame.width)
		case .Caption:
			cell.content = post.htmlBodyWithWidth(tableView.frame.width)
		}
		return cell
	}

	func tableView(tableView: UITableView, heightForCellAtRow row: Int, bodyHeight: CGFloat?, secondaryBodyHeight: CGFloat?, bodyHeights: [String: CGFloat]) -> CGFloat {
		let heightCalculator = PostViewHeightCalculator(width: tableView.frame.width, bodyHeight: bodyHeight, secondaryBodyHeight: secondaryBodyHeight, bodyHeights: bodyHeights)
		let height = heightCalculator.heightForPost(post, atRow: row, sectionRowCount: numbersOfRows())

		return height
	}

	func tableViewHeaderView(tableView: UITableView) -> UIView? {
		let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(PostHeaderView.viewIdentifier) as! PostHeaderView

		view.post = post

		return view
	}
}

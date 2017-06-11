//
//  PostViewHeightCalculator.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 1/1/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import UIKit

struct PostViewHeightCalculator {
	let width: CGFloat
	let postHeightCache: PostHeightCache

	func heightForPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row == sectionRowCount - 2 {
			return post.tags.count > 0 ? 30 : 0
		}

		if row == sectionRowCount - 1 {
			return 50
		}

		switch post.type {
		case "photo":
			return photoHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "text":
			return textHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "answer":
			return answerHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "quote":
			return quoteHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "link":
			return linkHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "chat":
			return chatHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "video":
			return videoHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		case "audio":
			return audioHeightWithPost(post, atRow: row, sectionRowCount: sectionRowCount)
		default:
			return 0
		}
	}

	fileprivate func photoHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row >= sectionRowCount - 2 - post.trailData.count {
			let index = sectionRowCount - 3 - row
			let bodyHeight = postHeightCache.bodyHeight(post, atIndex: index)
			return bodyHeight ?? 0
		}

		let postPhotos = post.photos
		var images: [PostPhoto]!

		if postPhotos.count == 1 {
			images = postPhotos
		} else {
			let photosetLayout = post.layout
			var photosIndexStart = 0
			for photosetLayoutRow in photosetLayout.rows[0..<row] {
				photosIndexStart += photosetLayoutRow
			}
			let photosetLayoutRow = photosetLayout.rows[row]

			images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
		}

		let imageWidth = width / CGFloat(images.count)
		let minHeight = floor(images
			.map { (image: PostPhoto) -> CGFloat in
				let scale = image.height / image.width
				return imageWidth * scale
			}
			.reduce(CGFloat.greatestFiniteMagnitude) { min($0, $1) }
		)

		return minHeight
	}

	fileprivate func textHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.TextRow.textRowFromRow(row) {
		case .title:
			if let title = post.title {
				let height = TitleTableViewCell.heightForTitle(title, width: width)
				return height
			}
			return 0
		case .body(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	fileprivate func answerHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.AnswerRow.answerRowFromRow(row) {
		case .question:
			let height = PostQuestionTableViewCell.heightForPost(post, width: width)
			return height
		case .answer(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}

	}

	fileprivate func quoteHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.QuoteRow(rawValue: row)! {
		case .quote:
			return postHeightCache.bodyHeightForPost(post) ?? 0
		case .source:
			return postHeightCache.secondaryBodyHeightForPost(post) ?? 0
		}
	}

	fileprivate func linkHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.LinkRow.linkRowFromRow(row) {
		case .link:
			return PostLinkTableViewCell.heightForPost(post, width: width)
		case .description(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	fileprivate func chatHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row == 0 {
			guard let title = post.title else {
				return 0
			}

			return TitleTableViewCell.heightForTitle(title, width: width)
		}

		let dialogueEntry = post.dialogueEntries[row - 1]

		return PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: width)
	}

	fileprivate func videoHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.VideoRow.videoRowFromRow(row) {
		case .player:
			return post.videoHeightWidthWidth(width) ?? 320
		case .caption(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	fileprivate func audioHeightWithPost(_ post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.AudioRow.audioRowFromRow(row) {
		case .player:
			return postHeightCache.secondaryBodyHeightForPost(post) ?? 0
		case .caption(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}
}

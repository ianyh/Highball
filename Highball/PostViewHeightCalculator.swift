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

	func heightForPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row == sectionRowCount - 1 {
			return post.tags.count > 0 ? 30 : 0
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

	private func photoHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row >= sectionRowCount - 1 - post.trailData.count {
			let index = sectionRowCount - 2 - row
			let bodyHeight = postHeightCache.bodyHeight(post, atIndex: index)
			return bodyHeight ?? 0
		}

		let postPhotos = post.photos
		var images: Array<PostPhoto>!

		if postPhotos.count == 1 {
			images = postPhotos
		} else {
			let photosetLayoutRows = post.layoutRows
			var photosIndexStart = 0
			for photosetLayoutRow in photosetLayoutRows.layoutRows[0..<row] {
				photosIndexStart += photosetLayoutRow
			}
			let photosetLayoutRow = photosetLayoutRows.layoutRows[row]

			images = Array(postPhotos[(photosIndexStart)..<(photosIndexStart + photosetLayoutRow)])
		}

		let imageWidth = width / CGFloat(images.count)
		let minHeight = floor(images
			.map { (image: PostPhoto) -> CGFloat in
				let scale = image.height / image.width
				return imageWidth * scale
			}
			.reduce(CGFloat.max) { min($0, $1) }
		)

		return minHeight
	}

	private func textHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.TextRow.textRowFromRow(row) {
		case .Title:
			if let title = post.title {
				let height = TitleTableViewCell.heightForTitle(title, width: width)
				return height
			}
			return 0
		case .Body(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	private func answerHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.AnswerRow.answerRowFromRow(row) {
		case .Question:
			let height = PostQuestionTableViewCell.heightForPost(post, width: width)
			return height
		case .Answer(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}

	}

	private func quoteHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.QuoteRow(rawValue: row)! {
		case .Quote:
			return postHeightCache.bodyHeightForPost(post) ?? 0
		case .Source:
			return postHeightCache.secondaryBodyHeightForPost(post) ?? 0
		}
	}

	private func linkHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.LinkRow.linkRowFromRow(row) {
		case .Link:
			return PostLinkTableViewCell.heightForPost(post, width: width)
		case .Description(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	private func chatHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row == 0 {
			guard let title = post.title else {
				return 0
			}

			return TitleTableViewCell.heightForTitle(title, width: width)
		}

		let dialogueEntry = post.dialogueEntries[row - 1]

		return PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: width)
	}

	private func videoHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.VideoRow.videoRowFromRow(row) {
		case .Player:
			return post.videoHeightWidthWidth(width) ?? 320
		case .Caption(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}

	private func audioHeightWithPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		switch PostViewSections.AudioRow.audioRowFromRow(row) {
		case .Player:
			return postHeightCache.secondaryBodyHeightForPost(post) ?? 0
		case .Caption(let index):
			return postHeightCache.bodyHeight(post, atIndex: index) ?? 0
		}
	}
}

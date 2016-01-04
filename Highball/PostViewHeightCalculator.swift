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
	let bodyHeight: CGFloat?
	let secondaryBodyHeight: CGFloat?

	func heightForPost(post: Post, atRow row: Int, sectionRowCount: Int) -> CGFloat {
		if row == sectionRowCount - 1 {
			return post.tags.count > 0 ? 30 : 0
		}

		switch post.type {
		case "photo":
			if row == sectionRowCount - 2 {
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
		case "text":
			switch PostViewSections.TextRow(rawValue: row)! {
			case .Title:
				if let title = post.title {
					let height = TitleTableViewCell.heightForTitle(title, width: width)
					return height
				}
				return 0
			case .Body:
				return bodyHeight ?? 0
			}
		case "answer":
			switch PostViewSections.AnswerRow(rawValue: row)! {
			case .Question:
				let height = PostQuestionTableViewCell.heightForPost(post, width: width)
				return height
			case .Answer:
				return bodyHeight ?? 0
			}
		case "quote":
			switch PostViewSections.QuoteRow(rawValue: row)! {
			case .Quote:
				return bodyHeight ?? 0
			case .Source:
				return secondaryBodyHeight ?? 0
			}
		case "link":
			switch PostViewSections.LinkRow(rawValue: row)! {
			case .Link:
				return PostLinkTableViewCell.heightForPost(post, width: width)
			case .Description:
				return bodyHeight ?? 0
			}
		case "chat":
			if row == 0 {
				guard let title = post.title else {
					return 0
				}

				return TitleTableViewCell.heightForTitle(title, width: width)
			}

			let dialogueEntry = post.dialogueEntries[row - 1]

			return PostDialogueEntryTableViewCell.heightForPostDialogueEntry(dialogueEntry, width: width)
		case "video":
			switch PostViewSections.VideoRow(rawValue: row)! {
			case .Player:
				return post.videoHeightWidthWidth(width) ?? 320
			case .Caption:
				return bodyHeight ?? 0
			}
		case "video":
			switch PostViewSections.AudioRow(rawValue: row)! {
			case .Player:
				return secondaryBodyHeight ?? 0
			case .Caption:
				return bodyHeight ?? 0
			}
		default:
			return 0
		}
	}
}

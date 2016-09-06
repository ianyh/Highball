//
//  ConversationsListPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

public class ConversationsListPresenter {
	public weak var view: ConversationsListView?
	public var dataManager: ConversationsListDataManager?

	public func viewDidAppear() {
		dataManager?.reloadData()
	}

	public func numberOfConversations() -> Int {
		return dataManager?.conversations.count ?? 0
	}

	public func conversationAtIndex(index: Int) -> Conversation {
		return dataManager!.conversations[index]
	}
}

extension ConversationsListPresenter: ConversationsListDataManagerDelegate {
	public func listDataManagerDidReload(dataManager: ConversationsListDataManager) {
		view?.reloadView()
	}
}

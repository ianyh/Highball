//
//  ConversationsListPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/5/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation

open class ConversationsListPresenter {
	open weak var view: ConversationsListView?
	open var dataManager: ConversationsListDataManager?

	open func viewDidAppear() {
		dataManager?.reloadData()
	}

	open func numberOfConversations() -> Int {
		return dataManager?.conversations.count ?? 0
	}

	open func conversationAtIndex(_ index: Int) -> Conversation {
		return dataManager!.conversations[index]
	}
}

extension ConversationsListPresenter: ConversationsListDataManagerDelegate {
	public func listDataManagerDidReload(_ dataManager: ConversationsListDataManager) {
		view?.reloadView()
	}
}

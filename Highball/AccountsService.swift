//
//  AccountsService.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/16/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import OAuthSwift
import RealmSwift
import SwiftyJSON
import TMTumblrSDK
import UIKit

public struct AccountsService {
	private static let lastAccountNameKey = "HILastAccountKey"

	public private(set) static var account: Account!

	public static func accounts() -> [Account] {
		guard let realm = try? Realm() else {
			return []
		}

		return try! realm.objects(AccountObject).map { $0 }
	}

	public static func lastAccount() -> Account? {
		let userDefaults = NSUserDefaults.standardUserDefaults()

		guard let accountName = userDefaults.stringForKey(lastAccountNameKey) else {
			return nil
		}

		guard let realm = try? Realm() else {
			return nil
		}

		guard let account = realm.objectForPrimaryKey(AccountObject.self, key: accountName) else {
			return nil
		}

		return account
	}

	public static func start(fromViewController viewController: UIViewController, completion: (Account) -> ()) {
		if let lastAccount = lastAccount() {
			loginToAccount(lastAccount, completion: completion)
			return
		}

		guard let firstAccount = accounts().first else {
			authenticateNewAccount(fromViewController: viewController) { account in
				if let account = account {
					self.loginToAccount(account, completion: completion)
				} else {
					self.start(fromViewController: viewController, completion: completion)
				}
			}
			return
		}

		loginToAccount(firstAccount, completion: completion)
	}

	public static func loginToAccount(account: Account, completion: (Account) -> ()) {
		self.account = account

		TMAPIClient.sharedInstance().OAuthToken = account.token
		TMAPIClient.sharedInstance().OAuthTokenSecret = account.tokenSecret

		dispatch_async(dispatch_get_main_queue()) {
			completion(account)
		}
	}

	public static func authenticateNewAccount(fromViewController viewController: UIViewController, completion: (account: Account?) -> ()) {
		let oauth = OAuth1Swift(
			consumerKey: TMAPIClient.sharedInstance().OAuthConsumerKey,
			consumerSecret: TMAPIClient.sharedInstance().OAuthConsumerSecret,
			requestTokenUrl: "https://www.tumblr.com/oauth/request_token",
			authorizeUrl: "https://www.tumblr.com/oauth/authorize",
			accessTokenUrl: "https://www.tumblr.com/oauth/access_token"
		)
		let currentAccount: Account? = account

		account = nil

		TMAPIClient.sharedInstance().OAuthToken = nil
		TMAPIClient.sharedInstance().OAuthTokenSecret = nil

		oauth.authorize_url_handler = SafariURLHandler(viewController: viewController)

		oauth.authorizeWithCallbackURL(
			NSURL(string: "highball://oauth-callback")!,
			success: { (credential, response, parameters) in
				TMAPIClient.sharedInstance().OAuthToken = credential.oauth_token
				TMAPIClient.sharedInstance().OAuthTokenSecret = credential.oauth_token_secret

				TMAPIClient.sharedInstance().userInfo { response, error in
					var account: Account?

					defer {
						completion(account: account)
					}

					if let error = error {
						print(error)
						return
					}

					let json = JSON(response)

					guard let blogsJSON = json["user"]["blogs"].array else {
						return
					}

					let blogs = blogsJSON.map { blogJSON -> UserBlogObject in
						let blog = UserBlogObject()
						blog.name = blogJSON["name"].stringValue
						blog.url = blogJSON["url"].stringValue
						blog.title = blogJSON["title"].stringValue
						blog.isPrimary = blogJSON["primary"].boolValue
						return blog
					}

					let accountObject = AccountObject()
					accountObject.name = json["name"].stringValue
					accountObject.token = TMAPIClient.sharedInstance().OAuthToken
					accountObject.tokenSecret = TMAPIClient.sharedInstance().OAuthTokenSecret
					accountObject.blogObjects.appendContentsOf(blogs)

					guard let realm = try? Realm() else {
						return
					}

					do {
						try realm.write {
							realm.add(accountObject, update: true)
						}
					} catch {
						print(error)
						return
					}

					account = accountObject

					self.account = currentAccount

					TMAPIClient.sharedInstance().OAuthToken = currentAccount?.token
					TMAPIClient.sharedInstance().OAuthTokenSecret = currentAccount?.tokenSecret
				}
			},
			failure: { (error) in
				print(error)
			}
		)
	}

	public static func deleteAccount(account: Account, fromViewController viewController: UIViewController, completion: (changedAccount: Bool) -> ()) {
		if self.account == account {
			self.account = nil

			start(fromViewController: viewController) { _ in
				completion(changedAccount: true)
			}
		}

		dispatch_async(dispatch_get_main_queue()) {
			completion(changedAccount: false)
		}
	}
}

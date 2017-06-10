//
//  AppDelegate.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Fabric
import Crashlytics

import UIKit
import TMTumblrSDK
import PINCache
import PINRemoteImage
import Reachability
import VENTouchLock
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var tabBarController: UITabBarController?
	var reachability: Reachability!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		reachability = Reachability.forLocalWiFi()
		reachability.startNotifier()

		TMAPIClient.sharedInstance().oAuthConsumerKey = "YhlYiD2dAUE6UH01ugPKQafm2XESBWsaOYPz7xV0q53SDn3ChU"
		TMAPIClient.sharedInstance().oAuthConsumerSecret = "ONVNS5UCfZMMhrekfjBknUXgjQ5I2J1a0aVDCfso2mfRcC4nEF"

		let imageCache = PINRemoteImageManager.shared().cache.diskCache
		let cache = PINCache.shared().diskCache

		// Only keep cache for 12 hours
		imageCache.ageLimit = 43200
		cache.ageLimit = 43200
		// Only keep up to 500 mb cache
		imageCache.byteLimit = 524288000
		cache.byteLimit = 524288000

		tabBarController = window?.rootViewController as? UITabBarController

		if let bundleInfoDictionary = Bundle.main.infoDictionary {
			if bundleInfoDictionary["HBCrashlyticsAPIKey"] != nil {
				Fabric.with([Crashlytics.self])
			}
		}

		VENTouchLock.sharedInstance().backgroundLockVisible = false
		VENTouchLock.sharedInstance().setKeychainService(
			"com.highball.Highball",
			keychainAccount: "com.highball",
			touchIDReason: "Scan fingerprint to open.",
			passcodeAttemptLimit: UInt.max,
			splashViewControllerClass: LockSplashViewController.classForCoder()
		)

		UIApplication.shared.statusBarStyle = .lightContent

		let backgroundColor = UIColor.flatSkyBlueColorDark().lighten(byPercentage: 0.5)

		UINavigationBar.appearance().barTintColor = backgroundColor
		UINavigationBar.appearance().tintColor = UIColor.white
		UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]

		UITabBar.appearance().tintColor = backgroundColor

		window?.rootViewController?.setStatusBarStyle(.lightContent)
		window?.tintColor = UIColor.flatSkyBlueColorDark().lighten(byPercentage: 0.5)
		window?.makeKeyAndVisible()

		AccountsService.start(fromViewController: tabBarController!) { _ in
			(self.tabBarController! as! MainViewController).reset()
		}

		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		if url.host == "oauth-callback" {
			OAuthSwift.handle(url: url)
		}
		return true
	}

	func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
		AnimatedImageCache.clearCache()
	}
}

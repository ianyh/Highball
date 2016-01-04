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
import WebKit
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

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		reachability = Reachability.reachabilityForLocalWiFi()
		reachability.startNotifier()

		TMAPIClient.sharedInstance().OAuthConsumerKey = "YhlYiD2dAUE6UH01ugPKQafm2XESBWsaOYPz7xV0q53SDn3ChU"
		TMAPIClient.sharedInstance().OAuthConsumerSecret = "ONVNS5UCfZMMhrekfjBknUXgjQ5I2J1a0aVDCfso2mfRcC4nEF"

		let imageCache = PINRemoteImageManager.sharedImageManager().cache.diskCache
		let cache = PINCache.sharedCache().diskCache

		// Only keep cache for 12 hours
		imageCache.ageLimit = 43200
		cache.ageLimit = 43200
		// Only keep up to 500 mb cache
		imageCache.byteLimit = 524288000
		cache.byteLimit = 524288000

		tabBarController = window?.rootViewController as? UITabBarController

		if let bundleInfoDictionary = NSBundle.mainBundle().infoDictionary {
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

		UIApplication.sharedApplication().statusBarStyle = .LightContent

		let backgroundColor = UIColor.flatSkyBlueColorDark().lightenByPercentage(0.5)

		UINavigationBar.appearance().barTintColor = backgroundColor
		UINavigationBar.appearance().tintColor = UIColor.whiteColor()
		UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

		UITabBar.appearance().tintColor = backgroundColor

		window?.rootViewController?.setStatusBarStyle(.LightContent)
		window?.tintColor = UIColor.flatSkyBlueColorDark().lightenByPercentage(0.5)
		window?.makeKeyAndVisible()

		AccountsService.start(fromViewController: tabBarController!) {
		}

		return true
	}

	func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
		if url.host == "oauth-callback" {
			OAuthSwift.handleOpenURL(url)
		}
		return true
	}

	func applicationDidReceiveMemoryWarning(application: UIApplication) {
		AnimatedImageCache.clearCache()
	}
}

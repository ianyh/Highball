//
//  AppDelegate.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import WebKit
import TMTumblrSDK
import Reachability
import TMCache
import VENTouchLock
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController: UINavigationController?
    var reachability: Reachability!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        self.reachability = Reachability.reachabilityForLocalWiFi()
        self.reachability.startNotifier()

        TMAPIClient.sharedInstance().OAuthConsumerKey = "YhlYiD2dAUE6UH01ugPKQafm2XESBWsaOYPz7xV0q53SDn3ChU"
        TMAPIClient.sharedInstance().OAuthConsumerSecret = "ONVNS5UCfZMMhrekfjBknUXgjQ5I2J1a0aVDCfso2mfRcC4nEF"

        // Only keep cache for 12 hours
        TMCache.sharedCache().diskCache.ageLimit = 43200
        // Only keep up to 500 mb cache
        TMCache.sharedCache().diskCache.byteLimit = 524288000

        self.navigationController = window?.rootViewController as? UINavigationController

        if let bundleInfoDictionary = NSBundle.mainBundle().infoDictionary {
            if let key = bundleInfoDictionary["HBCrashlyticsAPIKey"] as? NSString {
                Crashlytics.startWithAPIKey(key as String)
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

        self.window?.makeKeyAndVisible()

        AccountsService.start(fromViewController: navigationController!) {
            self.navigationController?.viewControllers = [DashboardViewController()]; return
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

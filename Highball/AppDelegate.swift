//
//  AppDelegate.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/24/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import UIKit
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController: UINavigationController?

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        TMAPIClient.sharedInstance().OAuthConsumerKey = "YhlYiD2dAUE6UH01ugPKQafm2XESBWsaOYPz7xV0q53SDn3ChU"
        TMAPIClient.sharedInstance().OAuthConsumerSecret = "ONVNS5UCfZMMhrekfjBknUXgjQ5I2J1a0aVDCfso2mfRcC4nEF"

        // Only keep cache for 12 hours
        TMCache.sharedCache().diskCache.ageLimit = 43200

        self.navigationController = UINavigationController()
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = self.navigationController

        AccountsService.start { () -> () in
            self.navigationController?.viewControllers = [DashboardViewController()]; return
        }

        if let bundleInfoDictionary = NSBundle.mainBundle().infoDictionary {
            if let key = bundleInfoDictionary["HBCrashlyticsAPIKey"] as? NSString {
                Crashlytics.startWithAPIKey(key)
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

        return true
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return TMAPIClient.sharedInstance().handleOpenURL(url)
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        AnimatedImageCache.clearCache()
    }
}

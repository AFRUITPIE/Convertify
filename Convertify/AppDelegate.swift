//
//  AppDelegate.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var link: String?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationDidBecomeActive(_: UIApplication) {
        resetAppLink()
    }

    private func resetAppLink() {
        let viewController = window?.rootViewController as! ViewController
        let pasteBoardValue = UIPasteboard.general.string

        // Only redoes search with new links, doesn't attempt searching when there is no string in pasteboard
        if pasteBoardValue == nil {
            viewController.initApp(link: "")
        } else if link != pasteBoardValue {
            link = pasteBoardValue
            viewController.initApp(link: pasteBoardValue ?? "")
        }
    }
}

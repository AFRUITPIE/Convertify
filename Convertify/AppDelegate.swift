//
//  AppDelegate.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import SpotifyLogin
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var link: String?

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let handled = SpotifyLogin.shared.applicationOpenURL(url) { _ in }

        let viewController = window?.rootViewController as! ViewController
        viewController.continueAfterSpotifyAuth()

        return handled
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SpotifyLogin.shared.configure(clientID: Auth.spotifyClientID, clientSecret: Auth.spotifyClientSecret, redirectURL: URL(string: "convertify://")!)
        return true
    }
}

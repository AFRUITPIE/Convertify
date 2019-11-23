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

    /// Handle continue after Spotify auth
    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let handled = SpotifyLogin.shared.applicationOpenURL(url) { _ in }

        return handled
    }

    /// Launch application -- entry point
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SpotifyLogin.shared.configure(clientID: Auth.spotifyClientID, clientSecret: Auth.spotifyClientSecret, redirectURL: URL(string: "convertify://")!)
        return true
    }
}

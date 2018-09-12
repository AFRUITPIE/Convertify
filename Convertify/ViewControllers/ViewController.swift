//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import SpotifyLogin
import UIKit

class ViewController: UIViewController {
    var spotifyTokenValid = false

    private var appleMusic: MusicSearcher = appleMusicSearcher()
    private var spotify: MusicSearcher = spotifySearcher()
    private var link: String?

    // Mark: Properties

    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!

    // Mark: Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        if let pasteBoardValue = UIPasteboard.general.string {
            setLink(link: pasteBoardValue)
        }
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
        initializeApp()
    }

    /// Handles ensuring that Spotify is logged in before handling the clipboard link
    @objc func initializeApp() {
        logoutButton.isHidden = true
        getSpotifyToken { error in
            if error == nil {
                self.spotifyTokenValid = true
                self.handleLink(link: self.link ?? "")
                self.logoutButton.isHidden = false

            } else {
                self.spotifyTokenValid = false
            }
        }
    }

    /// Updates the link
    ///
    /// - Parameter link: link to set this object to
    func setLink(link: String) {
        self.link = link
    }

    /// Animates the color conversion in the app
    ///
    /// - Parameters:
    ///   - title: Name to set the label to
    ///   - color: Color to set the background to
    ///   - enabled: Whether or not the convert button should be shown
    private func updateAppearance(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        }, completion: nil)

        convertButton.isEnabled = enabled
    }

    /// Ensures the Spotify token is valid
    private func getSpotifyToken(completion: @escaping (Error?) -> Void) {
        SpotifyLogin.shared.getAccessToken { accessToken, error in
            // Set the token if possible, initialize login flow if not possible
            if accessToken != nil {
                self.spotify.token = accessToken
                completion(nil)
            } else {
                // Alert users to needing Spotify login
                let alert = UIAlertController(title: "Spotify Login Not Found",
                                              message: "This app requires a Spotify account. Please login now.",
                                              preferredStyle: .alert)

                // Action to add to the alert
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("Login", comment: "Open Spotify Login"), style: .default, handler: { _ in
                        // Open the Spotify login prompt
                        SpotifyLoginPresenter.login(from: self, scopes: [])

                        // Adds a listener that retries the Spotify login and link handling when successfully logged in
                        NotificationCenter.default.addObserver(self, selector: #selector(self.initializeApp), name: .SpotifyLoginSuccessful, object: nil)
                    }
                ))

                // Present the alert, user MUST click login to continue
                self.present(alert, animated: true, completion: nil)
            }

            if error != nil {
                print(error ?? "")
            }
        }
    }

    /// "Connects" Apple Music and Spotify for searching between them. Finds matching
    /// data from opposite source and allows the user to open links in opposite app.
    ///
    /// - Parameter link: Link to handle
    func handleLink(link: String) {
        // Resets the label text while converting
        titleLabel.text = "Convertify"

        // Decides what to do with the link
        switch true {
        // Ignores playlists
        case link.contains("playlist"):
            updateAppearance(title: "I cannot convert playlists ☹️", color: UIColor.red, enabled: false)
            break
        // Ignores radio stations
        case link.contains("/station/"):
            updateAppearance(title: "I cannot convert radio stations ☹️", color: UIColor.red, enabled: false)
            break
        // Extracts Spotify data and searches for Apple Music links when it includes a Spotify link
        case link.contains(SearcherURL.spotify):
            // Get the Apple Music version if the link is Spotify, double check for Spotify login
            handleSearching(link: link, source: spotify, destination: appleMusic)
            break
        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.contains(SearcherURL.appleMusic):
            handleSearching(link: link, source: appleMusic, destination: spotify)
            break
        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No Spotify or Apple Music link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }

    /// Handles searching between the source and destination
    ///
    /// - Parameters:
    ///   - link: link to search with
    ///   - source: Source service of the link
    ///   - destination: Destination to open the search result in
    private func handleSearching(link: String, source: MusicSearcher, destination: MusicSearcher) {
        source.search(link: link)?
            .validate()
            .responseJSON { response in
                if response.error != nil {
                    self.titleLabel.text = "Error getting \(source.serviceName) data"
                    self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                } else if response.result.value != nil {
                    if source.artist != nil {
                        self.titleLabel.text = source.name! + " by " + source.artist!
                    } else {
                        self.titleLabel.text = source.name!
                    }

                    destination.search(name: source.name! + " " + (source.artist ?? ""), type: source.type!)
                        .validate()
                        .responseJSON { _ in
                            self.updateAppearance(title: "Open in \(destination.serviceName)", color: destination.serviceColor, enabled: true)
                        }
                }
            }
    }

    // Mark: Actions

    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link?.contains(SearcherURL.spotify) ?? false {
            appleMusic.open()
        } else if link?.contains(SearcherURL.appleMusic) ?? false {
            spotify.open()
        }
    }

    /// Logs user out of Spotify
    @IBAction func logoutSpotify(_: Any) {
        spotify.token = nil
        SpotifyLogin.shared.logout()
        spotifyTokenValid = false
        logoutButton.isHidden = true
        updateAppearance(title: "", color: UIColor.black, enabled: false)
        initializeApp()
    }
}

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
    private var appleMusic = appleMusicSearcher()
    private var spotify = spotifySearcher()
    var link: String?
    
    // Mark: Properties
    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(setupSpotifyCredentials), name: .SpotifyLoginSuccessful, object: nil)
        
        // Ensures Spotify is logged in
        setupSpotifyCredentials()
    }
    
    // FIXME: Probably best to handle this in the meat of the app so errors are more clear
    /// Changes the appearance of the app and button based on the link
    @objc func changeButtonAppearance() {
        // Set the style of the app based on the link in the cliboard
        if link?.contains("https://open.spotify.com/") ?? false {
            setConvertButton(title: "Open in Apple Music", color: UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0), enabled: true)
            convertButton.isEnabled = true
        } else if link?.contains("https://itunes.apple.com/") ?? false {
            setConvertButton(title: "Open in Spotify", color: UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0), enabled: true)
        } else {
            setConvertButton(title: "No link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }
    
    /// Animates the color conversion in the app
    ///
    /// - Parameters:
    ///   - title: Name to set the label as
    ///   - color: Color to set the background as
    ///   - enabled: Whether or not the convert button should be shown
    private func setConvertButton(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        }, completion: nil)
        
        convertButton.isEnabled = enabled
    }
    
    // FIXME: Is this too similar to finishLogin()?
    /// Sets up Spotify credentials
    @objc func setupSpotifyCredentials() {
        SpotifyLogin.shared.getAccessToken { accessToken, error in
            if accessToken != nil {
                self.spotify.token = accessToken
            } else {
                // Alert users to needing Spotify login
                let alert = UIAlertController(title: "Spotify Login Not Found", message: "This app requires a Spotify account. Please login now.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: "Open Spotify Login"), style: .default, handler: { _ in
                    // Open the Spotify login prompt
                    SpotifyLoginPresenter.login(from: self, scopes: [])
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            if error != nil {
                print(error ?? "")
            }
        }
    }
    
    /// Completes the Spotify login and sets the credentials
    @objc func finishLogin() {
        // Requests Spotify access token
        SpotifyLogin.shared.getAccessToken { accessToken, _ in
            if accessToken != nil {
                // Sets the Spotify token if there are no problems
                self.spotify.token = accessToken
            } else {
                // Logout just in case when there is no access token
                SpotifyLogin.shared.logout()
                
                // Alerts the user to needing to log into Spotify again
                let alert = UIAlertController(title: "We had trouble logging in", message: "Please try logging into Spotify again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry Spotify login"), style: .default, handler: { _ in
                    // restart Spotify login flow
                    self.setupSpotifyCredentials()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /// "Connects" Apple Music and Spotify for searching between them. Finds matching
    /// data from opposite source and allows the user to open links in opposite app.
    func handleLink() {
        // Resets the label text while converting
        titleLabel.text = "Convertify"
        
        // Playlists are ignored since they probably won't match
        if link?.contains("playlist") ?? false {
            setConvertButton(title: "I cannot convert playlists", color: UIColor.red, enabled: false)
        } else if link?.contains("https://open.spotify.com/") ?? false {
            // Get the Apple Music version if the link is Spotify
            if spotify.token != nil {
                spotify.search(link: link!)?
                    .validate()
                    .responseJSON { response in
                        // Sets the text of the label to the content that was found
                        if (response.error != nil) {
                            self.titleLabel.text = "Error getting Spotify data"
                            self.setConvertButton(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                        } else if response.result.value != nil {
                            if self.spotify.artist != nil {
                                self.titleLabel.text = self.spotify.name! + " by " + self.spotify.artist!
                            } else {
                                self.titleLabel.text = self.spotify.name!
                            }
                            
                            // TODO: Use the response to activate the link button
                            self.appleMusic.search(name: self.spotify.name! + " " + (self.spotify.artist ?? ""), type: self.spotify.type!)
                                .validate()
                                .responseJSON { response in
                                    self.changeButtonAppearance()
                            }
                        }
                }
            } else {
                setupSpotifyCredentials()
            }
        } else if link?.contains("https://itunes.apple.com/") ?? false {
            // Gets the Spotify version of something if the link is Apple Music
            appleMusic.search(link: link!)?
                .validate()
                .responseJSON { response in
                    // Sets the text of the label to the content that was found
                    if (response.error != nil) {
                        self.titleLabel.text = "Error getting Apple Music data"
                        self.setConvertButton(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                    } else if response.result.value != nil {
                        if self.appleMusic.artist != nil {
                            self.titleLabel.text = self.appleMusic.name! + " by " + self.appleMusic.artist!
                        } else {
                            self.titleLabel.text = self.appleMusic.name!
                        }
                        
                        // TODO: Use the response to activate the link button
                        self.spotify.search(name: self.appleMusic.name! + " " + (self.appleMusic.artist ?? ""), type: self.appleMusic.type!)
                            .validate()
                            .responseJSON { response in
                                self.changeButtonAppearance()
                        }
                    }
            }
        } else {
            changeButtonAppearance()
        }
    }
    
    // Mark: Actions
    
    /// Opens the link in the opposite app
    @IBAction func openSong(_: Any) {
        if link?.contains("https://open.spotify.com/") ?? false {
            appleMusic.open()
        } else if link?.contains("https://itunes.apple.com/") ?? false {
            spotify.open()
        }
    }
}

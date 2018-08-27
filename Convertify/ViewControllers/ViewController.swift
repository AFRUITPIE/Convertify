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
    private var link: String?
    
    // Mark: Properties
    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensures Spotify is logged in
        getSpotifyToken()
    }
    
    // Mark: Functions
    
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
    private func getSpotifyToken() {
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
                // self.getSpotifyToken()
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
        self.link = link
        
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
            if spotify.token != nil {
                handleSpotifySearching(link: link)
            } else {
                getSpotifyToken()
            }
            break
            
        // Extracts Apple Music data and searches for Spotify links when it includes an Apple Music link
        case link.contains(SearcherURL.appleMusic):
            handleAppleMusicSearching(link: link)
            break
            
        // Lets the user know I don't know how to handle whatever is in their clipboard
        default:
            updateAppearance(title: "No Spotify or Apple Music link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }
    
    
    /// Handles searching Apple Music
    ///
    /// - Parameter link: Apple Music compatible link to extract data from
    private func handleAppleMusicSearching(link: String) {
        // Gets the Spotify version of something if the link is Apple Music
        appleMusic.search(link: link)?
            .validate()
            .responseJSON { response in
                // Sets the text of the label to the content that was found
                if response.error != nil {
                    self.titleLabel.text = "Error getting Apple Music data"
                    self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                } else if response.result.value != nil {
                    if self.appleMusic.artist != nil {
                        self.titleLabel.text = self.appleMusic.name! + " by " + self.appleMusic.artist!
                    } else {
                        self.titleLabel.text = self.appleMusic.name!
                    }
                    
                    self.spotify.search(name: self.appleMusic.name! + " " + (self.appleMusic.artist ?? ""), type: self.appleMusic.type!)
                        .validate()
                        .responseJSON { _ in
                            self.updateAppearance(title: "Open in Spotify", color: UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0), enabled: true)
                    }
                }
        }
    }
    
    
    /// Handles searching Spotify
    ///
    /// - Parameter link: Spotify link to extract data from
    private func handleSpotifySearching(link: String) {
        spotify.search(link: link)?
            .validate()
            .responseJSON { response in
                // Sets the text of the label to the content that was found
                if response.error != nil {
                    self.titleLabel.text = "Error getting Spotify data"
                    self.updateAppearance(title: "Link might be formatted incorrectly", color: UIColor.red, enabled: false)
                } else if response.result.value != nil {
                    if self.spotify.artist != nil {
                        self.titleLabel.text = self.spotify.name! + " by " + self.spotify.artist!
                    } else {
                        self.titleLabel.text = self.spotify.name!
                    }
                    
                    // TODO: Use the response to activate the link button
                    self.appleMusic.search(name: self.spotify.name! + " " + (self.spotify.artist ?? ""), type: self.spotify.type!)
                        .validate()
                        .responseJSON { _ in
                            self.updateAppearance(title: "Open in Apple Music", color: UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0), enabled: true)
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
}
